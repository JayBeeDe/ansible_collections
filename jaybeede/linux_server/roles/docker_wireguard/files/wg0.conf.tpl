[Interface]
Address = 10.13.13.1{% if ipv6_flag == 1 %}, {{ wireguard_proxy_ipv6 }}{% endif %}

ListenPort = 51820
PrivateKey = {{ wireguard_proxy_private_key }}
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth+ -j MASQUERADE; ip6tables -A FORWARD -i %i -j ACCEPT; ip6tables -A FORWARD -o %i -j ACCEPT
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth+ -j MASQUERADE; ip6tables -D FORWARD -i %i -j ACCEPT; ip6tables -D FORWARD -o %i -j ACCEPT

{% for peer_name, peer in wireguard_proxy_peers_list.items() -%}
[Peer]
# {{ peer_name }}
PublicKey = {{ peer.public_key }}
PresharedKey = {{ peer.preshared_key }}
AllowedIPs = 10.13.13.{{ loop.index + 1 }}/32{% if ipv6_flag == 1 %}, {{ peer.ipv6_address }}/128{% if peer.extra_allowed_ip_address_cidrv6 is defined %}, {{ peer.extra_allowed_ip_address_cidrv6 }}{% endif %}{% endif %}

PersistentKeepalive = 25

{% endfor %}
