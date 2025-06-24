edge
=========

Services and shell configuration for ARM linux server at home: networking, ssh, firewall, firmware, motd, bash aliases, environment variables, rc local scripts, NFS share.

Role Variables
--------------

Variable Name | Description
------------- | -----------
user | The target machine session username
home | The target machine session username's home directory
ipv6_flag | Enable IPv6 for normal and wireguard client
assets_path | Path to assets that will be shared with NFS
nfs_subnet | Network allowed to access the NFS share
transmission_subnet | Network allowed to access the transmission web interface
transmission_peer_port | Network port used for transmission daemon peer
transmission_rpc_port | Network port used for transmission daemon RPC
transmission_rpc_hash | Hashed password used for transmission daemon when authentication is enabled (unused)
wireguard_client_peers_list | Same as [wireguard_proxy_peers_list](../wireguard/README.md) but items of the list that match the inventory hostname(s) with role edge will be configured as wireguard client
wireguard_client_public_key | Same as [vault_wireguard_proxy_public_key](../wireguard/README.md)
wireguard_client_public_key | VPN endpoint the client shall connect to

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
        name: edge
      when: inventory_hostname in groups["edge"]
```

License
-------

[GPL-3.0-or-later](../../LICENSE)

Author Information
------------------

JayBee <jb.social@outlook.com>
