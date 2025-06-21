wireguard
=========

Wireguard VPN for linux server.

Role Variables
--------------

Variable Name | Description
------------- | -----------
user | The target machine session username
home | The target machine session username's home directory
network_dns | primary IPv4 resolver
network_dns2 | secondary IPv4 resolver
network_dnsv6 | primary IPv6 resolver
network_dnsv62 | secondary IPv6 resolver
vpn_domain | VPN endpoint domain
wireguard_proxy_cidrv6 | Outer docker network (applicable if ipv6_flag set)
wireguard_proxy_ipv6 | Server IPv6 address (applicable if ipv6_flag set)
wireguard_proxy_peers_list | list of peers to configure (see details below)
vault_wireguard_proxy_port | VPN endpoint network port
vault_wireguard_proxy_private_key | Server private key
vault_wireguard_proxy_public_key | Server public key
vault_wireguard_proxy_route_cidrv6 | Private network (applicable if ipv6_flag set)
vault_wireguard_proxy_route_gwv6 | Private network gateway (applicable if ipv6_flag set)
ipv6_flag | enable IPv6 for Wireguard

`wireguard_proxy_peers_list` can contain up to 253 peers. Structure is described [here](../../README.md). Each peer has the following attributes:

Peer attribute Name | Description
------------------- | -----------
preshared_key | Preshared key across all peers and server
public_key | Peer public key
private_key | Peer private key
ipv6_address | Peer IPv6 address (applicable if ipv6_flag set)
extra_allowed_ip_address_cidrv6 | optional additional IPv6 to allow for site VPN

Example Playbook
----------------

Playbook should contain at least the following content:

```yaml
- hosts: all
  gather_facts: true
  collections:
    - jaybeede.linux_server
  tasks:
    - import_role:
        name: wireguard
      when: inventory_hostname in groups["vpn"]
```

Many thanks to [ohshitgorillas](https://www.reddit.com/user/ohshitgorillas/) for his precious hints for IPv6 configuration on wireguard: [Guide: How to Set Up WireGuard with IPv6 in Docker (Linux) : r/WireGuard](https://www.reddit.com/r/WireGuard/comments/178uolr/guide_how_to_set_up_wireguard_with_ipv6_in_docker/?rdt=43164).

License
-------

[GPL-3.0-or-later](../../LICENSE)

Author Information
------------------

JayBee <jb.social@outlook.com>
