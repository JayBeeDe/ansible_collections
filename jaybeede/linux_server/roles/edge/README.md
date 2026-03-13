edge
=========

Services and shell configuration for ARM linux server at home: networking, ssh, firewall, firmware, motd, bash aliases, environment variables, rc local scripts, NFS share.

Role Variables
--------------

Variable Name | Description
------------- | -----------
user | The target machine session username
home | The target machine session username's home directory
assets_path | Path to assets that will be shared with NFS
nfs_subnet | Network allowed to access the NFS share
transmission_subnet | Network allowed to access the transmission web interface
transmission_peer_port | Network port used for transmission daemon peer
transmission_rpc_port | Network port used for transmission daemon RPC
transmission_rpc_hash | Hashed password used for transmission daemon when authentication is enabled (unused)
wireguard_peers_list | List of peers to configure (see details below)
wireguard_public_key | Same as [vault_wireguard_public_key](../wireguard/README.md)
wireguard_public_key | VPN endpoint the client shall connect to

`wireguard_peers_list` can contain up to 253 peers. Structure is described [here](../../README.md). Each peer has the following attributes:

Peer attribute Name | Description
------------------- | -----------
preshared_key | Preshared key across all peers and server
public_key | Peer public key
private_key | Peer private key
ipv6_address | Peer IPv6 address

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
