#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
import traceback

from collections import defaultdict
from ansible.module_utils.basic import AnsibleModule, missing_required_lib
from ansible.module_utils._text import to_native
from pprint import pprint
import collections

sys.path.append("/usr/lib/python3/dist-packages/ansible/modules/system")
# TODO to be improved

from dconf import DconfPreference, DBusWrapper
import syslog
from ansible.module_utils.basic import AnsibleModule

DOCUMENTATION = '''
---
module: keyboard_shortcuts
author: JayBee
version_added: "2.0.0"
short_description: Create keyboard sortcuts on linux workstation running gnome
description: Ansible Module to create keyboard sortcuts on linux workstation running gnome

options:
  binding:
    description: Binding for the custom or builtin binding. If not provided or set to off, shortcut will be removed
    required: no
  command:
    description: Command to run when the binding is invoked (not applicable for builtin binding)
    required: no
  name:
    description: Name of the custom binding used as id here or builtin command name among: calculator (Launch calculator), control-center (Launch settings), email (Launch email client), eject (Eject), home (Home folder), media (Launch media player), next (Next track), pause (Pause playback), play (Play (or play/pause)), previous (Previous track), screensaver (Lock screen), search (Search), stop (Stop playback), volume-down (Volume down), volume-mute (Volume mute/unmute), volume-up (Volume up), volume-down-quiet (Quiet volume down), volume-mute-quiet (Quiet volume mute/unmute), volume-up-quiet (Quiet volume up), volume-down-precise (Precise volume down), volume-up-precise (Precise volume up), mic-mute (Microphone mute/unmute), www (Launch web browser), touchpad-toggle (Magnifier zoom out), touchpad-on (Switch touchpad on), touchpad-off (Switch touchpad off), playback-rewind (Skip backward in current track), playback-forward (Skip forward in current track), playback-repeat (Toggle repeat playback mode), playback-random (Toggle random playback mode), rotate-video-lock (Toggle automatic screen orientation), power (Power button), hibernate (Hibernate button), suspend (Suspend button), screen-brightness-up (Screen brightness up), screen-brightness-down (Screen brightness down), screen-brightness-cycle (Screen brightness cycle), keyboard-brightness-up (Keyboard brightness up), keyboard-brightness-down (Keyboard brightness down), keyboard-brightness-toggle (Keyboard brightness toggle), battery-status (Show battery status), rfkill (RF kill), rfkill-bluetooth (Bluetooth RF kill)
    required: yes
  dynamic:
    description: For builtin binding, set dynamic (non-static) keybinding (static by default)
    required: no
'''

EXAMPLES = '''
  - name: "Creating calculator shortcut"
    keyboard_shortcuts:
      binding: "<Super>c"
      command: calculator

  - name: "Creating Project Repo push shortcut"
    keyboard_shortcuts:
      binding: "<Primary><Alt>eacute"
      command: "/bin/bash $HOME/Documents/git/mynicescript.sh arg"
      name: "Push Projets Perso"
'''

RETURN = '''
results:
  description: return the dict describing the created shortcut
'''

builtinCommands = [
    {"name": "calculator", "description": "Launch calculator"},
    {"name": "control-center", "description": "Launch settings"},
    {"name": "email", "description": "Launch email client"},
    {"name": "eject", "description": "Eject"},
    {"name": "home", "description": "Home folder"},
    {"name": "media", "description": "Launch media player"},
    {"name": "next", "description": "Next track"},
    {"name": "pause", "description": "Pause playback"},
    {"name": "play", "description": "Play (or play/pause)"},
    {"name": "previous", "description": "Previous track"},
    {"name": "screensaver", "description": "Lock screen"},
    {"name": "search", "description": "Search"},
    {"name": "stop", "description": "Stop playback"},
    {"name": "volume-down", "description": "Volume down"},
    {"name": "volume-mute", "description": "Volume mute/unmute"},
    {"name": "volume-up", "description": "Volume up"},
    {"name": "volume-down-quiet", "description": "Quiet volume down"},
    {"name": "volume-mute-quiet", "description": "Quiet volume mute/unmute"},
    {"name": "volume-up-quiet", "description": "Quiet volume up"},
    {"name": "volume-down-precise", "description": "Precise volume down"},
    {"name": "volume-up-precise", "description": "Precise volume up"},
    {"name": "mic-mute", "description": "Microphone mute/unmute"},
    {"name": "www", "description": "Launch web browser"},
    {"name": "touchpad-toggle", "description": "Magnifier zoom out"},
    {"name": "touchpad-on", "description": "Switch touchpad on"},
    {"name": "touchpad-off", "description": "Switch touchpad off"},
    {"name": "playback-rewind", "description": "Skip backward in current track"},
    {"name": "playback-forward", "description": "Skip forward in current track"},
    {"name": "playback-repeat", "description": "Toggle repeat playback mode"},
    {"name": "playback-random", "description": "Toggle random playback mode"},
    {"name": "rotate-video-lock", "description": "Toggle automatic screen orientation"},
    {"name": "power", "description": "Power button"},
    {"name": "hibernate", "description": "Hibernate button"},
    {"name": "suspend", "description": "Suspend button"},
    {"name": "screen-brightness-up", "description": "Screen brightness up"},
    {"name": "screen-brightness-down", "description": "Screen brightness down"},
    {"name": "screen-brightness-cycle", "description": "Screen brightness cycle"},
    {"name": "keyboard-brightness-up", "description": "Keyboard brightness up"},
    {"name": "keyboard-brightness-down", "description": "Keyboard brightness down"},
    {"name": "keyboard-brightness-toggle", "description": "Keyboard brightness toggle"},
    {"name": "battery-status", "description": "Show battery status"},
    {"name": "rfkill", "description": "RF kill"},
    {"name": "rfkill-bluetooth", "description": "Bluetooth RF kill"},
    {"name": "switch-to-workspace-1", "description": "Switch to workspace 1", "schema": 1},
    {"name": "switch-to-workspace-2", "description": "Switch to workspace 2", "schema": 1},
    {"name": "switch-to-workspace-3", "description": "Switch to workspace 3", "schema": 1},
    {"name": "switch-to-workspace-4", "description": "Switch to workspace 4", "schema": 1},
    {"name": "switch-to-workspace-5", "description": "Switch to workspace 5", "schema": 1},
    {"name": "switch-to-workspace-6", "description": "Switch to workspace 6", "schema": 1},
    {"name": "switch-to-workspace-7", "description": "Switch to workspace 7", "schema": 1},
    {"name": "switch-to-workspace-8", "description": "Switch to workspace 8", "schema": 1},
    {"name": "switch-to-workspace-9", "description": "Switch to workspace 9", "schema": 1},
    {"name": "switch-to-workspace-10", "description": "Switch to workspace 10", "schema": 1},
    {"name": "switch-to-workspace-11", "description": "Switch to workspace 11", "schema": 1},
    {"name": "switch-to-workspace-12", "description": "Switch to workspace 12", "schema": 1},
    {"name": "switch-to-workspace-left", "description": "Switch to workspace left", "schema": 1},
    {"name": "switch-to-workspace-right", "description": "Switch to workspace right", "schema": 1},
    {"name": "switch-to-workspace-up", "description": "Switch to workspace above", "schema": 1},
    {"name": "switch-to-workspace-down", "description": "Switch to workspace below", "schema": 1},
    {"name": "switch-to-workspace-last", "description": "Switch to last workspace", "schema": 1},
    {"name": "switch-group", "description": "Switch windows of an application", "schema": 1},
    {"name": "switch-group-backward", "description": "Reverse switch windows of an application", "schema": 1},
    {"name": "switch-applications", "description": "Switch applications", "schema": 1},
    {"name": "switch-applications-backward", "description": "Reverse switch applications", "schema": 1},
    {"name": "switch-windows", "description": "Switch windows", "schema": 1},
    {"name": "switch-windows-backward", "description": "Reverse switch windows", "schema": 1},
    {"name": "switch-panels", "description": "Switch system controls", "schema": 1},
    {"name": "switch-panels-backward", "description": "Reverse switch system controls", "schema": 1},
    {"name": "cycle-group", "description": "Switch windows of an app directly", "schema": 1},
    {"name": "cycle-group-backward", "description": "Reverse switch windows of an app directly", "schema": 1},
    {"name": "cycle-windows", "description": "Switch windows directly", "schema": 1},
    {"name": "cycle-windows-backward", "description": "Reverse switch windows directly", "schema": 1},
    {"name": "cycle-panels", "description": "Switch system controls directly", "schema": 1},
    {"name": "cycle-panels-backward", "description": "Reverse switch system controls directly", "schema": 1},
    {"name": "show-desktop", "description": "Hide all normal windows", "schema": 1},
    {"name": "panel-main-menu", "description": "Show the activities overview", "schema": 1},
    {"name": "panel-run-dialog", "description": "Show the run command prompt", "schema": 1},
    {"name": "set-spew-mark", "description": "Don’t use", "schema": 1},
    {"name": "activate-window-menu", "description": "Activate the window menu", "schema": 1},
    {"name": "toggle-fullscreen", "description": "Toggle fullscreen mode", "schema": 1},
    {"name": "toggle-maximized", "description": "Toggle maximization state", "schema": 1},
    {"name": "toggle-above", "description": "Toggle window always appearing on top", "schema": 1},
    {"name": "maximize", "description": "Maximize window", "schema": 1},
    {"name": "unmaximize", "description": "Restore window", "schema": 1},
    {"name": "toggle-shaded", "description": "Toggle shaded state", "schema": 1},
    {"name": "minimize", "description": "Minimize window", "schema": 1},
    {"name": "close", "description": "Close window", "schema": 1},
    {"name": "begin-move", "description": "Move window", "schema": 1},
    {"name": "begin-resize", "description": "Resize window", "schema": 1},
    {"name": "toggle-on-all-workspaces", "description": "Toggle window on all workspaces or one", "schema": 1},
    {"name": "move-to-workspace-1", "description": "Move window to workspace 1", "schema": 1},
    {"name": "move-to-workspace-2", "description": "Move window to workspace 2", "schema": 1},
    {"name": "move-to-workspace-3", "description": "Move window to workspace 3", "schema": 1},
    {"name": "move-to-workspace-4", "description": "Move window to workspace 4", "schema": 1},
    {"name": "move-to-workspace-5", "description": "Move window to workspace 5", "schema": 1},
    {"name": "move-to-workspace-6", "description": "Move window to workspace 6", "schema": 1},
    {"name": "move-to-workspace-7", "description": "Move window to workspace 7", "schema": 1},
    {"name": "move-to-workspace-8", "description": "Move window to workspace 8", "schema": 1},
    {"name": "move-to-workspace-9", "description": "Move window to workspace 9", "schema": 1},
    {"name": "move-to-workspace-10", "description": "Move window to workspace 10", "schema": 1},
    {"name": "move-to-workspace-11", "description": "Move window to workspace 11", "schema": 1},
    {"name": "move-to-workspace-12", "description": "Move window to workspace 12", "schema": 1},
    {"name": "move-to-workspace-last", "description": "Move window to last workspace", "schema": 1},
    {"name": "move-to-workspace-left", "description": "Move window one workspace to the left", "schema": 1},
    {"name": "move-to-workspace-right", "description": "Move window one workspace to the right", "schema": 1},
    {"name": "move-to-workspace-up", "description": "Move window one workspace up", "schema": 1},
    {"name": "move-to-workspace-down", "description": "Move window one workspace down", "schema": 1},
    {"name": "move-to-monitor-left", "description": "Move window to the next monitor on the left", "schema": 1},
    {"name": "move-to-monitor-right", "description": "Move window to the next monitor on the right", "schema": 1},
    {"name": "move-to-monitor-up", "description": "Move window to the next monitor above", "schema": 1},
    {"name": "move-to-monitor-down", "description": "Move window to the next monitor below", "schema": 1},
    {"name": "raise-or-lower", "description": "Raise window if covered, otherwise lower it", "schema": 1},
    {"name": "raise", "description": "Raise window above other windows", "schema": 1},
    {"name": "lower", "description": "Lower window below other windows", "schema": 1},
    {"name": "maximize-vertically", "description": "Maximize window vertically", "schema": 1},
    {"name": "maximize-horizontally", "description": "Maximize window horizontally", "schema": 1},
    {"name": "move-to-corner-nw", "description": "Move window to top left corner", "schema": 1},
    {"name": "move-to-corner-ne", "description": "Move window to top right corner", "schema": 1},
    {"name": "move-to-corner-sw", "description": "Move window to bottom left corner", "schema": 1},
    {"name": "move-to-corner-se", "description": "Move window to bottom right corner", "schema": 1},
    {"name": "move-to-side-n", "description": "Move window to top edge of screen", "schema": 1},
    {"name": "move-to-side-s", "description": "Move window to bottom edge of screen", "schema": 1},
    {"name": "move-to-side-e", "description": "Move window to right side of screen", "schema": 1},
    {"name": "move-to-side-w", "description": "Move window to left side of screen", "schema": 1},
    {"name": "move-to-center", "description": "Move window to center of screen", "schema": 1},
    {"name": "switch-input-source", "description": "Switch input source", "schema": 1},
    {"name": "switch-input-source-backward", "description": "Switch input source backward", "schema": 1},
    {"name": "always-on-top", "description": "Toggle window to be always on top", "schema": 1}
]


def xstr(s):
    if s is None:
        return "''"
    return "'" + s + "'"


def axstr(ss):
    if ss is None:
        return "[" + xstr(None) + "]"
    if len(ss) == 0:
        return "[" + xstr(None) + "]"
    if not isinstance(ss, list):
        return "[" + xstr(ss) + "]"
    out = "["
    for s in ss[:-1]:
        out += xstr(s) + ", "
    out += xstr(ss[-1]) + "]"
    return out


def main():
    module = AnsibleModule(
        argument_spec=dict(
            binding=dict(required=False, type="str", default="off"),
            command=dict(required=False, type="str", default="/bin/false"),
            name=dict(required=True, type="str"),
            dynamic=dict(required=False, type="bool", default=False),
        )
    )
    module.log(msg="some_message")

    shortcut = defaultdict(dict)

    binding = module.params.get("binding")
    command = module.params.get("command")
    name = module.params.get("name")
    dynamic = module.params.get("dynamic")
    builtin = False
    builtinIndexSchema = None
    for item in builtinCommands:
        if item["name"] == name:
            builtin = True
            if "schema" in item:
                builtinIndexSchema = item["schema"]
            break
    if binding is not None:
        if binding == "off" or binding == "disabled" or binding == "null":
            binding = None

    dconf = DconfPreference(module, module.check_mode)

    prefixDconfCustomPath = "/org/gnome/settings-daemon/plugins/media-keys/"
    suffixDconfCustomRootPath = "custom-keybindings"
    suffixDconfCustomPath = suffixDconfCustomRootPath + "/custom"
    prefixDconfBuiltinAlternatePaths = ["/org/gnome/desktop/wm/keybindings/", "/org/gnome/shell/keybindings/"]
    if builtinIndexSchema is None:
        prefixDconfBuiltinPath = prefixDconfCustomPath
    else:
        prefixDconfBuiltinPath = prefixDconfBuiltinAlternatePaths[builtinIndexSchema - 1]
    indexCustom = 0
    if builtin:
        if dynamic:
            revStaticName = name + "-static"
        else:
            revStaticName = name
            name = name + "-static"
        old_binding_revStatic = dconf.read(prefixDconfBuiltinPath + revStaticName)
        old_binding = dconf.read(prefixDconfBuiltinPath + name)
    else:
        cursorIndex = 1
        cursorName = dconf.read(prefixDconfCustomPath + suffixDconfCustomPath + str(cursorIndex) + "/name")
        old_name = xstr(None)
        while cursorName is not None:
            # we fetch all keys to get the last one, just in case there are multiple (shall not be)
            if cursorName == xstr(name):
                indexCustom = cursorIndex
                old_name = xstr(name)
            cursorIndex = cursorIndex + 1
            cursorName = dconf.read(prefixDconfCustomPath + suffixDconfCustomPath + str(cursorIndex) + "/name")
        if indexCustom == 0:
            indexCustom = cursorIndex
            # we will create the custom shortcut entry at the end of the list
        old_binding = dconf.read(prefixDconfCustomPath + suffixDconfCustomPath + str(indexCustom) + "/binding")
        old_command = dconf.read(prefixDconfCustomPath + suffixDconfCustomPath + str(indexCustom) + "/command")
        try:
            customKeyBindingsList = dconf.read(prefixDconfCustomPath + suffixDconfCustomRootPath).strip("'][").split("', '")
        except:
            customKeyBindingsList = []

    hasChanged = False
    if builtin:
        if binding is None:
            if old_binding is not None:
                hasChanged = True
                dconf.reset(prefixDconfBuiltinPath + name)
        else:
            if old_binding_revStatic is not None:
                # we need to remove the non static shortcut
                hasChanged = True
                dconf.reset(prefixDconfBuiltinPath + revStaticName)
            if old_binding != axstr(binding):
                hasChanged = True
                dconf.write(prefixDconfBuiltinPath + name, axstr(binding))
    else:
        if binding is None:
            if prefixDconfCustomPath + suffixDconfCustomPath + str(indexCustom) + "/" in customKeyBindingsList:
                hasChanged = True
                customKeyBindingsList.remove(str(prefixDconfCustomPath + suffixDconfCustomPath + str(indexCustom) + "/"))
                dconf.write(prefixDconfCustomPath + suffixDconfCustomRootPath, axstr(customKeyBindingsList))
                # we have found a indexCustom so we are sure that there is equivalence with existance of custom + indexCustom key
                dconf.reset(prefixDconfCustomPath + suffixDconfCustomPath + str(indexCustom) + "/name")
                dconf.reset(prefixDconfCustomPath + suffixDconfCustomPath + str(indexCustom) + "/binding")
                dconf.reset(prefixDconfCustomPath + suffixDconfCustomPath + str(indexCustom) + "/command")
        else:
            if prefixDconfCustomPath + suffixDconfCustomPath + str(indexCustom) + "/" not in customKeyBindingsList:
                hasChanged = True
                customKeyBindingsList.append(str(prefixDconfCustomPath + suffixDconfCustomPath + str(indexCustom) + "/"))
                dconf.write(prefixDconfCustomPath + suffixDconfCustomRootPath, axstr(customKeyBindingsList))
            if old_name != xstr(name):
                hasChanged = True
                dconf.write(prefixDconfCustomPath + suffixDconfCustomPath + str(indexCustom) + "/name", xstr(name))
            if old_binding != xstr(binding):
                hasChanged = True
                dconf.write(prefixDconfCustomPath + suffixDconfCustomPath + str(indexCustom) + "/binding", xstr(binding))
            if old_command != xstr(command):
                hasChanged = True
                dconf.write(prefixDconfCustomPath + suffixDconfCustomPath + str(indexCustom) + "/command", xstr(command))

    msg = "Nothing has changed"
    if hasChanged:
        if builtin:
            msg = "Builtin command " + name + " has been "
        else:
            msg = "Command Name " + name + " (command is " + command + ") has been "
        if binding is None:
            msg += "removed from keyboard shortcuts"
        else:
            msg += "added or altered to keyboard shortcuts"

    module.exit_json(changed=hasChanged, ansible_module_results=msg)


if __name__ == "__main__":
    main()
