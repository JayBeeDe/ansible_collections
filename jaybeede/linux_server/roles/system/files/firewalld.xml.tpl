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
{% if https_flag is defined and https_flag == 1 and server_domain is defined %}
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
{% if virtualdesktopdb_password is defined %}
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