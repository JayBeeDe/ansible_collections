#!/usr/bin/env python3

import os
import argparse
from pykeepass import PyKeePass

PROG = "kdbxQuery"
VERSION = "0.2"


def get_entry(kp, path):
    # because kp.find_entries(path=title, first=True) doesn't work
    group = kp.root_group
    items = path.split("/")
    items.pop(0)
    entry = items.pop()
    for item in items:
        group = kp.find_groups(group=group, name=item, first=True, recursive=False)
    return kp.find_entries(group=group, title=entry, first=True)


def main():
    parser = argparse.ArgumentParser(
        prog=PROG,
        description=PROG
    )

    group = ""
    parser.add_argument("-g", "--group", type=str, required=False, help="KeePass entry folder (" + group + " by default)")

    parser.add_argument("-t", "--title", type=str, required=True, help="KeePass entry folder")

    path = ""
    help_msg = "Path to kdbx file"
    required = True
    if "PYKEEPASS_DATABASE" in os.environ:
        path = os.environ["PYKEEPASS_DATABASE"]
        help_msg += " (" + path + " by default)"
        required = False
    parser.add_argument("-p", "--path", type=str, required=required, help=help_msg)

    keyfile = ""
    help_msg = "Path to key file"
    required = True
    if "PYKEEPASS_KEYFILE" in os.environ:
        keyfile = os.environ["PYKEEPASS_KEYFILE"]
        help_msg += " (" + keyfile + " by default)"
        required = False
    parser.add_argument("-k", "--keyfile", type=str, required=required, help=help_msg)

    attributes = ["username", "password"]
    parser.add_argument("-a", "--attribute", type=str, action="append", required=False, help="Attributes (" + ", ".join(attributes) + " by default)")

    parser.add_argument("-V", "--version", action="version", version=PROG + " version " + VERSION)

    args = parser.parse_args()
    if args.group:
        group = args.group
    title = args.title
    if args.path:
        path = args.path
    if args.keyfile:
        keyfile = args.keyfile
    if args.attribute:
        attributes = args.attribute

    kp = PyKeePass(path, keyfile=keyfile)
    entry = get_entry(kp, group + "/" + title)
    res = ""
    for attribute in attributes:
        if getattr(entry, attribute) and type(getattr(entry, attribute) != bool):
            res += str(getattr(entry, attribute))
        res += " "

    print(res[:-1])


if __name__ == "__main__":
    main()
