system
=========

Services, printer and shell configuration for linux desktop: networking, ssh, firewall, virtualization, grub, motd, printer, bash aliases, environment variables, rc local scripts.

Requirements
------------

:warning: /VMs will be used as folder to store the local virtual machine file. Please ensure you have enough space.

:warning: nmcli python library might need to be patched. Please remplace (or ensure the content is already ok):
> /usr/lib/python3/dist-packages/ansible/modules/net_tools/nmcli.py line 567:

**FROM**
```python
try:
 import gi
 gi.require_version('NMClient', '1.0')
 gi.require_version('NetworkManager', '1.0')
 from gi.repository import NetworkManager, NMClient
```
**REPLACE BY**
```python
 try:
 import gi
 gi.require_version('NM', '1.0')
 from gi.repository import NM
```

Role Variables
--------------

Variable Name | Description
------------- | -----------
user | The target machine session username
home | The target machine session username's home directory
git_rootrepo | Path to the git root repo (personal)
network_dns | DNS Client to be configured on target machine
network_interface | Network interface to be configured on target machine
network_ip | Network IP address to be configured on target machine
network_subnet | Network subnet to be configured on target machine
password | (optional) If set, target user password will be changed
printer_ip | Printer IP to be configured on target machine
printer_model | (Brother) Printer model to be configured on target machine
rdp_name | RDP name for the local virtual machine
ssh_port | local SSH port (to configure SSH loopback)

Example Playbook
----------------

Playbook should contain at least the following content:

```yaml
- hosts: all
  gather_facts: true
  collections:
    - jaybeede.linux_desktop
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
