ip -6 route {{ action_route }} {{ wireguard_proxy_route_cidrv6 }} via {{ wireguard_proxy_route_gwv6 }}
{% for peer_name, peer in wireguard_proxy_peers_list.items() -%}{% if peer.extra_allowed_ip_address_cidrv6 is defined %}
ip -6 route {{ action_route }} {{ peer.extra_allowed_ip_address_cidrv6 }} via {{ wireguard_proxy_route_gwv6 }}
{% endif %}{% endfor %}
