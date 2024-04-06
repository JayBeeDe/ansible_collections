id: telegram
as_token: "{{ matrixtelegrambridge_astoken }}"
hs_token: "{{ matrixtelegrambridge_hstoken }}"
namespaces:
    users:
    - exclusive: true
      regex: '@telegram_.*:{{ server_domain | regex_replace("\.", "\\.") }}'
    - exclusive: true
      regex: '@telegrambot:{{ server_domain | regex_replace("\.", "\\.") }}'
    aliases:
    - exclusive: true
      regex: \#telegram_.*:{{ server_domain | regex_replace("\.", "\\.") }}
url: http://matrix-telegram-bridge:29317
sender_localpart: "{{ matrixtelegrambridge_senderlocalpart }}"
rate_limited: false
de.sorunome.msc2409.push_ephemeral: true
push_ephemeral: true