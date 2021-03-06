from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

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
