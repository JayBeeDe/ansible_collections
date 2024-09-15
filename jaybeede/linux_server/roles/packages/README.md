packages
=========

Packages for linux server: apt and clean useless default packages.

Role Variables
--------------

Variable Name | Description
------------- | -----------
locale | Display language to be configured (ISO code)

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
        name: packages
```

License
-------

[GPL-3.0-or-later](../../LICENSE)

Author Information
------------------

JayBee <jb.social@outlook.com>
