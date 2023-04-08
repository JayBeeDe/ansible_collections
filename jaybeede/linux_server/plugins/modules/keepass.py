#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import random
import string
import traceback
from ansible.module_utils.basic import AnsibleModule, missing_required_lib

PYKEEPASS_IMP_ERR = None
try:
    from pykeepass import PyKeePass, create_database
    import pykeepass.exceptions
except ImportError:
    PYKEEPASS_IMP_ERR = traceback.format_exc()
    pykeepass_found = False
else:
    pykeepass_found = True

DOCUMENTATION = '''
---
module: keepass
author: JayBee
version_added: "2.0.0"
short_description: Manage kdbx Keepass Databases
description: Ansible module to add, alter and get passwords, usernames, titles, url

requirements:
    - PyKeePass

options:
    database:
        description:
            - Path of the keepass database. Will be created if doesn't exist
        required: true
        type: str

    keyfile:
        description:
            - Path of the keepass keyfile
        required: true
        type: str

    title:
        description:
            - Title or full path (group/subgroup1/subgroup2/title) of the entry
        required: true
        type: str

    username:
        description:
            - Username of the entry to be set. Ignored (read only mode) if not provided
        required: false
        type: str

    password:
        description:
            - Password to be set. Ignored (read only mode) if not provided. Incompatible with password_length
        required: false
        type: str

    password_length:
        description:
            - Password length to be generated. Ignored (read only mode) if not provided. Incompatible with password
        required: false
        type: int

    url:
        description:
            - Password URL. Ignored (read only mode) if not provided
        required: false
        type: str
'''

EXAMPLES = '''
- name: Get existing password
  keepass:
    database: /tmp/vault.kdbx
    keyfile: /tmp/vault.key
    title: MariaDB
  register: creds
- debug:
    msg: "Username: {{ creds.username }}, Password: {{ creds.password }}, New password: {{ creds.changed }}"

- name: Generate a new password
  keepass:
    database: /tmp/vault.kdbx
    keyfile: /tmp/vault.key
    title: MariaDB
    username: mariadb-admin
    password_length: 45
  register: creds
- debug:
    msg: "Username: {{ creds.username }}, Password: {{ creds.password }}, New password: {{ creds.changed }}"

- name: Set a new password
  keepass:
    database: /tmp/vault.kdbx
    keyfile: /tmp/vault.key
    title: MariaDB
    username: mariadb-admin
    password: password
    url: https://my-website.com
  register: creds
- debug:
    msg: "Username: {{ creds.username }}, Password: {{ creds.password }}, New password: {{ creds.changed }}"
'''

RETURN = '''
title:
    description: The updated or retrieved password full path (group/subgroup1/subgroup2/title)
    type: str
username:
    description: The updated or retrieved password username
    type: str
password:
    description: The updated or retrieved password value
    type: str
url:
    description: The updated or retrieved password url
    type: str
'''


def get_entry(kp, path):
    # because kp.find_entries(path=title, first=True) doesn't work
    group = kp.root_group
    items = path.split("/")
    items.pop(0)
    entry = items.pop()
    for item in items:
        group = kp.find_groups(group=group, name=item, first=True, recursive=False)
    return kp.find_entries(group=group, title=entry, first=True)


def create_group(kp, path):
    group = kp.root_group
    items = path.split("/")
    items.pop(0)
    for item in items:
        cursor_group = group
        group = kp.find_groups(group=cursor_group, name=item, first=True)
        if not group:
            group = kp.add_group(destination_group=cursor_group, group_name=item, icon="47", notes="Generated by ansible")
    return kp, group


def generate_password(length):
    alphabet = string.ascii_letters + string.digits
    return "".join(random.choice(alphabet) for _ in range(length))


def main():
    module = AnsibleModule(
        argument_spec=dict(
            database=dict(type="str", required=True),
            keyfile=dict(type="str", required=True),
            title=dict(type="str", required=True),
            username=dict(type="str", required=False, default=None),
            password=dict(type="str", required=False, default=None, no_log=True),
            url=dict(type="str", required=False, default=None),
            password_length=dict(type="int", required=False, default=None, no_log=False),
        ),
        supports_check_mode=True
    )

    result = dict(
        changed=False,
        title="",
        username="",
        password="",
        url=""
    )

    if not pykeepass_found:
        module.fail_json(msg=missing_required_lib("pykeepass"), exception=PYKEEPASS_IMP_ERR)

    database = module.params.get("database")
    keyfile = module.params.get("keyfile")
    title = module.params.get("title")
    username = module.params.get("username")
    password = module.params.get("password")
    password_length = module.params.get("password_length")
    url = module.params.get("url")

    if not keyfile:
        module.fail_json(msg="'keyfile' is required")

    if not title or len(title) == 0:
        module.fail_json(msg="'title' is required")

    if password and " " in password:
        module.fail_json(msg="'password' cannot contains spaces")

    if title[0] != "/":
        title = "/" + title

    if title == "/":
        module.fail_json(msg="'title' cannot be the root")

    if password and password_length:
        module.fail_json(msg="Incompatible parameters. Either provide 'password' or 'password_length' or none of them!")

    read_only = True
    if username or password or password_length or url:
        read_only = False

    try:
        kp = PyKeePass(database, keyfile=keyfile)
    except FileNotFoundError:
        try:
            read_only = False
            kp = create_database(database, keyfile=keyfile)
            # Database doesn't exist, let's create it
        except IOError:
            KEEPASS_OPEN_ERR = traceback.format_exc()  # pylint: disable=unused-variable
            module.fail_json(msg="Could not create the database")
        except:
            KEEPASS_OPEN_ERR = traceback.format_exc()
            module.fail_json(msg="Unknown error while trying to create the database")
    except IOError:
        KEEPASS_OPEN_ERR = traceback.format_exc()
        module.fail_json(msg="Could not open the database or keyfile")
    except pykeepass.exceptions.CredentialsError:
        KEEPASS_OPEN_ERR = traceback.format_exc()
        module.fail_json(msg="Could not open the database, as the credentials are wrong")
    except (pykeepass.exceptions.HeaderChecksumError, pykeepass.exceptions.PayloadChecksumError):
        KEEPASS_OPEN_ERR = traceback.format_exc()
        module.fail_json(msg="Could not open the database, as the checksum of the database is wrong. This could be caused by a corrupt database")
    except:
        KEEPASS_OPEN_ERR = traceback.format_exc()
        module.fail_json(msg="Unknown error while trying to create the database")

    entry = get_entry(kp, title)
    # try to get the entry from the database
    if entry:
        result["title"] = "/" + entry.path  # pylint: disable=no-member
        result["username"] = entry.username  # pylint: disable=no-member
        result["password"] = entry.password  # pylint: disable=no-member
        result["url"] = entry.url  # pylint: disable=no-member
    if read_only:
        # we have what we want, let's exit
        module.exit_json(**result)

    if password_length:
        # password needs to be generated (password variable is None)
        password = generate_password(password_length)

    if result["title"] != title or result["username"] != username or result["password"] != password or result["url"] != url:
        # we have a change
        result["changed"] = True
        if entry:
            entry.title = os.path.basename(title)
            entry.username = username or ""
            entry.password = password
            entry.url = url or ""
        else:
            result["hasentry"] = False
            kp, group = create_group(kp, os.path.dirname(title))
            kp.add_entry(group, os.path.basename(title), "sds", password, icon="47", notes="Generated by ansible")
            # add entry and its group
        kp.save()
        # commit changes
        result["title"] = title  # return the path
        result["username"] = username
        result["password"] = password
        result["url"] = url

    module.exit_json(**result)


if __name__ == "__main__":
    main()
