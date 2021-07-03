applications
=========

Desktop applications configuration: pulseaudio, chromium, keepassxc, VLC, conky, flameshot, vscode, terminator, remmina, libreoffice, onedrive, git.

Requirements
------------

:warning: Add the chomium Bookmarks file into the [files/](files) directory. On Linux, you can find this file under $HOME/.config/chromium/Default/Bookmarks.

Role Variables
--------------

Variable Name | Description
------------- | -----------
user | The target machine session username
home | The target machine session username's home directory
git_email | Git user.email identity to be configured
git_name | Git user.name identity to be configured
rdp_host | RDP host for the local virtual machine
rdp_name | RDP name for the local virtual machine
rdp_port | RDP port for the local virtual machine
rdp_sharefolder | Path to the host machine share folder for the local virtual machine
rdp_user | RDP user for the local virtual machine

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
        name: applications
```

License
-------

[GPL-3.0-or-later](../../LICENSE)

Author Information
------------------

JayBee <jb.social@outlook.com>
