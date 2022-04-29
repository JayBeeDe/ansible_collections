# linux_desktop

linux_desktop collection provides a set of ready to use roles & modules to quicky deploy a Ubuntu desktop computer: OS, desktop and application configuration.

## Collection Content

### Roles

* [applications](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_desktop/roles/applications/README.md)
* [desktop](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_desktop/roles/desktop/README.md)
* [gnome](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_desktop/roles/gnome/README.md)
* [packages](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_desktop/roles/packages/README.md)
* [system](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_desktop/roles/system/README.md)

### Modules

* [desktop_launchers](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_desktop/plugins/modules/desktop_launchers.py)
* [gnome_extensions](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_desktop/plugins/modules/gnome_extensions.py)
* [keyboard_shortcuts](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_desktop/plugins/modules/keyboard_shortcuts.py)

## Features overview

### Modules

Module | Feature | Description
------ | ------- | -----------
desktop_launchers | Manage desktop icons | create, edit, remove desktop icons according the freedesktop.org specifications
gnome_extensions | Manage Gnome extensions | install, update, uninstall, enable, disable gnome extensions
keyboard_shortcuts | Manage keyboard shortcut | create, edit remove buldtin or custom command bindings to a keyboard shortcut

### Roles

"Configuration" doesn't prevent the user from changing the configuration whereas "Policy" prevents the user from changing the configuration

Application | Configuration | Policy Restriction
----------- | ------------- | ------------------
chrome + extensions | yes | yes
conky | yes | no
flameshot | yes | no
git | yes | no
keepassXC | yes | yes
libreoffice | yes | no
nemo | yes | no
onedrive | yes | no
remmina | yes | no
terminator | yes | no
VLC | yes | no
vscode + extensions | yes | no
evince | yes | no

<br />

Gnome Feature | Configuration
------------- | -------------
extension: [ArcMenu](https://gitlab.com/arcmenu/ArcMenu) | yes
extension: [bing-wallpaper-gnome](https://github.com/neffo/bing-wallpaper-gnome-extension) | yes
extension: [dash-to-panel](https://github.com/home-sweet-gnome/dash-to-panel) | yes
extension: [datetime-format](https://extensions.gnome.org/extension/1173/datetime-format/) | yes
extension: [GSConnect](https://github.com/GSConnect/gnome-shell-extension-gsconnect) | yes
extension: [gse-sound-output-device-chooser](https://github.com/kgshank/gse-sound-output-device-chooser) | yes
extension: [minimize-to-tray](https://github.com/oae/gnome-shell-minimize-to-tray) | yes
extension: [Put Window](https://github.com/negesti/gnome-shell-extensions-negesti) | yes
extension: [remove-dropdown-arrows](https://github.com/mpdeimos/gnome-shell-remove-dropdown-arrows) | yes
extension: [removeaccesibility](https://extensions.gnome.org/extension/112/remove-accesibility/) | yes
extension: [steal-my-focus](https://extensions.gnome.org/extension/234/steal-my-focus/) | yes
extension: [unblank](https://extensions.gnome.org/extension/1414/unblank/) | yes
dark-mode | yes
night-light | yes
power settings | yes
notifications | yes
printer | yes

## Prerequisites

### Vault

Create a directory group_vars into [plugins/inventory](https://github.com/JayBeeDe/ansible_collections/tree/main/jaybeede/linux_desktop/plugins/inventory) directory.
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

Node must be running ubuntu desktop and user variable must be correctly defined (in vault).<br />
Target machine must be reachable over SSH or not if local machine.<br />
Partitioning is **NOT** configured by the collection.<br />

Warning: All roles dependencies must be met:<br />
* applications role:<br />
  - Add the chrome Bookmarks file into the [files/](https://github.com/JayBeeDe/ansible_collections/tree/main/jaybeede/linux_desktop/roles/applications/files) directory. On Linux, you can find this file under $HOME/.config/google-chrome/Default/Bookmarks.<br />
* desktop role:<br />
  - PyGObject is required for the desktop_launchers module: see [official installation instructions](https://pygobject.readthedocs.io/en/latest/getting_started.html).<br />
* gnome role:<br />
  - /usr/share/gnome-shell/extensions/ must have recursively 777 as chmod when scope is set to system.<br />
* system role:<br />
  - /VMs will be used as folder to store the local virtual machine file. Please ensure you have enough space.<br />
  - nmcli python library might need to be patched. Please remplace (or ensure the content is already ok): see [system role documentation for details](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_desktop/roles/system/README.md)<br />

## Quick start

You can put all the roles within the following order in your playbook (let's call it linux_desktop.yml):

```yaml
- hosts: all
  gather_facts: true
  collections:
    - jaybeede.linux_desktop
  tasks:
    - import_role:
        name: packages
    - import_role:
        name: system
    - import_role:
        name: applications
    - import_role:
        name: desktop
    - import_role:
        name: gnome
```

Warning: Order is important:
> * Packages role is required by other roles and must be installed FIRST.
> * Desktop role is required by gnome role: gnome role must be run AFTER desktop role

Then you need to create an inventory file that contains all the variables: see [plugins/inventory/inventory.yml](https://github.com/JayBeeDe/ansible_collections/blob/main/jaybeede/linux_desktop/plugins/inventory/inventory.yml) file.

For the description of all variables, see the role documentation.

Define your current user as sudoer:

echo "my-username  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/my-username

Then, once ready, you just need to run as current user:

```bash
ansible-playbook linux_desktop.yml -i jaybeede/linux_desktop/plugins/inventory/inventory.yml --ask-vault-pass
```