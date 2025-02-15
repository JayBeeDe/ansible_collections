# Network-specific config options
network:
    # Device name that's shown in the "WhatsApp Web" section in the mobile app.
    os_name: Mautrix-WhatsApp bridge
    # Browser name that determines the logo shown in the mobile app.
    # Must be "unknown" for a generic icon or a valid browser name if you want a specific icon.
    # List of valid browser names: https://github.com/tulir/whatsmeow/blob/efc632c008604016ddde63bfcfca8de4e5304da9/binary/proto/def.proto#L43-L64
    browser_name: unknown

    # Proxy to use for all WhatsApp connections.
    proxy: null
    # Alternative to proxy: an HTTP endpoint that returns the proxy URL to use for WhatsApp connections.
    get_proxy_url: null
    # Whether the proxy options should only apply to the login websocket and not to authenticated connections.
    proxy_only_login: false

    # Should incoming calls send a message to the Matrix room?
    call_start_notices: true
    # Should another user's cryptographic identity changing send a message to Matrix?
    identity_change_notices: false
    # Send the presence as "available" to whatsapp when users start typing on a portal.
    # This works as a workaround for homeservers that do not support presence, and allows
    # users to see when the whatsapp user on the other side is typing during a conversation.
    send_presence_on_typing: false
    # Should WhatsApp status messages be bridged into a Matrix room?
    enable_status_broadcast: true
    # Should sending WhatsApp status messages be allowed?
    # This can cause issues if the user has lots of contacts, so it's disabled by default.
    disable_status_broadcast_send: true
    # Should the status broadcast room be muted and moved into low priority by default?
    # This is only applied when creating the room, the user can unmute it later.
    mute_status_broadcast: true
    # Tag to apply to pinned chats on WhatsApp.
    pinned_tag: m.favourite
    # Tag to apply to archived chats on WhatsApp.
    # Set to m.lowpriority to move them to low priority.
    archive_tag:
    # Tag to apply to the status broadcast room.
    status_broadcast_tag: m.lowpriority
    # Should the bridge use thumbnails from WhatsApp?
    # They're disabled by default due to very low resolution.
    whatsapp_thumbnail: false
    # Should the bridge detect URLs in outgoing messages, ask the homeserver to generate a preview,
    # and send it to WhatsApp? URL previews can always be sent using the `com.beeper.linkpreviews`
    # key in the event content even if this is disabled.
    url_previews: false
    # Should polls be sent using unstable MSC3381 event types?
    extev_polls: false
    # Should view-once messages be disabled entirely?
    disable_view_once: false
    # Should the bridge always send "active" delivery receipts (two gray ticks on WhatsApp)
    # even if the user isn't marked as online (e.g. when presence bridging isn't enabled)?
    #
    # By default, the bridge acts like WhatsApp web, which only sends active delivery
    # receipts when it's in the foreground.
    force_active_delivery_receipts: false
    # When direct media is enabled and a piece of media isn't available on the WhatsApp servers,
    # should it be automatically requested from the phone?
    direct_media_auto_request: true
    # Settings for converting animated stickers.
    animated_sticker:
        # Format to which animated stickers should be converted.
        # disable - No conversion, just unzip and send raw lottie JSON
        # png - converts to non-animated png (fastest)
        # gif - converts to animated gif
        # webm - converts to webm video, requires ffmpeg executable with vp9 codec and webm container support
        # webp - converts to animated webp, requires ffmpeg executable with webp codec/container support
        target: webp
        # Arguments for converter. All converters take width and height.
        args:
            width: 320
            height: 320
            fps: 25 # only for webm, webp and gif (2, 5, 10, 20 or 25 recommended)

    # Settings for handling history sync payloads.
    history_sync:
        # How many conversations should the bridge create after login?
        # If -1, all conversations received from history sync will be bridged.
        # Other conversations will be backfilled on demand when receiving a message.
        max_initial_conversations: -1
        # Should the bridge request a full sync from the phone when logging in?
        # This bumps the size of history syncs from 3 months to 1 year.
        request_full_sync: true
        # Configuration parameters that are sent to the phone along with the request full sync flag.
        # By default, (when the values are null or 0), the config isn't sent at all.
        full_sync_config:
            # Number of days of history to request.
            # The limit seems to be around 3 years, but using higher values doesn't break.
            days_limit: null
            # This is presumably the maximum size of the transferred history sync blob, which may affect what the phone includes in the blob.
            size_mb_limit: null
            # This is presumably the local storage quota, which may affect what the phone includes in the history sync blob.
            storage_quota_mb: null
        # Settings for media requests. If the media expired, then it will not be on the WA servers.
        # Media can always be requested by reacting with the ♻️ (recycle) emoji.
        # These settings determine if the media requests should be done automatically during or after backfill.
        media_requests:
            # Should the expired media be automatically requested from the server as part of the backfill process?
            auto_request_media: true
            # Whether to request the media immediately after the media message is backfilled ("immediate")
            # or at a specific time of the day ("local_time").
            request_method: immediate
            # If request_method is "local_time", what time should the requests be sent (in minutes after midnight)?
            request_local_time: 120
            # Maximum number of media request responses to handle in parallel per user.
            max_async_handle: 2

# Config options that affect the central bridge module.
bridge:
    # The prefix for commands. Only required in non-management rooms.
    command_prefix: "!wa"
    # Should the bridge create a space for each login containing the rooms that account is in?
    personal_filtering_spaces: false
    # Whether the bridge should set names and avatars explicitly for DM portals.
    # This is only necessary when using clients that don't support MSC4171.
    private_chat_portal_meta: true
    # Should events be handled asynchronously within portal rooms?
    # If true, events may end up being out of order, but slow events won't block other ones.
    # This is not yet safe to use.
    async_events: false
    # Should every user have their own portals rather than sharing them?
    # By default, users who are in the same group on the remote network will be
    # in the same Matrix room bridged to that group. If this is set to true,
    # every user will get their own Matrix room instead.
    split_portals: false
    # Should the bridge resend `m.bridge` events to all portals on startup?
    resend_bridge_info: false

    # Should leaving Matrix rooms be bridged as leaving groups on the remote network?
    bridge_matrix_leave: false
    # Should room tags only be synced when creating the portal? Tags mean things like favorite/pin and archive/low priority.
    # Tags currently can't be synced back to the remote network, so a continuous sync means tagging from Matrix will be undone.
    tag_only_on_create: true
    # List of tags to allow bridging. If empty, no tags will be bridged.
    only_bridge_tags: [m.favourite, m.lowpriority]
    # Should room mute status only be synced when creating the portal?
    # Like tags, mutes can't currently be synced back to the remote network.
    mute_only_on_create: true

    # What should be done to portal rooms when a user logs out or is logged out?
    # Permitted values:
    #   nothing - Do nothing, let the user stay in the portals
    #   kick - Remove the user from the portal rooms, but don't delete them
    #   unbridge - Remove all ghosts in the room and disassociate it from the remote chat
    #   delete - Remove all ghosts and users from the room (i.e. delete it)
    cleanup_on_logout:
        # Should cleanup on logout be enabled at all?
        enabled: false
        # Settings for manual logouts (explicitly initiated by the Matrix user)
        manual:
            # Action for private portals which will never be shared with other Matrix users.
            private: nothing
            # Action for portals with a relay user configured.
            relayed: nothing
            # Action for portals which may be shared, but don't currently have any other Matrix users.
            shared_no_users: nothing
            # Action for portals which have other logged-in Matrix users.
            shared_has_users: nothing
        # Settings for credentials being invalidated (initiated by the remote network, possibly through user action).
        # Keys have the same meanings as in the manual section.
        bad_credentials:
            private: nothing
            relayed: nothing
            shared_no_users: nothing
            shared_has_users: nothing

    # Permissions for using the bridge.
    # Permitted values:
    #    relay - Talk through the relaybot (if enabled), no access otherwise
    # commands - Access to use commands in the bridge, but not login.
    #     user - Access to use the bridge with puppeting.
    #    admin - Full access, user level with some additional administration tools.
    # Permitted keys:
    #        * - All Matrix users
    #   domain - All users on that homeserver
    #     mxid - Specific user
    permissions:
        "domain": relay
        "{{ matrix_domain }}": admin
        "@admin:{{ matrix_domain }}": admin

# Config for the bridge's database.
database:
    # The database type. "sqlite3-fk-wal" and "postgres" are supported.
    type: postgres
    # The database URI.
    #   SQLite: A raw file path is supported, but `file:<path>?_txlock=immediate` is recommended.
    #           https://github.com/mattn/go-sqlite3#connection-string
    #   Postgres: Connection string. For example, postgres://user:password@host/database?sslmode=disable
    #             To connect via Unix socket, use something like postgres:///dbname?host=/var/run/postgresql
    uri: "postgres://matrixdb:{{ matrixdb_password }}@matrix-db/whatsapp?sslmode=disable"
    # Maximum number of connections.
    max_open_conns: 20
    max_idle_conns: 2
    # Maximum connection idle time and lifetime before they're closed. Disabled if null.
    # Parsed with https://pkg.go.dev/time#ParseDuration
    max_conn_idle_time: null
    max_conn_lifetime: null

# Homeserver details.
homeserver:
    # The address that this appservice can use to connect to the homeserver.
    # Local addresses without HTTPS are generally recommended when the bridge is running on the same machine,
    # but https also works if they run on different machines.
    address: "http://matrix-gtw:8008"
    # The domain of the homeserver (also known as server_name, used for MXIDs, etc).
    domain: "{{ matrix_domain }}"

    # What software is the homeserver running?
    # Standard Matrix homeservers like Synapse, Dendrite and Conduit should just use "standard" here.
    software: standard
    # The URL to push real-time bridge status to.
    # If set, the bridge will make POST requests to this URL whenever a user's remote network connection state changes.
    # The bridge will use the appservice as_token to authorize requests.
    status_endpoint: null
    # Endpoint for reporting per-message status.
    # If set, the bridge will make POST requests to this URL when processing a message from Matrix.
    # It will make one request when receiving the message (step BRIDGE), one after decrypting if applicable
    # (step DECRYPTED) and one after sending to the remote network (step REMOTE). Errors will also be reported.
    # The bridge will use the appservice as_token to authorize requests.
    message_send_checkpoint_endpoint: null
    # Does the homeserver support https://github.com/matrix-org/matrix-spec-proposals/pull/2246?
    async_media: false
    # Should the bridge use a websocket for connecting to the homeserver?
    # The server side is currently not documented anywhere and is only implemented by mautrix-wsproxy,
    # mautrix-asmux (deprecated), and hungryserv (proprietary).
    websocket: false
    # How often should the websocket be pinged? Pinging will be disabled if this is zero.
    ping_interval_seconds: 0

# Application service host/registration related details.
# Changing these values requires regeneration of the registration (except when noted otherwise)
appservice:
    # The address that the homeserver can use to connect to this appservice.
    # Like the homeserver address, a local non-https address is recommended when the bridge is on the same machine.
    # If the bridge is elsewhere, you must secure the connection yourself (e.g. with https or wireguard)
    # If you want to use https, you need to use a reverse proxy. The bridge does not have TLS support built in.
    address: http://matrix-whatsapp-bridge:29318
    # A public address that external services can use to reach this appservice.
    # This is only needed for things like public media. A reverse proxy is generally necessary when using this field.
    # This value doesn't affect the registration file.
    public_address: https://bridge.example.com

    # The hostname and port where this appservice should listen.
    # For Docker, you generally have to change the hostname to 0.0.0.0.
    hostname: 0.0.0.0
    port: 29318

    # The unique ID of this appservice.
    id: whatsapp
    # Appservice bot details.
    bot:
        # Username of the appservice bot.
        username: whatsapp_JayBeeDeBot
        # Display name and avatar for bot. Set to "remove" to remove display name/avatar, leave empty
        # to leave display name/avatar as-is.
        displayname: WhatsApp bridge bot
        avatar: mxc://maunium.net/NeXNQarUbrlYBiPCpprYsRqr

    # Whether to receive ephemeral events via appservice transactions.
    ephemeral_events: true
    # Should incoming events be handled asynchronously?
    # This may be necessary for large public instances with lots of messages going through.
    # However, messages will not be guaranteed to be bridged in the same order they were sent in.
    # This value doesn't affect the registration file.
    async_transactions: false

    # Authentication tokens for AS <-> HS communication. Autogenerated; do not modify.
    as_token: "{{ matrixwhatsappbridge_astoken }}"
    hs_token: "{{ matrixwhatsappbridge_hstoken }}"

# Config options that affect the Matrix connector of the bridge.
matrix:
    # Whether the bridge should send the message status as a custom com.beeper.message_send_status event.
    message_status_events: false
    # Whether the bridge should send a read receipt after successfully bridging a message.
    delivery_receipts: false
    # Whether the bridge should send error notices via m.notice events when a message fails to bridge.
    message_error_notices: true
    # Whether the bridge should update the m.direct account data event when double puppeting is enabled.
    sync_direct_chat_list: false
    # Whether created rooms should have federation enabled. If false, created portal rooms
    # will never be federated. Changing this option requires recreating rooms.
    federate_rooms: true
    # The threshold as bytes after which the bridge should roundtrip uploads via the disk
    # rather than keeping the whole file in memory.
    upload_file_threshold: 5242880

# Settings for provisioning API
provisioning:
    # Prefix for the provisioning API paths.
    prefix: /_matrix/provision
    # Shared secret for authentication. If set to "generate" or null, a random secret will be generated,
    # or if set to "disable", the provisioning API will be disabled.
    # shared_secret: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    # Whether to allow provisioning API requests to be authed using Matrix access tokens.
    # This follows the same rules as double puppeting to determine which server to contact to check the token,
    # which means that by default, it only works for users on the same server as the bridge.
    allow_matrix_auth: true
    # Enable debug API at /debug with provisioning authentication.
    debug_endpoints: false

# Settings for backfilling messages.
# Note that the exact way settings are applied depends on the network connector.
# See https://docs.mau.fi/bridges/general/backfill.html for more details.
backfill:
    # Whether to do backfilling at all.
    enabled: true
    # Maximum number of messages to backfill in empty rooms.
    max_initial_messages: 50
    # Maximum number of missed messages to backfill after bridge restarts.
    max_catchup_messages: 500
    # If a backfilled chat is older than this number of hours,
    # mark it as read even if it's unread on the remote network.
    unread_hours_threshold: 720
    # Settings for backfilling threads within other backfills.
    threads:
        # Maximum number of messages to backfill in a new thread.
        max_initial_messages: 50
    # Settings for the backwards backfill queue. This only applies when connecting to
    # Beeper as standard Matrix servers don't support inserting messages into history.
    queue:
        # Should the backfill queue be enabled?
        enabled: false
        # Number of messages to backfill in one batch.
        batch_size: 100
        # Delay between batches in seconds.
        batch_delay: 20
        # Maximum number of batches to backfill per portal.
        # If set to -1, all available messages will be backfilled.
        max_batches: -1
        # Optional network-specific overrides for max batches.
        # Interpretation of this field depends on the network connector.
        max_batches_override: {}

# # Settings for enabling double puppeting
# double_puppet:
#     # Servers to always allow double puppeting from.
#     # This is only for other servers and should NOT contain the server the bridge is on.
#     servers:
#         example.com: https://example.com
#     # Whether to allow client API URL discovery for other servers. When using this option,
#     # users on other servers can use double puppeting even if their server URLs aren't
#     # explicitly added to the servers map above.
#     allow_discovery: false
#     # Shared secrets for automatic double puppeting.
#     # See https://docs.mau.fi/bridges/general/double-puppeting.html for instructions.
#     secrets:
#         example.com: foobar

# End-to-bridge encryption support options.
#
# See https://docs.mau.fi/bridges/general/end-to-bridge-encryption.html for more info.
encryption:
    # Whether to enable encryption at all. If false, the bridge will not function in encrypted rooms.
    allow: false
    # Whether to force-enable encryption in all bridged rooms.
    default: false
    # Whether to require all messages to be encrypted and drop any unencrypted messages.
    require: false
    # Whether to use MSC2409/MSC3202 instead of /sync long polling for receiving encryption-related data.
    # This option is not yet compatible with standard Matrix servers like Synapse and should not be used.
    appservice: false
    # Enable key sharing? If enabled, key requests for rooms where users are in will be fulfilled.
    # You must use a client that supports requesting keys from other users to use this feature.
    allow_key_sharing: false
    # Pickle key for encrypting encryption keys in the bridge database.
    # If set to generate, a random key will be generated.
    pickle_key: maunium.net/go/mautrix-whatsapp
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
        # Minimum level for which the bridge should send keys to when bridging messages from the remote network to Matrix.
        receive: unverified
        # Minimum level that the bridge should accept for incoming Matrix messages.
        send: unverified
        # Minimum level that the bridge should require for accepting key requests.
        share: cross-signed-tofu
    # Options for Megolm room key rotation. These options allow you to configure the m.room.encryption event content.
    # See https://spec.matrix.org/v1.10/client-server-api/#mroomencryption for more information about that event.
    rotation:
        # Enable custom Megolm room key rotation settings. Note that these
        # settings will only apply to rooms created after this option is set.
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
