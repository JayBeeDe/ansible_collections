# Homeserver details
homeserver:
    # The address that this appservice can use to connect to the homeserver.
    address: "http://matrix-gtw:8008"
    # The domain of the homeserver (also known as server_name, used for MXIDs, etc).
    domain: "{{ matrix_domain }}"
    # What software is the homeserver running?
    # Standard Matrix homeservers like Synapse, Dendrite and Conduit should just use "standard" here.
    software: standard
    # The URL to push real-time bridge status to.
    # If set, the bridge will make POST requests to this URL whenever a user's whatsapp connection state changes.
    # The bridge will use the appservice as_token to authorize requests.
    status_endpoint: null
    # Endpoint for reporting per-message status.
    message_send_checkpoint_endpoint: null
    # Does the homeserver support https://github.com/matrix-org/matrix-spec-proposals/pull/2246?
    async_media: false
    # Should the bridge use a websocket for connecting to the homeserver?
    # The server side is currently not documented anywhere and is only implemented by mautrix-wsproxy,
    # mautrix-asmux (deprecated), and hungryserv (proprietary).
    websocket: false
    # How often should the websocket be pinged? Pinging will be disabled if this is zero.
    ping_interval_seconds: 0

# Application service host/registration related details
# Changing these values requires regeneration of the registration.
appservice:
    # The address that the homeserver can use to connect to this appservice.
    address: http://matrix-whatsapp-bridge:29318
    # The hostname and port where this appservice should listen.
    hostname: 0.0.0.0
    port: 29318
    # Database config.
    database:
        # The database type. "sqlite3-fk-wal" and "postgres" are supported.
        type: postgres
        # The database URI.
        #   SQLite: A raw file path is supported, but `file:<path>?_txlock=immediate` is recommended.
        #           https://github.com/mattn/go-sqlite3#connection-string
        #   Postgres: Connection string. For example, postgres://user:password@host/database?sslmode=disable
        #             To connect via Unix socket, use something like postgres:///dbname?host=/var/run/postgresql
        uri: "postgres://matrixdb:{{ matrixdb_password }}@matrix-db/whatsapp?sslmode=disable"
        # Maximum number of connections. Mostly relevant for Postgres.
        max_open_conns: 20
        max_idle_conns: 2
        # Maximum connection idle time and lifetime before they're closed. Disabled if null.
        # Parsed with https://pkg.go.dev/time#ParseDuration
        max_conn_idle_time: null
        max_conn_lifetime: null

    # The unique ID of this appservice.
    id: whatsapp
    bot:
        # Username of the appservice bot.
        username: whatsapp_JayBeeDeBot
        # Display name and avatar for bot. Set to "remove" to remove display name/avatar, leave empty
        # to leave display name/avatar as-is.
        displayname: WhatsApp bridge bot
        avatar: mxc://maunium.net/NeXNQarUbrlYBiPCpprYsRqr
    # Whether or not to receive ephemeral events via appservice transactions.
    # Requires MSC2409 support (i.e. Synapse 1.22+).
    # You should disable bridge -> sync_with_custom_puppets when this is enabled.
    ephemeral_events: true
    # Should incoming events be handled asynchronously?
    # This may be necessary for large public instances with lots of messages going through.
    # However, messages will not be guaranteed to be bridged in the same order they were sent in.
    async_transactions: false

    # Authentication tokens for AS <-> HS communication. Autogenerated; do not modify.
    as_token: "{{ matrixwhatsappbridge_astoken }}"
    hs_token: "{{ matrixwhatsappbridge_hstoken }}"

metrics:
    enabled: false
    listen: 127.0.0.1:8001
bridge:
    # Should the bridge create a space for each logged-in user and add bridged rooms to it?
    # Users who logged in before turning this on should run `!wa sync space` to create and fill the space for the first time.
    personal_filtering_spaces: false
    # Should the bridge send a read receipt from the bridge bot when a message has been sent to WhatsApp?
    delivery_receipts: false
    # Whether the bridge should send the message status as a custom com.beeper.message_send_status event.
    message_status_events: false
    # Whether the bridge should send error notices via m.notice events when a message fails to bridge.
    message_error_notices: true
    # Should incoming calls send a message to the Matrix room?
    call_start_notices: true
    # Should another user's cryptographic identity changing send a message to Matrix?
    identity_change_notices: false
    portal_message_buffer: 128
    # Settings for handling history sync payloads.
    history_sync:
        # Enable backfilling history sync payloads from WhatsApp?
        backfill: true
        # The maximum number of initial conversations that should be synced.
        # Other conversations will be backfilled on demand when receiving a message or when initiating a direct chat.
        max_initial_conversations: -1
        # Maximum number of messages to backfill in each conversation.
        # Set to -1 to disable limit.
        message_count: 50
        # Should the bridge request a full sync from the phone when logging in?
        # This bumps the size of history syncs from 3 months to 1 year.
        request_full_sync: false
        # Configuration parameters that are sent to the phone along with the request full sync flag.
        # By default (when the values are null or 0), the config isn't sent at all.
        full_sync_config:
            # Number of days of history to request.
            # The limit seems to be around 3 years, but using higher values doesn't break.
            days_limit: null
            # This is presumably the maximum size of the transferred history sync blob, which may affect what the phone includes in the blob.
            size_mb_limit: null
            # This is presumably the local storage quota, which may affect what the phone includes in the history sync blob.
            storage_quota_mb: null
        # If this value is greater than 0, then if the conversation's last message was more than
        # this number of hours ago, then the conversation will automatically be marked it as read.
        # Conversations that have a last message that is less than this number of hours ago will
        # have their unread status synced from WhatsApp.
        unread_hours_threshold: 0
        ###############################################################################
        # The settings below are only applicable for backfilling using batch sending, #
        # which is no longer supported in Synapse.                                    #
        ###############################################################################

        # Settings for media requests. If the media expired, then it will not be on the WA servers.
        # Media can always be requested by reacting with the ♻️ (recycle) emoji.
        # These settings determine if the media requests should be done automatically during or after backfill.
        media_requests:
            # Should expired media be automatically requested from the server as part of the backfill process?
            auto_request_media: true
            # Whether to request the media immediately after the media message is backfilled ("immediate")
            # or at a specific time of the day ("local_time").
            request_method: immediate
            # If request_method is "local_time", what time should the requests be sent (in minutes after midnight)?
            request_local_time: 120
        # Settings for immediate backfills. These backfills should generally be small and their main purpose is
        # to populate each of the initial chats (as configured by max_initial_conversations) with a few messages
        # so that you can continue conversations without losing context.
        immediate:
            # The number of concurrent backfill workers to create for immediate backfills.
            # Note that using more than one worker could cause the room list to jump around
            # since there are no guarantees about the order in which the backfills will complete.
            worker_count: 1
            # The maximum number of events to backfill initially.
            max_events: 10
        # Settings for deferred backfills. The purpose of these backfills are to fill in the rest of
        # the chat history that was not covered by the immediate backfills.
        # These backfills generally should happen at a slower pace so as not to overload the homeserver.
        # Each deferred backfill config should define a "stage" of backfill (i.e. the last week of messages).
        # The fields are as follows:
        # - start_days_ago: the number of days ago to start backfilling from.
        #     To indicate the start of time, use -1. For example, for a week ago, use 7.
        # - max_batch_events: the number of events to send per batch.
        # - batch_delay: the number of seconds to wait before backfilling each batch.
        deferred:
            # Last Week
            - start_days_ago: 7
              max_batch_events: 20
              batch_delay: 5
            # Last Month
            - start_days_ago: 30
              max_batch_events: 50
              batch_delay: 10
            # Last 3 months
            - start_days_ago: 90
              max_batch_events: 100
              batch_delay: 10
            # The start of time
            - start_days_ago: -1
              max_batch_events: 500
              batch_delay: 10
    # Should puppet avatars be fetched from the server even if an avatar is already set?
    user_avatar_sync: true
    # Should Matrix users leaving groups be bridged to WhatsApp?
    bridge_matrix_leave: true
    # Should the bridge update the m.direct account data event when double puppeting is enabled.
    # Note that updating the m.direct event is not atomic (except with mautrix-asmux)
    # and is therefore prone to race conditions.
    sync_direct_chat_list: false
    # Should the bridge use MSC2867 to bridge manual "mark as unread"s from
    # WhatsApp and set the unread status on initial backfill?
    # This will only work on clients that support the m.marked_unread or
    # com.famedly.marked_unread room account data.
    sync_manual_marked_unread: true
    # When double puppeting is enabled, users can use `!wa toggle` to change whether
    # presence is bridged. This setting sets the default value.
    # Existing users won't be affected when these are changed.
    default_bridge_presence: true
    # Send the presence as "available" to whatsapp when users start typing on a portal.
    # This works as a workaround for homeservers that do not support presence, and allows
    # users to see when the whatsapp user on the other side is typing during a conversation.
    send_presence_on_typing: false
    # Should the bridge always send "active" delivery receipts (two gray ticks on WhatsApp)
    # even if the user isn't marked as online (e.g. when presence bridging isn't enabled)?
    #
    # By default, the bridge acts like WhatsApp web, which only sends active delivery
    # receipts when it's in the foreground.
    force_active_delivery_receipts: false
    # Servers to always allow double puppeting from
    double_puppet_server_map:
        example.com: https://example.com
    # Allow using double puppeting from any server with a valid client .well-known file.
    double_puppet_allow_discovery: false
    # Shared secrets for https://github.com/devture/matrix-synapse-shared-secret-auth
    #
    # If set, double puppeting will be enabled automatically for local users
    # instead of users having to find an access token and run `login-matrix`
    # manually.
    login_shared_secret_map:
        example.com: foobar
    # Whether to explicitly set the avatar and room name for private chat portal rooms.
    # If set to `default`, this will be enabled in encrypted rooms and disabled in unencrypted rooms.
    # If set to `always`, all DM rooms will have explicit names and avatars set.
    # If set to `never`, DM rooms will never have names and avatars set.
    private_chat_portal_meta: always
    # Should group members be synced in parallel? This makes member sync faster
    parallel_member_sync: false
    # Should Matrix m.notice-type messages be bridged?
    bridge_notices: true
    # Set this to true to tell the bridge to re-send m.bridge events to all rooms on the next run.
    # This field will automatically be changed back to false after it, except if the config file is not writable.
    resend_bridge_info: false
    # When using double puppeting, should muted chats be muted in Matrix?
    mute_bridging: false
    # When using double puppeting, should archived chats be moved to a specific tag in Matrix?
    # Note that WhatsApp unarchives chats when a message is received, which will also be mirrored to Matrix.
    # This can be set to a tag (e.g. m.lowpriority), or null to disable.
    archive_tag: null
    # Same as above, but for pinned chats. The favorite tag is called m.favourite
    pinned_tag: null
    # Should mute status and tags only be bridged when the portal room is created?
    tag_only_on_create: true
    # Should WhatsApp status messages be bridged into a Matrix room?
    # Disabling this won't affect already created status broadcast rooms.
    enable_status_broadcast: true
    # Should sending WhatsApp status messages be allowed?
    # This can cause issues if the user has lots of contacts, so it's disabled by default.
    disable_status_broadcast_send: true
    # Should the status broadcast room be muted and moved into low priority by default?
    # This is only applied when creating the room, the user can unmute it later.
    mute_status_broadcast: true
    # Tag to apply to the status broadcast room.
    status_broadcast_tag: m.lowpriority
    # Should the bridge use thumbnails from WhatsApp?
    # They're disabled by default due to very low resolution.
    whatsapp_thumbnail: false
    # Allow invite permission for user. User can invite any bots to room with whatsapp
    # users (private chat and groups)
    allow_user_invite: false
    # Whether or not created rooms should have federation enabled.
    # If false, created portal rooms will never be federated.
    federate_rooms: true
    # Should the bridge never send alerts to the bridge management room?
    # These are mostly things like the user being logged out.
    disable_bridge_alerts: false
    # Should the bridge stop if the WhatsApp server says another user connected with the same session?
    # This is only safe on single-user bridges.
    crash_on_stream_replaced: false
    # Should the bridge detect URLs in outgoing messages, ask the homeserver to generate a preview,
    # and send it to WhatsApp? URL previews can always be sent using the `com.beeper.linkpreviews`
    # key in the event content even if this is disabled.
    url_previews: false
    # Send captions in the same message as images. This will send data compatible with both MSC2530 and MSC3552.
    # This is currently not supported in most clients.
    caption_in_message: false
    # Send galleries as a single event? This is not an MSC (yet).
    beeper_galleries: false
    # Should polls be sent using MSC3381 event types?
    extev_polls: false
    # Should cross-chat replies from WhatsApp be bridged? Most servers and clients don't support this.
    cross_room_replies: false
    # Disable generating reply fallbacks? Some extremely bad clients still rely on them,
    # but they're being phased out and will be completely removed in the future.
    disable_reply_fallbacks: false
    # Maximum time for handling Matrix events. Duration strings formatted for https://pkg.go.dev/time#ParseDuration
    # Null means there's no enforced timeout.
    message_handling_timeout:
        # Send an error message after this timeout, but keep waiting for the response until the deadline.
        # This is counted from the origin_server_ts, so the warning time is consistent regardless of the source of delay.
        # If the message is older than this when it reaches the bridge, the message won't be handled at all.
        error_after: null
        # Drop messages after this timeout. They may still go through if the message got sent to the servers.
        # This is counted from the time the bridge starts handling the message.
        deadline: 120s

    # The prefix for commands. Only required in non-management rooms.
    command_prefix: "!wa"

    # Messages sent upon joining a management room.
    # Markdown is supported. The defaults are listed below.
    management_room_text:
        # Sent when joining a room.
        welcome: "Hello, I'm a WhatsApp bridge bot."
        # Sent when joining a management room and the user is already logged in.
        welcome_connected: "Use `help` for help."
        # Sent when joining a management room and the user is not logged in.
        welcome_unconnected: "Use `help` for help or `login` to log in."
        # Optional extra text sent when joining a management room.
        additional_help: ""

    # End-to-bridge encryption support options.
    #
    # See https://docs.mau.fi/bridges/general/end-to-bridge-encryption.html for more info.
    encryption:
        # Allow encryption, work in group chat rooms with e2ee enabled
        allow: false
        # Default to encryption, force-enable encryption in all portals the bridge creates
        # This will cause the bridge bot to be in private chats for the encryption to work properly.
        default: false
        # Whether to use MSC2409/MSC3202 instead of /sync long polling for receiving encryption-related data.
        appservice: false
        # Require encryption, drop any unencrypted messages.
        require: false
        # Enable key sharing? If enabled, key requests for rooms where users are in will be fulfilled.
        # You must use a client that supports requesting keys from other users to use this feature.
        allow_key_sharing: false
        # Should users mentions be in the event wire content to enable the server to send push notifications?
        plaintext_mentions: false
        # Options for deleting megolm sessions from the bridge.
        delete_keys:
            # Beeper-specific: delete outbound sessions when hungryserv confirms
            # that the user has uploaded the key to key backup.
            delete_outbound_on_ack: false
            # Don't store outbound sessions in the inbound table.
            dont_store_outbound: false
            # Ratchet megolm sessions forward after decrypting messages.
            ratchet_on_decrypt: false
            # Delete fully used keys (index >= max_messages) after decrypting messages.
            delete_fully_used_on_decrypt: false
            # Delete previous megolm sessions from same device when receiving a new one.
            delete_prev_on_new_session: false
            # Delete megolm sessions received from a device when the device is deleted.
            delete_on_device_delete: false
            # Periodically delete megolm sessions when 2x max_age has passed since receiving the session.
            periodically_delete_expired: false
            # Delete inbound megolm sessions that don't have the received_at field used for
            # automatic ratcheting and expired session deletion. This is meant as a migration
            # to delete old keys prior to the bridge update.
            delete_outdated_inbound: false
        # What level of device verification should be required from users?
        #
        # Valid levels:
        #   unverified - Send keys to all device in the room.
        #   cross-signed-untrusted - Require valid cross-signing, but trust all cross-signing keys.
        #   cross-signed-tofu - Require valid cross-signing, trust cross-signing keys on first use (and reject changes).
        #   cross-signed-verified - Require valid cross-signing, plus a valid user signature from the bridge bot.
        #                           Note that creating user signatures from the bridge bot is not currently possible.
        #   verified - Require manual per-device verification
        #              (currently only possible by modifying the `trust` column in the `crypto_device` database table).
        verification_levels:
            # Minimum level for which the bridge should send keys to when bridging messages from WhatsApp to Matrix.
            receive: unverified
            # Minimum level that the bridge should accept for incoming Matrix messages.
            send: unverified
            # Minimum level that the bridge should require for accepting key requests.
            share: cross-signed-tofu
        # Options for Megolm room key rotation. These options allow you to
        # configure the m.room.encryption event content. See:
        # https://spec.matrix.org/v1.3/client-server-api/#mroomencryption for
        # more information about that event.
        rotation:
            # Enable custom Megolm room key rotation settings. Note that these
            # settings will only apply to rooms created after this option is
            # set.
            enable_custom: false
            # The maximum number of milliseconds a session should be used
            # before changing it. The Matrix spec recommends 604800000 (a week)
            # as the default.
            milliseconds: 604800000
            # The maximum number of messages that should be sent with a given a
            # session before changing it. The Matrix spec recommends 100 as the
            # default.
            messages: 100
            # Disable rotating keys when a user's devices change?
            # You should not enable this option unless you understand all the implications.
            disable_device_change_key_rotation: false

    # Settings for provisioning API
    provisioning:
        # Prefix for the provisioning API paths.
        prefix: /_matrix/provision
        # Shared secret for authentication. If set to "generate", a random secret will be generated,
        # or if set to "disable", the provisioning API will be disabled.
        shared_secret:
        # Enable debug API at /debug with provisioning authentication.
        debug_endpoints: false

    # Permissions for using the bridge.
    # Permitted values:
    #   relay    - Talk through the relaybot (if enabled), no access otherwise
    #       user - Access to use the bridge to chat with a WhatsApp account.
    #      admin - User level and some additional administration tools
    # Permitted keys:
    #        * - All Matrix users
    #   domain - All users on that homeserver
    #     mxid - Specific user
    permissions:
        "domain": relay
        "{{ matrix_domain }}": admin
        "@admin:{{ matrix_domain }}": admin

whatsapp:
    # Device name that's shown in the "WhatsApp Web" section in the mobile app.
    os_name: Mautrix-WhatsApp bridge
    # Browser name that determines the logo shown in the mobile app.
    # Must be "unknown" for a generic icon or a valid browser name if you want a specific icon.
    # List of valid browser names: https://github.com/tulir/whatsmeow/blob/efc632c008604016ddde63bfcfca8de4e5304da9/binary/proto/def.proto#L43-L64
    browser_name: unknown
    # Settings for relay mode
    relay:
        # Whether relay mode should be allowed. If allowed, `!wa set-relay` can be used to turn any
        # authenticated user into a relaybot for that chat.
        enabled: false
        # Should only admins be allowed to set themselves as relay users?
        admin_only: true
        # The formats to use when sending messages to WhatsApp via the relaybot.

# Logging config. See https://github.com/tulir/zeroconfig for details.
logging:
    min_level: debug
    writers:
        - type: stdout
          format: pretty-colored
        - type: file
          format: json
          filename: ./logs/mautrix-whatsapp.log
          max_size: 100
          max_backups: 10
          compress: true
