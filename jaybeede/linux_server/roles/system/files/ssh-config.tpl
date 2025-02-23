{% for host in ansible_play_hosts_all -%}
Host {{ hostvars[host]['ansible_host'] }}
  HostName {{ hostvars[host]['ansible_host'] }}
  User {{ user }}
  Port {{ ssh_port | string }}
{% endfor %}
