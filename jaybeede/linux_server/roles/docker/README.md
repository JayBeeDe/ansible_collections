docker
=========

Services and shell configuration for linux server: networking, ssh, firewall, virtualization, grub, motd, printer, bash aliases, environment variables, rc local scripts.

Role Variables
--------------

Variable Name | Description
------------- | -----------
user | The target machine session username
home | The target machine session username's home directory
ini_path | path where database initial backups are stored to bootstrap database
server_domain | Server domain
matrix_domain | Matrix server domain
network_dns | nginx primary resolver
network_dns2 | nginx secondary resolver
https_flag | Use HTTPS when set to true
blogdb_password | Blog database password
etherpaddb_password | Etherpad database password
limesurveydb_password | Limesurvey database password
matrixdb_password | Matrix database password
virtualdesktopdb_password | Guacamole database password
matrix_homeserver | Matrix home server URL
matrixgtw_register_secret | synapse registration_shared_secret setting
matrixproxy_secret | Matrix sliding sync SYNCV3_SECRET setting
telegram_chatid | Matrix Telegram bridge bot commands authorization
telegram_token | Matrix Telegram bridge bot token
matrixtelegrambridge_apphash | Matrix Telegram bridge api_hash setting
matrixtelegrambridge_appid | Matrix Telegram bridge api_id setting
matrixtelegrambridge_astoken | Matrix Telegram bridge as_token setting
matrixtelegrambridge_hstoken | Matrix Telegram bridge hs_token setting
matrixtelegrambridge_senderlocalpart | Matrix Telegram bridge registration sender_localpart setting
matrixwhatsappbridge_astoken | Matrix WhatsApp bridge as_token setting
matrixwhatsappbridge_hstoken | Matrix WhatsApp bridge hs_token setting
matrixwhatsappbridge_senderlocalpart | Matrix WhatsApp bridge registration sender_localpart setting

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
        name: docker
```

License
-------

[GPL-3.0-or-later](../../LICENSE)

Author Information
------------------

JayBee <jb.social@outlook.com>
