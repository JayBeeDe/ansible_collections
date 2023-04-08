#!/usr/bin/env python3

import sys
import os
from pykeepass import PyKeePass


def get_entry(kp, path):
    # because kp.find_entries(path=title, first=True) doesn't work
    group = kp.root_group
    items = path.split("/")
    items.pop(0)
    entry = items.pop()
    for item in items:
        group = kp.find_groups(group=group, name=item, first=True, recursive=False)
    return kp.find_entries(group=group, title=entry, first=True)


attr = None
if len(sys.argv) > 2:
    attr = sys.argv[2]
if not "PYKEEPASS_DATABASE" in os.environ or not "PYKEEPASS_KEYFILE" in os.environ:
    print("PYKEEPASS_DATABASE and PYKEEPASS_KEYFILE must both exist", file=sys.stderr)
    sys.exit(1)

kp = PyKeePass(os.environ["PYKEEPASS_DATABASE"], keyfile=os.environ["PYKEEPASS_KEYFILE"])
entry = get_entry(kp, sys.argv[1])
if attr is None:
    print(entry)
else:
    print(getattr(entry, attr))
