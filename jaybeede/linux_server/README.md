# linux_server

linux_server collection provides a set of ready to use roles & modules to quickly deploy a Debian server: OS and application configuration.

## Collection Content

### Roles

* [packages](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_server/roles/packages/README.md)
* [system](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_server/roles/system/README.md)
* [docker](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_server/roles/docker/README.md)

## Prerequisites

### Vault

Create a directory group_vars into [plugins/inventory](https://github.com/JayBeeDe/ansible_collections/tree/main/jaybeede/linux_server/plugins/inventory) directory.
Create a file all.yml into group_vars directory with the following content:

```yaml
vault_user: "my vault_user"
vault_password: "my vault_password"  # if user doesn't exist, user will be created with specified password. Otherwise, password will not be updated
vault_ssh_port: "my vault_ssh_port"
vault_ssh_host1: "my vault_ssh_host1"
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
