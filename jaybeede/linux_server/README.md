# linux_server

linux_server collection provides a set of ready to use roles & modules to quicky deploy a Debian server: OS and application configuration.

## Collection Content

### Roles

* [packages](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_server/roles/packages/README.md)
* [system](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_server/roles/system/README.md)

## Features overview

### Roles

"Configuration" doesn't prevent the user from changing the configuration whereas "Policy" prevents the user from changing the configuration

Application | Configuration | Policy Restriction
----------- | ------------- | ------------------
chromium + extensions | yes | yes
conky | yes | no
flameshot | yes | no
git | yes | no
keepassXC | yes | yes
libreoffice | yes | no
nemo | yes | no
onedrive | yes | no
pulseaudio | yes | no
remmina | yes | no
terminator | yes | no
VLC | yes | no
vscode + extensions | yes | no
evince | yes | no

## Prerequisites

### Vault

Create a directory group_vars into [plugins/inventory](https://github.com/JayBeeDe/ansible_collections/tree/main/jaybeede/linux_server/plugins/inventory) directory.
Create a file all.yml into group_vars directory with the following content:

```yaml
vault_user: "my vault_user"
vault_password: "my vault_password"  # if user doesn't exist, user will be created with specified password. Otherwise, password will not be updated
vault_email: "my vault_email"
vault_nickname: "my vault_nickname"
vault_kdbx_path: "my vault_kdbx_path"
vault_key_path: "my vault_key_path"
vault_rdp_port: "my vault_rdp_port"
vault_rdp_user: "my vault_rdp_user"
vault_tokenGithub: "my vault_tokenGithub"
vault_tokenGitlab: "my vault_tokenGitlab"
```

**Encrypt** that file.

### General

Node must be running debian server and user variable must be correctly defined (in vault).<br />
Target machine must be reachable over SSH or not if local machine.<br />
Partitioning is **NOT** configured by the collection.<br />

Warning: All roles dependencies must be met:<br />
* system role:<br />
  - /VMs will be used as folder to store the local virtual machine file. Please ensure you have enough space.<br />
  - nmcli python library might need to be patched. Please remplace (or ensure the content is already ok): see [system role documentation for details](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_server/roles/system/README.md)<br />

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
```

Warning: Order is important:
> * Packages role is required by other roles and must be installed FIRST.

Then you need to create an inventory file that contains all the variables: see [plugins/inventory/inventory.yml](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_server/inventory/inventory.yml) file.

For the description of all variables, see the role documentation.

Then, once ready, you just need to run:

```bash
ansible-playbook linux_server.yml -i jaybeede/linux_server/inventory/inventory.yml --ask-vault-pass
```