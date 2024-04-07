id: whatsapp
url: http://matrix-whatsapp-bridge:29318
as_token: "{{ matrixwhatsappbridge_astoken }}"
hs_token: "{{ matrixwhatsappbridge_hstoken }}"
sender_localpart: "{{ matrixwhatsappbridge_senderlocalpart }}"
namespaces:
    users:
    - exclusive: true
      regex: ^@whatsappbot:{{ server_domain | regex_replace("\.", "\\.") }}$
    - exclusive: true
      regex: ^@whatsapp_.*:{{ server_domain | regex_replace("\.", "\\.") }}$
rate_limited: false
de.sorunome.msc2409.push_ephemeral: true
push_ephemeral: true