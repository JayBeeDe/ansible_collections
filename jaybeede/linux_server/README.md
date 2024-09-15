# linux_server

linux_server collection provides a set of ready to use roles & modules to quickly deploy a Debian server: OS and application configuration.

## Collection Content

### Roles

* [packages](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_server/roles/packages/README.md)
* [system](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_server/roles/system/README.md)
* [docker](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_server/roles/docker/README.md)
* [cron](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_server/roles/cron/README.md)

### Modules

* [keepass](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_server/plugins/modules/keepass.py)

## Features overview

### Modules <!-- markdownlint-disable-line no-duplicate-heading -->

Module | Feature | Description
------ | ------- | -----------
keepass | Password management | Secure place to save all passwords and token used by cron scripts

### Roles <!-- markdownlint-disable-line no-duplicate-heading -->

Feature |
------- |
[Apache Guacamole](https://guacamole.apache.org/) clientless remote desktop gateway
[Etherpad](https://etherpad.org/) online editor
[jawanndenn](https://github.com/hartwork/jawanndenn) meetings scheduler and polls manager
[Matrix](https://matrix.org/) network for secure and decentralised communication
[Nginx](https://nginx.org/) reverse proxy
[Wordpress](https://wordpress.com/) blog

## Prerequisites

### Vault

Create a directory group_vars into [plugins/inventory](https://github.com/JayBeeDe/ansible_collections/tree/main/jaybeede/linux_server/plugins/inventory) directory.
Create a file all.yml into group_vars directory with the following content:

```yaml
vault_user: "my vault_user"
vault_password: "my vault_password"  # if user doesn't exist, user will be created with specified password. Otherwise, password will not be updated
vault_email: "my vault_email"
vault_nickname: "my vault_nickname"
vault_ssh_port: "my vault_ssh_port"
vault_ssh_host1: "my vault_ssh_host1"
vault_become_pass: "my vault_become_pass"
vault_domain: "my vault_domain"
vault_blogdb_password: "my vault_blogdb_password"
vault_virtualdesktopdb_password: "my vault_virtualdesktopdb_password"
vault_limesurveyui_password: "my vault_limesurveyui_password"
vault_limesurveydb_password: "my vault_limesurveydb_password"
vault_etherpadui_password: "my vault_etherpadui_password"
vault_etherpaddb_password: "my vault_etherpaddb_password"
vault_matrixdb_password: "my vault_matrixdb_password"
vault_matrixproxy_secret: "my vault_matrixproxy_secret"
vault_matrixgtw_register_secret: "my vault_matrixgtw_register_secret"
vault_telegram_token: "my vault_telegram_token"
vault_telegram_chatid: "my vault_telegram_chatid"
vault_matrix_deviceid: "my vault_matrix_deviceid"
vault_matrix_userid: "my vault_matrix_userid"
vault_matrix_chatid: "my vault_matrix_chatid"
vault_matrix_token: "my vault_matrix_token"
vault_matrixtelegrambridge_appid: "my vault_matrixtelegrambridge_appid"
vault_matrixtelegrambridge_apphash: "my vault_matrixtelegrambridge_apphash"
vault_matrixtelegrambridge_astoken: "my vault_matrixtelegrambridge_astoken"
vault_matrixtelegrambridge_hstoken: "my vault_matrixtelegrambridge_hstoken"
vault_matrixtelegrambridge_senderlocalpart: "my vault_matrixtelegrambridge_senderlocalpart"
vault_matrixwhatsappbridge_astoken: "my vault_matrixwhatsappbridge_astoken"
vault_matrixwhatsappbridge_hstoken: "my vault_matrixwhatsappbridge_hstoken"
vault_matrixwhatsappbridge_senderlocalpart: "my vault_matrixwhatsappbridge_senderlocalpart"
vault_kdbx_path: "my vault_kdbx_path"
vault_kdbx_key_path: "my vault_kdbx_key_path"
```

**Encrypt** that file.

### General

Node must be running debian server and user variable must be correctly defined (in vault).<br />
Target machine must be reachable over SSH or not if local machine.<br />
Current user must already be configured<br />
Partitioning is **NOT** configured by the collection.<br />

## Quick start

You can put all the roles within the following order in your playbook (let's call it linux_server.yml):

```yaml
- hosts: all
  gather_facts: true
  collections:
    - jaybeede.linux_server
  tasks:
    - import_role:
        name: packages
    - import_role:
        name: system
    - import_role:
        name: docker
    - import_role:
        name: cron
```

Warning: Order is important:
>
> * Packages role is required by other roles and must be installed FIRST.

Then you need to create an inventory file that contains all the variables: see [plugins/inventory/inventory.yml](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_server/inventory/inventory.yml) file.

For the description of all variables, see the role documentation.

Then, once ready, you just need to run:

```bash
ansible-playbook linux_server.yml -i jaybeede/linux_server/plugins/inventory/inventory.yml --ask-vault-pass
```
