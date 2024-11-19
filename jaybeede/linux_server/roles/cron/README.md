cron
=========

Services and shell configuration for linux server: networking, ssh, firewall, virtualization, grub, motd, printer, bash aliases, environment variables, rc local scripts.

Requirements
------------

[keepass](../../plugins/modules/keepass.py) module is required for that role.

Role Variables
--------------

Variable Name | Description
------------- | -----------
user | The target machine session username
home | The target machine session username's home directory
kdbx_path | Path where the encrypted passwords will be saved
kdbx_key_path | Path to the key file needed to decrypt passwords
email | email used in SSL certificate renewal process
server_domain | server domain to renew in SSL certificate renewal process
matrix_domain | matrix domain to renew in SSL certificate renewal process
telegram_chatid | Telegram chat id to send cron notification messages
telegram_token | Telegram token to send cron notification messages
matrix_userid | Matrix user id to send cron notification messages (backup channel)
matrix_token | Matrix token to send cron notification messages (backup channel)
matrix_homeserver | Matrix home server domain to send cron notification messages (backup channel)
matrix_chatid | Matrix chat id to send cron notification messages (backup channel)
matrix_deviceid | Matrix device id to send cron notification messages (backup channel)
blogdb_password | Database password used to perform blog backup
virtualdesktopdb_password | Database password used to perform guacamole backup
limesurveydb_password | Database password used to perform limesurvey backup
etherpaddb_password | Database password used to perform etherpad backup

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
        name: cron
```

License
-------

[GPL-3.0-or-later](../../LICENSE)

Author Information
------------------

JayBee <jb.social@outlook.com>
