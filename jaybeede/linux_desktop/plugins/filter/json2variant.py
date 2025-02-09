from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = '''
---
filter: json2variant
author: JayBee
version_added: "2.0.0"
short_description: Convert json to variant
description: Ansible Filter that takes from pipe json content and convert it in a format that can be directly interpreted in ansible tasks such as dconf settings.

options: the json content

'''

EXAMPLES = '''

Read a json configuration file and put it in a variable to be used later in the playbook

vars:
    dashtopanel: "{{ lookup('file', '{{ role_path }}/files/dash-to-panel.json') | from_json | jaybeede.linux_desktop.json2variant }}"

'''

RETURN = '''
results:
  description: return the dict describing the json
'''

def json2variant(lstInput, deep=0):
    if isinstance(lstInput, list):
        out = "["
        for item in lstInput:
            if out != "[":
                out += ","
            out += json2variant(item, deep+1)
        out += "]"
    else:
        out = str(lstInput)
    out = out.replace(" ", "")
    out = out.replace("'", '"')
    if deep == 0:
        return str("'" + out + "'")
    else:
        return str(out)


class FilterModule(object):

    def filters(self):
        return {
            'json2variant': json2variant
        }
