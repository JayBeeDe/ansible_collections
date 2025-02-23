127.0.0.1   localhost
127.0.1.1   {{ ansible_host }}

::1	localhost   ip6-localhost   ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

{% for host in ansible_play_hosts_all -%}
{{ hostvars[host]['ansible_default_ipv4']['address'] }} {{ hostvars[host]['ansible_host'] }}
{% endfor %}
