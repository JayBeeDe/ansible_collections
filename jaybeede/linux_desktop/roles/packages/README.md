packages
=========

Packages for linux desktop: apt, snap and clean useless default packages.

Role Variables
--------------

Variable Name | Description
------------- | -----------
country | Country local to be configured (ISO code), uppercase
language | Display language to be configured (ISO code), lowercase
theme_primary_name | Primary gnome theme name (for example Yaru-dark to download org.gtk.Gtk3theme.Yaru-dark flatpak package theme)

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
        name: packages
```

License
-------

[GPL-3.0-or-later](../../LICENSE)

Author Information
------------------

JayBee <jb.social@outlook.com>
