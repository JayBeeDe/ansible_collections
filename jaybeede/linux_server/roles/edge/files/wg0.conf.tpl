[Interface]
{% set ipv4_suffix_address = wireguard_peers_list[ansible_host]["ipv6_address"].split(':')[-1] %}
Address = 10.13.13.{{ ipv4_suffix_address }}, {{ wireguard_peers_list[ansible_host]["ipv6_address"] }}
PrivateKey = {{ wireguard_peers_list[ansible_host]["private_key"] }}
ListenPort = 51820
DNS = {{ network_dns }},{{ network_dns2 }},{{ network_dnsv6 }},{{ network_dnsv62 }}
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = {{ wireguard_public_key }}
PresharedKey = {{ wireguard_peers_list[ansible_host]["preshared_key"] }}
Endpoint = {{ wireguard_endpoint }}
AllowedIPs = 0.0.0.0/0, ::/0
