<?xml version="1.0" encoding="utf-8"?>
<zone>
  <short>Public</short>
  <description>For use in public areas. You do not trust the other computers on networks to not harm your computer. Only selected incoming connections are accepted.</description>
  <service name="dhcpv6-client" />
{% if wireguard_proxy_port is defined %}
  <rule family="ipv4">
    <port protocol="udp" port="{{ wireguard_proxy_port | string }}"/>
    <accept/>
  </rule>
  <rule family="ipv6">
    <port protocol="udp" port="{{ wireguard_proxy_port | string }}"/>
    <accept/>
  </rule>
  <masquerade/>
{% endif %}
{% if server_domain is defined %}
  <rule family="ipv4">
    <port protocol="tcp" port="80"/>
    <accept/>
  </rule>
{% endif %}
{% if use_https is defined and use_https and server_domain is defined %}
  <rule family="ipv4">
    <port protocol="tcp" port="443"/>
    <accept/>
  </rule>
{% endif %}
{% if matrix_domain is defined %}
  <rule family="ipv4">
    <port protocol="tcp" port="8448"/>
    <accept/>
  </rule>
{% endif %}
{% if matrixtelegrambridge_appid is defined %}
  <rule family="ipv4">
    <source address="172.17.0.0/24"/>
    <port protocol="tcp" port="8000"/>
    <accept/>
  </rule>
{% endif %}
  <rule family="ipv4">
    <source address="127.0.0.1/32" />
    <port protocol="tcp" port="{{ ssh_port | string }}" />
    <accept />
  </rule>
{% if nfs_subnet is defined %}
  <rule family="ipv4">
    <source address="{{ nfs_subnet }}"/>
    <port protocol="tcp" port="111"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <source address="{{ nfs_subnet }}"/>
    <port protocol="udp" port="111"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <source address="{{ nfs_subnet }}"/>
    <port protocol="tcp" port="2049"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <source address="{{ nfs_subnet }}"/>
    <port protocol="udp" port="2049"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <source address="{{ nfs_subnet }}"/>
    <port protocol="tcp" port="3000"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <source address="{{ nfs_subnet }}"/>
    <port protocol="udp" port="3000"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <source address="{{ nfs_subnet }}"/>
    <port protocol="tcp" port="3001"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <source address="{{ nfs_subnet }}"/>
    <port protocol="udp" port="3002"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <source address="{{ nfs_subnet }}"/>
    <port protocol="tcp" port="3003"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <source address="{{ nfs_subnet }}"/>
    <port protocol="udp" port="3003"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <source address="{{ nfs_subnet }}"/>
    <port protocol="tcp" port="6667"/>
    <accept/>
  </rule>
{% endif %}
{% if transmission_subnet is defined and transmission_rpc_port is defined %}
  <rule family="ipv4">
    <source address="{{ transmission_subnet }}"/>
    <port protocol="tcp" port="{{ transmission_rpc_port }}"/>
    <accept/>
  </rule>
{% endif %}
{% if transmission_peer_port is defined %}
  <rule family="ipv4">
    <source address="10.13.13.0/24"/>
    <port protocol="tcp" port="{{ transmission_peer_port }}"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <source address="10.13.13.0/24"/>
    <port protocol="udp" port="{{ transmission_peer_port }}"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <destination address="10.13.13.0/24"/>
    <port protocol="tcp" port="{{ transmission_peer_port }}"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <destination address="10.13.13.0/24"/>
    <port protocol="udp" port="{{ transmission_peer_port }}"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <port protocol="tcp" port="{{ transmission_peer_port }}"/>
    <drop/>
  </rule>
  <rule family="ipv4">
    <port protocol="udp" port="{{ transmission_peer_port }}"/>
    <drop/>
  </rule>
  <rule family="ipv6">
    <port protocol="tcp" port="{{ transmission_peer_port }}"/>
    <drop/>
  </rule>
  <rule family="ipv6">
    <port protocol="udp" port="{{ transmission_peer_port }}"/>
    <drop/>
  </rule>
{% endif %}
{% if virtualdesktopdb_password is defined or wireguard_proxy_port is defined %}
  <rule family="ipv4">
    <source address="172.17.0.0/24"/>
    <port protocol="tcp" port="{{ ssh_port | string }}"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <source address="172.18.0.0/24"/>
    <port protocol="tcp" port="{{ ssh_port | string }}"/>
    <accept/>
  </rule>
{% endif %}
  <rule family="ipv4">
    <source address="{{ allowed_ip }}/32" />
    <port protocol="tcp" port="{{ ssh_port | string }}" />
    <accept />
  </rule>
{% for host in ansible_play_hosts_all -%}
{{ "  " }}<rule family="ipv4">
    <source address="{{ hostvars[host]['ansible_default_ipv4']['address'] }}/32" />
    <port protocol="tcp" port="{{ ssh_port | string }}" />
    <accept />
  </rule>
{% endfor %}
</zone>