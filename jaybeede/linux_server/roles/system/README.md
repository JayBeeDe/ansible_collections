system
=========

Services and shell configuration for linux server: networking, ssh, firewall, virtualization, grub, motd, printer, bash aliases, environment variables, rc local scripts.

Role Variables
--------------

Variable Name | Description
------------- | -----------
user | The target machine session username
home | The target machine session username's home directory
git_rootrepo | Path to the git root repo (personal)
network_dns | DNS Client to be configured on target machine
network_interface | Network interface to be configured on target machine
ssh_port | local SSH port (to configure SSH loopback)

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
        name: system
```

License
-------

[GPL-3.0-or-later](../../LICENSE)

Author Information
------------------

JayBee <jb.social@outlook.com>
