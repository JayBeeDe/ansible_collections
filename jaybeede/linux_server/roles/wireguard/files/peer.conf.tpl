# {{ item.key }}

[Interface]
Address = 10.13.13.{{ count + 2 }}{% if ipv6_flag == 1 %}, {{ item.value.ipv6_address }}{% endif %}

PrivateKey = {{ item.value.private_key }}
ListenPort = 51820
DNS = {{ network_dns }},{{ network_dns2 }},{{ network_dnsv6 }},{{ network_dnsv62 }}

[Peer]
PublicKey = {{ wireguard_proxy_public_key }}
PresharedKey = {{ item.value.preshared_key }}
Endpoint = {{ vpn_domain }}:{{ wireguard_proxy_port | string }}
AllowedIPs = 0.0.0.0/0{% if ipv6_flag == 1 %}, ::/0{% endif %}
