from __future__ import (absolute_import, division, print_function)
__metaclass__ = type


def groups2str(dictInput, user="root"):
    out = ""
    if isinstance(dictInput, list):
        for group in dictInput:
            if user in group["value"] and group["key"] != user:
                if out != "":
                    out += ","
                out += group["key"]
    return out


class FilterModule(object):

    def filters(self):
        return {
            "groups2str": groups2str
        }
