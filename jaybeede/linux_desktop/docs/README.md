# Ansible Collection - jaybeede.linux_desktop

## Dependencies

Node must be running ubuntu desktop and user defined in vault.

plugins/inventory/group_vars/all.yml ENCRYPTED vault file must exist with all the vault_* variables defined into it (see list within the plugins/inventory/inventory.yml file)

Packages role is required by other roles and must be installed first.

PyGObject is required for the desktop_launchers module; see [official installation instructions](https://pygobject.readthedocs.io/en/latest/getting_started.html).

python3-psutil is required by the desktop role
Add dependencies:
  - role: packages

Role desktop requires the VM to be logged in as specified user

Role desktop is required by gnome role

Run the following command:

ansible-playbook all.yml -i jaybeede/linux_desktop/plugins/inventory/inventory.yml --ask-vault-pass

provide the vault password




NOTE that library may need to be patched here
/usr/lib/python3/dist-packages/ansible/modules/net_tools/nmcli.py line 567
FROM
try:
 import gi
 gi.require_version('NMClient', '1.0')
 gi.require_version('NetworkManager', '1.0')
 from gi.repository import NetworkManager, NMClient
REPLACE BY
 try:
 import gi
 gi.require_version('NM', '1.0')
 from gi.repository import NM




 gnome_extensions requires ansible to be installed



 /usr/share/gnome-shell/extensions/ must have recursivly 777 as chmod when scope is set to system