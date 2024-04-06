{
    "default_server_config": {
        "m.homeserver": {
            "base_url": "https://{{ server_domain }}/matrix",
            "server_name": "{{ server_domain }}"
        },
        "m.identity_server": {
            "base_url": "https://vector.im"
        }
    },
    "brand": "Messages",
    "integrations_ui_url": "https://scalar.vector.im/",
    "integrations_rest_url": "https://scalar.vector.im/api",
    "integrations_widgets_urls": [
        "https://scalar.vector.im/_matrix/integrations/v1",
        "https://scalar.vector.im/api",
        "https://scalar-staging.vector.im/_matrix/integrations/v1",
        "https://scalar-staging.vector.im/api",
        "https://scalar-staging.riot.im/scalar/api"
    ],
    "bug_report_endpoint_url": "https://element.io/bugreports/submit",
    "uisi_autorageshake_app": "element-auto-uisi",
    "show_labs_settings": true,
    "room_directory": {
        "servers": [
            "matrix.org",
            "gitter.im",
            "libera.chat"
        ]
    },
    "enable_presence_by_hs_url": {
        "https://matrix.org": false,
        "https://matrix-client.matrix.org": false
    },
    "terms_and_conditions_links": [
        {
            "url": "https://element.io/privacy",
            "text": "Privacy Policy"
        },
        {
            "url": "https://element.io/cookie-policy",
            "text": "Cookie Policy"
        }
    ],
    "privacy_policy_url": "https://element.io/cookie-policy",
    "features": {
        "feature_video_rooms": false,
        "feature_new_room_decoration_ui": false,
        "feature_element_call_video_rooms": false
    },
    "setting_defaults": {
        "RustCrypto.staged_rollout_percent": 100
    },
    "map_style_url": "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx"
}