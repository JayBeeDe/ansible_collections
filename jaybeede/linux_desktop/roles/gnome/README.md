gnome
=========

Gnome configuration for linux desktop: gnome extensions, dark-mode, night-light, evince, nemo, power settings, notifications, wallpaper, keyboard shortcuts.

Requirements
------------

[gnome_extensions](../../plugins/modules/gnome_extensions.py) and [keyboard_shortcuts](../../plugins/modules/keyboard_shortcuts.py) modules are required for that role.
[json2variant](../../plugins/filter/json2variant.py) filter is required for that role.

:warning: /usr/share/gnome-shell/extensions/ must have recursively 777 as chmod when scope is set to system.

Role Variables
--------------

Variable Name | Description
------------- | -----------
user | The target machine session username
home | The target machine session username's home directory
legal_email | Legal email to display on the gnome banner message
legal_name | Legal name to display on the gnome banner message
git_rootrepo | Path to the git root repo (personal)
tokenGithub | GitHub token to bypass GitHub API limitation when downloading gnome extension
theme_primary_name | Primary gnome theme name (for example Yaru-dark)
theme_secondary_name | Real gnome theme name (for example Yaru-purple-dark)

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
        name: gnome
```

License
-------

[GPL-3.0-or-later](../../LICENSE)

Author Information
------------------

JayBee <jb.social@outlook.com>
