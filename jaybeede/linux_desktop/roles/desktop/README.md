desktop
=========

Desktop icons for a ready to go working station: arc-menu shortcuts, gnome bookmarks, desktop icons, autostart launchers, user icons.

Requirements
------------

[desktop_launchers](../../plugins/modules/desktop_launchers.py) module is required for that role.

:warning: PyGObject is required for the desktop_launchers module: see [official installation instructions](https://pygobject.readthedocs.io/en/latest/getting_started.html).

Role Variables
--------------

Variable Name | Description
------------- | -----------
user | The target machine session username
home | The target machine session username's home directory
kdbx_path | Path to the keepassxc kdbx file
key_path | Path to the keepassxc key file
rdp_host | RDP host for the local virtual machine
rdp_name | RDP name for the local virtual machine
rdp_port | RDP port for the local virtual machine

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
        name: desktop
```

License
-------

[GPL-3.0-or-later](../../LICENSE)

Author Information
------------------

JayBee <jb.social@outlook.com>
