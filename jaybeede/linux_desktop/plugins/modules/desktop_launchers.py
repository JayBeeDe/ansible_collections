#!/usr/bin/python
# -*- coding: utf-8 -*-

import gi
import os
gi.require_version("Gtk", "3.0")
os.environ["DISPLAY"] = ":0"
from gi.repository import Gtk
from gi.repository import GLib
import locale
import re
from collections import defaultdict
from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils.urls import open_url
import collections

DOCUMENTATION = '''
---
module: desktop_launchers
author: JayBee
version_added: "2.0.0"
short_description: Create desktop files according the freedesktop.org specifications
description: Ansible Module to create .desktop files according the freedesktop.org specifications: https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#recognized-keys

options:
  source:
    description: when provided, input desktop file will be used as template and arguments provided will override the template
    required: no
  target:
    description: command (freedesktop_Type is Application) or URL (freedesktop_Type is Link) to the target
    required: yes
  location:
    description: path of the output desktop file
    required: yes
  head:
    description: header to be copied from template / updated to location Desktop Entry by default. Do not put [] brackets.
    required: no
  freedesktop_Version:
    description: Version argument (see freedesktop specifications)
    required: no
  freedesktop_Name:
    description: Name argument. Name[en_US] and Name[<your local>] will be also filled with the same value. (see freedesktop specifications)
    required: no
  freedesktop_GenericName:
    description: GenericName argument (see freedesktop specifications)
    required: no
  freedesktop_NoDisplay:
    description: NoDisplay argument (see freedesktop specifications)
    required: no
  freedesktop_Comment:
    description: Comment argument (see freedesktop specifications)
    required: no
  freedesktop_Icon:
    description: Icon argument. If not precised, path will be taken from the binary (freedesktop_Type is Application) or favicon (freedesktop_Type is Link) or freedesktop_Name otherwise (see freedesktop specifications)
    required: no
  freedesktop_OnlyShowIn:
    description: OnlyShowIn argument (see freedesktop specifications)
    required: no
  freedesktop_NotShowIn:
    description: NotShowIn argument (see freedesktop specifications)
    required: no
  freedesktop_DBusActivatable:
    description: DBusActivatable argument (see freedesktop specifications)
    required: no
  freedesktop_TryExec:
    description: TryExec argument. If not precised and freedesktop_Type is Application, it will be taken from the path of freedesktop_Name otherwise (see freedesktop specifications)
    required: no
  freedesktop_Path:
    description: Path argument. If not precised and freedesktop_Type is Application, it will be taken from the dir of freedesktop_Name otherwise (see freedesktop specifications)
    required: no
  freedesktop_Terminal:
    description: Terminal argument (see freedesktop specifications)
    required: no
  freedesktop_Actions:
    description: Actions argument (see freedesktop specifications)
    required: no
  freedesktop_MimeType:
    description: MimeType argument (see freedesktop specifications)
    required: no
  freedesktop_Categories:
    description: Categories argument (see freedesktop specifications)
    required: no
  freedesktop_Implements:
    description: Implements argument (see freedesktop specifications)
    required: no
  freedesktop_Keywords:
    description: Keywords argument (see freedesktop specifications)
    required: no
  freedesktop_StartupNotify:
    description: StartupNotify argument (see freedesktop specifications)
    required: no
  freedesktop_StartupWMClass:
    description: StartupWMClass argument (see freedesktop specifications)
    required: no
  freedesktop_PrefersNonDefaultGPU:
    description: PrefersNonDefaultGPU argument (see freedesktop specifications)
    required: no

'''

EXAMPLES = '''
  - name: "Creating VLC application shortcut"
    desktop_launchers:
      target: "/usr/bin/vlc --started-from-file %U"
      location: "$HOME/Desktop/vlc.desktop"
    register: testout

  - name: "Creating GitHub URL shortcut"
    desktop_launchers:
      target: "https://github.com/JayBeeDe/"
      location: "$HOME/Desktop/JayBeeDe.desktop"
      freedesktop_Type: "Link"
    register: testout
'''

RETURN = '''
results:
  description: return the dict describing the created desktop file
'''


def resolvePath(path, partialResolve=False):
    # this function will convert language dependant path to resolved paths, and if partialResolve flag enabled, will then try to replace by env variable such as $HOME, etc.
    xdg_resolvable = ["$DIRECTORY_DESKTOP", "$DIRECTORY_DOCUMENTS", "$DIRECTORY_DOWNLOAD", "$DIRECTORY_MUSIC", "$DIRECTORY_PICTURES", "$DIRECTORY_PUBLIC_SHARE", "$DIRECTORY_TEMPLATES", "$DIRECTORY_VIDEOS", "$N_DIRECTORIES"]
    for item in xdg_resolvable:
        if item in path:
            newItem = re.sub(r"^\$", "", item)
            try:
                resolvedItem = GLib.get_user_special_dir(eval("GLib.UserDirectory." + newItem))
                path = re.sub("\$" + newItem, resolvedItem, path)
            except Exception:
                pass
    # resolve system language dependant folders
    path = os.path.expandvars(path)
    # resolve environment variables as well
    if partialResolve:
        for k, v in sorted(os.environ.items(), key=lambda item: item[1]):
            if re.search(r"^\/.*$", v):
                if v in path:
                    path = re.sub(v, "$" + k, path)
                    # return k + " " + v + " " + path
        # replace all resolved value by env variables when possible
    return path


def main():
    module = AnsibleModule(
        argument_spec=dict(
            source=dict(required=False, type="str"),
            target=dict(required=True, type="str"),
            location=dict(required=True, type="str"),
            head=dict(required=False, type="str", default="Desktop Entry"),

            freedesktop_Type=dict(required=False, type="str", default="Application", choices=["Application", "Link"]),
            freedesktop_Version=dict(required=False, type="float", default=1.0),
            freedesktop_Name=dict(required=False, type="str"),
            freedesktop_GenericName=dict(required=False, type="str"),
            freedesktop_NoDisplay=dict(required=False, type="bool", default=False),
            freedesktop_Comment=dict(required=False, type="str"),
            freedesktop_Icon=dict(required=False, type="str"),
            freedesktop_OnlyShowIn=dict(required=False, type="str"),
            freedesktop_NotShowIn=dict(required=False, type="str"),
            freedesktop_DBusActivatable=dict(required=False, type="bool", default=False),
            freedesktop_TryExec=dict(required=False, type="str"),
            freedesktop_Path=dict(required=False, type="str"),
            freedesktop_Terminal=dict(required=False, type="bool", default=False),
            freedesktop_Actions=dict(required=False, type="str"),
            freedesktop_MimeType=dict(required=False, type="str"),
            freedesktop_Categories=dict(required=False, type="str"),
            freedesktop_Implements=dict(required=False, type="str"),
            freedesktop_Keywords=dict(required=False, type="str"),
            freedesktop_StartupNotify=dict(required=False, type="bool", default=True),
            freedesktop_StartupWMClass=dict(required=False, type="str"),
            freedesktop_PrefersNonDefaultGPU=dict(required=False, type="bool"),
        )
    )

    desktop = defaultdict(dict)
    source = module.params.get("source")
    if source is not None:
        source = resolvePath(source)
    target = resolvePath(module.params.get("target"), partialResolve=True)
    # target = module.params.get("target")
    location = resolvePath(str(module.params.get("location")))
    head = module.params.get("head")
    newDir = None
    newPath = None

    if re.search(r"^http(s?):\/\/(www\.)?(.*)\.(.*)$", target):
        desktop["Type"] == "Link"
    else:
        desktop["Type"] == "Application"

    cursorFlag = False
    if source is not None and os.path.isfile(source):
        f = open(source, "r")
        for line in f:
            lineShk = re.sub(r"\n$", "", line)
            if re.search(r"^\[" + head + "\]$", lineShk):
                cursorFlag = True
            elif re.search(r"^\S*=.*$", lineShk) and cursorFlag:
                k = re.compile(r"^(\S+) *=(.*)$").match(lineShk).groups()[0]
                v = re.compile(r"^(\S+) *=(.*)$").match(lineShk).groups()[1]
                desktop[k] = v
            else:
                if cursorFlag and not re.search(r"^ *$", lineShk):
                    cursorFlag = False
        # read data from template
        f.close()

    for k, v in module.params.items():
        if v is not None:
            if re.search(r"^freedesktop_.*", k):
                newKey = re.compile(r"^(freedesktop_)(.*)$").match(k).groups()[1]
                desktop[newKey] = v
                # override template or just add parameters

    if desktop["Type"] == "Link":
        desktop["URL"] = target
    else:
        print(target)
        desktop["Exec"] = target

    if desktop["Type"] == "Link":
        target = re.sub(r"\/*$", "", target)
        newName = re.sub(r"\.", " ", re.sub(r"\.\S+$", "", target.split("/")[-1])).title()
    else:
        if re.search(r"^\/.*", target):
            # "/usr/bin/vlc --started-from-file %U"s
            newName = os.path.basename(re.compile(r"^((\/\S*)+) .*$").match(target).groups()[0])
        elif re.search(r"^(\S+) .*$", target):
            newName = re.compile(r"^(\S+) .*$").match(target).groups()[0]
        else:
            newName = target
    if "Name" not in desktop:
        desktop["Name"] = newName
    desktop["Name[en_US]"] = desktop["Name"]
    syslocale = locale.getdefaultlocale()[0]
    if syslocale != "en_US":
        desktop["Name[" + syslocale + "]"] = desktop["Name"]

    iconIsURL = False
    if "Icon" not in desktop and desktop["Type"] == "Link":
        iconIsURL = True
    if "Icon" in desktop and desktop["Type"] == "Application":
        if re.search(r"^http(s?):\/\/(www\.)?(.*)\.(.*)$", desktop["Icon"]):
            iconIsURL = True
    webBody = None
    iconData = None
    if iconIsURL:
        if os.path.isdir("/usr/share/icons/ansible/"):
            iconDir = "/usr/share/icons/ansible/"
        else:
            try:
                os.makedirs("/usr/share/icons/ansible/")
                os.chmod("/usr/share/icons/ansible/", 0o755)
                iconDir = "/usr/share/icons/ansible/"
            except Exception:
                if not os.path.isdir(os.environ["HOME"] + "/.local/share/icons/ansible/"):
                    os.makedirs(os.environ["HOME"] + "/.local/share/icons/ansible/")
                    os.chmod(os.environ["HOME"] + "/.local/share/icons/ansible/", 0o755)
                iconDir = os.environ["HOME"] + "/.local/share/icons/ansible/"
        try:
            webBody = open_url(desktop["URL"], method="GET", validate_certs=False).read()
        except Exception:
            webBody = None
        if webBody is not None:
            if re.search("<link rel=\\\"icon\\\" ", webBody):
                matchs = re.compile(r"^.*<link rel=\"icon\" .*href=\"(\S+)\".*\/>$", re.MULTILINE)
                iconURLs = []
                for match in matchs.finditer(webBody):
                    iconURLs.append(match.groups()[0])
                iconURLs = sorted(iconURLs, reverse=True)
                # we take the biggest image (trust alphabetic order !!) first
                iconData = None
                for iconURL in iconURLs:
                    if not re.search(r"^http(s?):\/\/(www\.)?(.*)\.(.*)$", iconURL):
                        iconURL = desktop["URL"] + iconURL
                    # module.exit_json(changed=False, results=iconURL)
                    iconPath = iconDir + desktop["Name"] + re.compile(r"^.*(\.\S+)$").match(iconURL).groups()[0]
                    try:
                        iconData = open_url(iconURL, method="GET", validate_certs=False).read()
                        with open(iconPath, "wb") as image:
                            image.write(iconData)
                        os.chmod(iconPath, 0o755)
                        break
                    except Exception:
                        iconData = None
        if iconData is not None:
            desktop["Icon"] = iconPath
    if not "Icon" in desktop and (webBody is None or iconData is None or not iconIsURL):
        iconTheme = Gtk.IconTheme.get_default()
        icon = iconTheme.lookup_icon(desktop["Name"], 48, 0)
        if icon:
            desktop["Icon"] = icon.get_filename()
        else:
            desktop["Icon"] = desktop["Name"]

    if desktop["Type"] == "Application":
        if re.search(r"^\/.*", target):
            newDir = os.path.dirname(re.compile(r"^((\/\S*)+) .*$").match(target).groups()[0])
        if newDir is not None:
            newPath = newDir + "/" + desktop["Name"].lower()
        else:
            newPath = desktop["Name"].lower()
        if "Path" not in desktop and newDir is not None:
            desktop["Path"] = newDir
        # if "TryExec" not in desktop:
        #     desktop["TryExec"] = newPath

    if re.search(r"^.*\/$", location):
        location = location + desktop["Name"] + ".desktop"
    else:
        if not re.search(r"^.*\.desktop$", location):
            location = location + ".desktop"

    odesktop = collections.OrderedDict(sorted(desktop.items()))
    from pprint import pprint as pprint
    pprint(odesktop)

    hasChanged = False
    cnt = 0
    newLines = []
    if os.path.exists(location):
        f = open(location, "r")
        for line in f.readlines():
            lineShk = re.sub(r"\n$", "", line)
            if re.search(r"^\[" + head + "\]$", lineShk):
                cursorFlag = True
            elif re.search(r"^\S+ *=.*$", lineShk) and cursorFlag:
                k = re.compile(r"^(\S+) *=(.*)$").match(lineShk).groups()[0]
                v = re.compile(r"^(\S+) *=(.*)$").match(lineShk).groups()[1]
                if k in odesktop:
                    if str(v).lower() in ["true", "false"]:
                        if str(odesktop[k]).lower() != str(v).lower():
                            hasChanged = True
                    else:
                        if str(odesktop[k]) != str(v):
                            hasChanged = True
                else:
                    hasChanged = True
                cnt = cnt + 1
            else:
                if cursorFlag and not re.search(r"^ *$", lineShk):
                    cursorFlag = False
                if not re.search(r"^ *$", lineShk):
                    newLines.append(lineShk)
        f.close()
        if cnt != len(odesktop):
            hasChanged = True
        # read data from exiting file to check if content is the same
        if hasChanged:
            f = open(location, "w+")
            for newLine in newLines:
                f.write(newLine + "\n")
            f.close()
            # remove section containing old data: everything will be appended later
    else:
        hasChanged = True

    if not os.path.isdir(os.path.dirname(location)):
        os.makedirs(os.path.dirname(location))
        os.chmod(os.path.dirname(location), 0o755)

    if hasChanged:
        with open(location, "a") as f:
            f.write("[" + head + "]\n")
            for k, v in odesktop.items():
                if isinstance(v, bool):
                    f.write(k + "=" + str(v).lower() + "\n")
                else:
                    f.write(k + "=" + str(v) + "\n")
        os.chmod(location, 0o755)

    module.exit_json(changed=hasChanged, ansible_module_results=odesktop)


if __name__ == "__main__":
    main()
