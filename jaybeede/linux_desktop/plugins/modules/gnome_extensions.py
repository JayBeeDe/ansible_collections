#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import shutil
import subprocess
import tempfile
import hashlib
import urllib.parse
from urllib.parse import quote
import uuid
import sys
import locale
import re
from collections import defaultdict
from ansible.module_utils.basic import AnsibleModule
from ansible.errors import AnsibleError
from ansible.module_utils.urls import open_url
import collections
import json
import pdb

sys.path.append("/usr/lib/python3/dist-packages/ansible/modules/files")
sys.path.append("/usr/lib/python3/dist-packages/ansible/modules/system")
# TODO to be improved

from unarchive import ZipArchive
from dconf import DconfPreference, DBusWrapper

DOCUMENTATION = '''
---
module: gnome_extensions
author: JayBee
version_added: "2.0.0"
short_description: Manage gnome extensions
description: Ansible Module to manage (install, update, uninstall, enable, disable) gnome extensions. Gnome extensions can be downloaded from official community website, from the GitHub extension repo, or directly from a custom private or public URL. When run as root, gnome extension will be system wide otherwise will be user wide installed.

options:
  url:
    description: GitHub or public GitLab extension repo URL or custom URL pointing at the archive containing the extension. Note that extension uuid can also be precised instead if extension is already installed on the target system.
    required: yes
  action:
    description: install, enable (install if not already installed, default value), disable, uninstall (disable then uninstall)
    required: no
  version:
    description: specific version to be installed, no updates if provided. If provided, updates will not be installed. Please also ensure the version is supported by your gnome shell version. By default, if not provided the latest version supported by your gnome shell will be downloaded. Option not supported (ignored) when a custom URL is provided and/or action is disable or uninstall
    required: no
  force:
    description: force extension to be installed even if written as not compatible with your gnome version
    required: no
  tokenGithub:
    description: personal GitHub token. If provided, in case GitHub repo URL is provided, calls to GitHub API will be limited to 1000 per hour instead of 60 per hour
    required: no
  tokenGitlab:
    description: personal GitLab token. If provided, in case GitLab repo URL is provided, calls to GitLab API will be limited to 2000 per minute instead of 500 per minute (tokenGitlab might never be necessary in this ansible module)
    required: no
'''

EXAMPLES = '''

Basic example, module will try to download the latest version that is compatible with your gnome-shell version:

  - name: "Installing latest dash-to-panel from official community website extensions.gnome.org..."
    gnome_extensions:
      url: "https://github.com/home-sweet-gnome/dash-to-panel"
    notify: "Reload gnome"

The 2 following tasks are equivalent:

  - name: "Installing dash-to-panel from GitHub official repo..."
    gnome_extensions:
      url: "https://github.com/home-sweet-gnome/dash-to-panel"
      version: 40
    notify: "Reload gnome"

  - name: "Installing dash-to-panel fom custom URL (is GitHub public repo here, but it can be anything that point out to the zip file)..."
    gnome_extensions:
      url: "https://github.com/home-sweet-gnome/dash-to-panel/releases/download/v40/dash-to-panel@jderose9.github.com_v40.zip"
    notify: "Reload gnome"

Other example:

  - name: "Disabling Bing Wallpaper extension..."
    gnome_extensions:
      url: "https://github.com/home-sweet-gnome/dash-to-panel"
      action: disable
    notify: "Reload gnome"

  - name: "Disabling Bing Wallpaper extension..."
    gnome_extensions:
      url: "BingWallpaper@ineffable-gmail.com"
      action: disable
    notify: "Reload gnome"

Handler required:

  - name: "Reload gnome"
    command: killall -1 gnome-shell

'''

RETURN = '''
results:
  description: return the dict describing the created desktop file
'''

extensionSystemWideBasePath = "/usr/share/gnome-shell/extensions"
extensionUserWideBasePath = os.environ["HOME"] + "/.local/share/gnome-shell/extensions"
extensionEnabledDconfPath = "/org/gnome/shell/enabled-extensions"
extensionDisabledDconfPath = "/org/gnome/shell/disabled-extensions"


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


def repo2url(url, version=0, token=None):
    if getUrlSourceType(url) == "github" or getUrlSourceType(url) == "gitlab":
        headers = {}
        namespace = urllib.parse.urlparse(url).path.split("/")[1:][0]
        repo = urllib.parse.urlparse(url).path.split("/")[1:][1]
        if getUrlSourceType(url) == "github":
            if token is not None:
                headers = {"Authorization": "token " + token}
            apiUrl = "https://api.github.com/repos/" + namespace + "/" + repo + "/releases"
            # https://github.com/home-sweet-gnome/dash-to-panel
            # https://api.github.com/repos/home-sweet-gnome/dash-to-panel/releases/latest don't use latest to be more consistent with others
            # zipball_url
            releases = json.loads(open_url(apiUrl, method="GET", validate_certs=False, headers=headers).read())
            if len(releases) > 0:
                versionKey = "tag_name"
            else:
                versionKey = "name"
                apiUrl = "https://api.github.com/repos/" + namespace + "/" + repo + "/tags"
                # https://github.com/kgaut/gnome-shell-audio-output-switcher
                # https://api.github.com/repos/kgaut/gnome-shell-audio-output-switcher/tags if not working
                releases = json.loads(open_url(apiUrl, method="GET", validate_certs=False, headers=headers).read())
            if version <= 0:
                if len(releases) <= abs(int(version)):
                    return None
                else:
                    if "assets" in releases[abs(int(version))]:
                        if len(releases[abs(int(version))]["assets"]) > 0:
                            return releases[abs(int(version))]["assets"][0]["browser_download_url"]
                    return releases[abs(int(version))]["zipball_url"]
            else:
                for release in releases:
                    if version == tag2version(release[versionKey]):
                        if "assets" in release:
                            if len(release["assets"]) > 0:
                                return release["assets"][0]["browser_download_url"]
                        return release["zipball_url"]

        elif getUrlSourceType(url) == "gitlab":
            if token is not None:
                headers = {"PRIVATE-TOKEN": token}
            apiUrl = "https://gitlab.com/api/v4/projects/" + quote(namespace + "/" + repo, safe="") + "/releases"
            # https://gitlab.com/arcmenu-team/Arc-Menu
            # https://gitlab.com/api/v4/projects/arcmenu%2FArcMenu/releases
            releases = json.loads(open_url(apiUrl, method="GET", validate_certs=False, headers=headers).read())
            if version <= 0:
                if len(releases) <= abs(int(version)):
                    return None
                foundFlag = True
                release = releases[abs(int(version))]
            else:
                foundFlag = False
                for release in releases:
                    if version == tag2version(release["tag_name"]):
                        foundFlag = True
                        break
            if release is not None and foundFlag:
                for source in release["assets"]["sources"]:
                    if source["format"] == "zip":
                        return source["url"]
        raise AnsibleError("Could not get the zip URL from " + getUrlSourceType(url) + " repo " + url + " (API URL is " + apiUrl + ") " + str(version) + " " + getUrlSourceType(url))
    return url


def url2uuid(module, url, token=None):
    if getUrlSourceType(url) == "uuid":
        return url
    tmpPath = downloadExtension(module, repo2url(url, 0, token))
    extensionMetadataFileJson = getFileMetadata(tmpPath + "/metadata.json")
    return extensionMetadataFileJson["uuid"]


def tag2version(version):
    fnret = re.compile(r"^\D*((\d+)([\.,-_]\d+)?).*").match(version)
    if fnret is not None:
        version = re.sub(r"(,|-|_)", ".", fnret.groups()[0])
    return float(version)


def getUrlSourceType(url):
    # this function will parse the url to get the source type: uuid, github, gitlab or custom url
    if re.search(r"^http(s?):\/\/(www\.)?(.*)\.(.*)$", url):
        # we have an url
        if re.search(r"^(.*)\.zip$", urllib.parse.urlparse(url).path):
            return "custom"
        if re.search(r"^(www\.)?github\.com$", urllib.parse.urlparse(url).netloc) and re.search(r"^(\/.+){2}(.*)$", urllib.parse.urlparse(url).path):
            return "github"
        if re.search(r"^(www\.)?gitlab\.com$", urllib.parse.urlparse(url).netloc) and re.search(r"^(\/.+){2}(.*)$", urllib.parse.urlparse(url).path):
            return "gitlab"
        else:
            raise AnsibleError("URL provided must be either extension UUID, github repo URL, public gitlab repo URL or custom URL to the zip file")
    else:
        return "uuid"


def runCmd(cmd, errorMsg="Error while running CMD command"):
    cmdArr = cmd.split(" ")
    realErrorMsg = re.sub("CMD", cmdArr[0], errorMsg)
    realErrorMsg = re.sub("ARG", " ".join(cmdArr[1:]), realErrorMsg)
    try:
        subprocess.check_output(["gnome-shell", "--version"])
    except:
        raise AnsibleError(realErrorMsg)
    fnret = subprocess.getoutput(cmd)
    return fnret


def getGnomeShellVersion():
    fnret = runCmd("gnome-shell --version", "CMD command failed. You might need to install CMD as you want to install a gnome shell extension!")
    version = re.compile(r"^GNOME Shell (.*)").match(fnret).groups()[0]
    return tag2version(version)


def getFileMetadata(path):
    with open(path) as extensionMetadataFile:
        extensionMetadataFileJson = json.loads(extensionMetadataFile.read())
    return extensionMetadataFileJson


def getLocalExtensionMetadata(uuid, raiseFlag=True):
    for baseDir in extensionSystemWideBasePath, extensionUserWideBasePath:
        if os.path.isdir(baseDir):
            for extensionDir in os.listdir(baseDir):
                if os.path.isdir(baseDir + "/" + extensionDir):
                    extensionMetadataFilePath = baseDir + "/" + extensionDir + "/metadata.json"
                    if os.path.isfile(extensionMetadataFilePath):
                        extensionMetadataFileJson = getFileMetadata(extensionMetadataFilePath)
                        if extensionMetadataFileJson["uuid"] == uuid:
                            extensionMetadataFileJson["directory"] = baseDir + "/" + extensionDir
                            return extensionMetadataFileJson
    if raiseFlag:
        raise AnsibleError("gnome-shell extension " + uuid + " is neither installed for the system nor for the user")
    else:
        return None


def checkLocalExtensionInstalled(uuid):
    if getLocalExtensionMetadata(uuid, raiseFlag=False) is None:
        return None
    else:
        fnret = re.compile(r"^" + extensionSystemWideBasePath).match(getLocalExtensionMetadata(uuid, raiseFlag=False)["directory"])
        fnret2 = re.compile(r"^" + extensionUserWideBasePath).match(getLocalExtensionMetadata(uuid, raiseFlag=False)["directory"])
        if fnret is not None:
            return "system"
        elif fnret2 is not None:
            return "user"
        else:
            return "otheruser"


def setLocalExtensionState(module, uuid, state="enable"):
    if checkLocalExtensionInstalled(uuid) is None:
        if state == "disable":
            return False
        else:
            raise AnsibleError("Gnome Extension " + uuid + " cannot be enabled since not installed")
    dconf = DconfPreference(module, module.check_mode)
    enabledExtensions = []
    disabledExtensions = []
    if dconf.read(extensionEnabledDconfPath) is not None:
        enabledExtensions = dconf.read(extensionEnabledDconfPath).strip("'][").split("', '")
    if dconf.read(extensionDisabledDconfPath) is not None:
        disabledExtensions = dconf.read(extensionDisabledDconfPath).strip("'][").split("', '")
    if state == "enable" and (uuid not in enabledExtensions or uuid in disabledExtensions):
        if uuid not in enabledExtensions:
            enabledExtensions.append(uuid)
        if uuid in disabledExtensions:
            disabledExtensions.remove(uuid)
    elif state == "disable" and (uuid in enabledExtensions or uuid not in disabledExtensions):
        if uuid in enabledExtensions:
            enabledExtensions.remove(uuid)
        if uuid not in disabledExtensions:
            disabledExtensions.append(uuid)
    else:
        return False
    if len(enabledExtensions) > 1 and enabledExtensions[0] == "":
        enabledExtensions.pop(0)
    if len(disabledExtensions) > 1 and disabledExtensions[0] == "":
        disabledExtensions.pop(0)
    dconf.write(extensionEnabledDconfPath, axstr(enabledExtensions))
    # dconf doesn't work anymore... ? To be troubleshooted
    dconf.write(extensionDisabledDconfPath, axstr(disabledExtensions))
    # refreshGnome()
    return True


def refreshGnome(method="dbus"):
    errorMsg = "Gnome refresh failed. Extension might not be fully reloaded"
    if method == "dbus":
        runCmd("dbus-send --type=method_call --print-reply --dest=org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Eval string:'global.reexec_self()'", errorMsg)
    else:
        runCmd("killall -1 gnome-shell", errorMsg)
    return True


def installExtension(module, url, scope="system", version=0, force=False, token=None):
    # TODO still handle no reinstall when already ok
    # TODO case with different version than can be changed (upgraded/downgraded)
    # TODO version not ok and with other privilege
    hasChanged = False
    if scope == "system":
        # root or sudo user => system wide install
        extensionBasePath = extensionSystemWideBasePath
    else:
        # user wide install
        extensionBasePath = extensionUserWideBasePath

    gsVersion = getGnomeShellVersion()

    # get latest compatible
    urlSourceType = getUrlSourceType(url)
    if urlSourceType == "uuid":
        raise AnsibleError("A gnome extension cannot be installed with an uuid: you need to provide an URL or a gitlab/github repo URL")

    foundFlag = False
    if version == 0 and (urlSourceType == "github" or urlSourceType == "gitlab"):
        downloadUrl = ""  # just to go in the while loop
        while(downloadUrl is not None):
            downloadUrl = repo2url(url, version, token)
            tmpPath = downloadExtension(module, downloadUrl)
            extensionMetadataFileJson = getFileMetadata(tmpPath + "/metadata.json")
            gsVersionCompatibilityList = extensionMetadataFileJson["shell-version"]
            uuid = extensionMetadataFileJson["uuid"]
            if checkLocalExtensionInstalled(uuid) is not None:
                if checkLocalExtensionInstalled(uuid) != scope:
                    hasChanged = uninstallExtension(module, uuid)
            for gsVersionCompatibilityItem in gsVersionCompatibilityList:
                if gsVersion == tag2version(gsVersionCompatibilityItem) or force is True:
                    foundFlag = True
                    break
            if foundFlag:
                break
            version = version - 1
        if downloadUrl is None:
            raise AnsibleError("No version found for " + uuid + " compatible with gnome shell version " + str(gsVersion) + "(only compatible with version " + ", ".join(gsVersionCompatibilityList) + ")")
    else:
        tmpPath = downloadExtension(module, repo2url(url, version, token))
        extensionMetadataFileJson = getFileMetadata(tmpPath + "/metadata.json")
        gsVersionCompatibilityList = extensionMetadataFileJson["shell-version"]
        uuid = extensionMetadataFileJson["uuid"]
        if checkLocalExtensionInstalled(uuid) is not None:
            if checkLocalExtensionInstalled(uuid) != scope:
                hasChanged = uninstallExtension(module, uuid)
        for gsVersionCompatibilityItem in gsVersionCompatibilityList:
            if gsVersion == tag2version(gsVersionCompatibilityItem) or force is True:
                foundFlag = True
                break
        if not foundFlag:
            versionMsg = ""
            if version != 0:
                versionMsg = " version " + str(version)
            raise AnsibleError("Extension " + uuid + versionMsg + " is not compatible with gnome shell version " + str(gsVersion) + " (only compatible with version " + ", ".join(gsVersionCompatibilityList) + ")")
            # error with latest version (0) raised above

    md5contentTmp = None
    md5content = None
    if os.path.isfile(tmpPath + "/md5sum.txt") and os.path.isfile(extensionBasePath + "/md5sum/" + uuid + ".txt"):
        with open(tmpPath + "/md5sum.txt", "r") as md5file:
            md5contentTmp = md5file.read()
        with open(extensionBasePath + "/md5sum/" + uuid + ".txt", "r") as md5file:
            md5content = md5file.read()
    if md5contentTmp is not None and md5content is not None:
        if md5contentTmp == md5content:
            return uuid, hasChanged
    shutil.move(tmpPath, extensionBasePath + "/" + uuid)
    if not os.path.isdir(extensionBasePath + "/md5sum"):
        os.mkdir(extensionBasePath + "/md5sum")
        os.chmod(extensionBasePath + "/md5sum", 0o777)
    if os.path.isfile(extensionBasePath + "/md5sum/" + uuid + ".txt"):
        os.remove(extensionBasePath + "/md5sum/" + uuid + ".txt")
    os.rename(extensionBasePath + "/" + uuid + "/md5sum.txt", extensionBasePath + "/md5sum/" + uuid + ".txt")
    if os.path.isdir(tempfile.gettempdir() + "/gnome_extensions"):
        try:
            shutil.rmtree(tempfile.gettempdir() + "/gnome_extensions")
        except:
            pass
    for root, dirs, files in os.walk(extensionBasePath + "/" + uuid):
        for item in dirs:
            os.chmod(os.path.join(root, item), 0o777)
        for item in files:
            os.chmod(os.path.join(root, item), 0o777)
    os.chmod(extensionBasePath + "/" + uuid, 0o777)
    return uuid, True


def file2md5(filePath):
    m = hashlib.md5()
    a_file = open(filePath, "rb")
    content = a_file.read()
    m.update(content)
    digest = m.hexdigest()
    return str(digest)


def downloadExtension(module, url):
    if os.path.isdir(tempfile.gettempdir() + "/gnome_extensions"):
        try:
            shutil.rmtree(tempfile.gettempdir() + "/gnome_extensions")
        except:
            pass
    try:
        os.mkdir(tempfile.gettempdir() + "/gnome_extensions")
        os.chmod(tempfile.gettempdir() + "/gnome_extensions", 0o777)
    except:
        pass
    tmpPath = tempfile.gettempdir() + "/gnome_extensions/" + str(uuid.uuid4())
    extensionData = open_url(url, method="GET", validate_certs=False).read()
    with open(tmpPath + ".zip", "wb") as extension:
        extension.write(extensionData)
    os.chmod(tmpPath + ".zip", 0o755)
    md5Archive = file2md5(tmpPath + ".zip")
    os.mkdir(tmpPath)
    os.chmod(tmpPath, 0o755)

    # workaround: patch current ansible module object to make extract working
    ZipFakeModule = module
    zipFakeModuleArgument_spec = ZipFakeModule.argument_spec
    zipFakeModuleParams = ZipFakeModule.params
    zipFakeModuleArgument_spec["extra_opts"] = dict(type='list', default=[])
    zipFakeModuleParams["extra_opts"] = []
    zipFakeModuleArgument_spec["exclude"] = dict(type='list', default=[])
    zipFakeModuleParams["exclude"] = []
    zipFakeModuleParams["remote_src"] = True
    setattr(ZipFakeModule, "argument_spec", zipFakeModuleArgument_spec)
    setattr(ZipFakeModule, "params", zipFakeModuleParams)
    zipObj = ZipArchive(src=tmpPath + ".zip", b_dest=tmpPath, file_args=None, module=ZipFakeModule)
    zipObj.unarchive()

    if not os.path.isfile(tmpPath + "/metadata.json"):
        for root, dirs, files in os.walk(tmpPath):
            for item in files:
                if item == "metadata.json":
                    tmpPath = os.path.join(root)
                    break

    if not os.path.isfile(tmpPath + "/metadata.json"):
        raise AnsibleError("metadata.json file could not be found within the extension. Please ensure the extension package is correct")

    with open(tmpPath + "/md5sum.txt", "w") as md5file:
        md5file.write(md5Archive)
    return tmpPath


def uninstallExtension(module, uuid):
    hasChanged = False
    dconf = DconfPreference(module, module.check_mode)
    disabledExtensions = dconf.read(extensionDisabledDconfPath).strip("'][").split("', '")
    if uuid in disabledExtensions:
        disabledExtensions.remove(uuid)
        dconf.write(extensionDisabledDconfPath, axstr(disabledExtensions))
        hasChanged = True
    if checkLocalExtensionInstalled(uuid) is None:
        return hasChanged
    hasChanged = True
    extensionDirectory = getLocalExtensionMetadata(uuid, raiseFlag=False)["directory"]
    shutil.rmtree(extensionDirectory)
    if os.path.isdir(os.path.abspath(extensionDirectory + "/../md5sum")):
        if os.path.isfile(os.path.abspath(extensionDirectory + "/../md5sum/" + uuid + ".txt")):
            os.remove(os.path.abspath(extensionDirectory + "/../md5sum/" + uuid + ".txt"))
    return hasChanged


def main():
    module = AnsibleModule(
        argument_spec=dict(
            url=dict(required=True, type="str"),
            version=dict(required=False, type="float", default=0),
            scope=dict(required=False, type="str", default="system", choice=["system", "user"]),
            action=dict(required=False, type="str", default="enable", choice=["install", "enable", "disable", "uninstall"]),
            force=dict(required=False, type="bool", default=False),
            tokenGithub=dict(required=False, type="str", default=None),
            tokenGitlab=dict(required=False, type="str", default=None)
        )
    )
    # pdb.set_trace()

    url = module.params.get("url")
    version = module.params.get("version")
    scope = module.params.get("scope")
    action = module.params.get("action")
    force = module.params.get("force")
    if getUrlSourceType(url) == "github" and module.params.get("tokenGithub") is not None:
        token = module.params.get("tokenGithub")
    elif getUrlSourceType(url) == "gitlab" and module.params.get("tokenGitlab") is not None:
        token = module.params.get("tokenGitlab")
    else:
        token = None
    hasChanged = False
    hasChanged1 = False
    hasChanged2 = False
    hasChanged3 = False
    hasChanged4 = False

    if action == "install" or action == "enable":
        uuid, hasChanged1 = installExtension(module, url, scope, version, force, token)

    if action == "disable" or action == "uninstall":
        uuid = url2uuid(module, url, token)

    if action == "enable":
        hasChanged2 = setLocalExtensionState(module, uuid, state="enable")

    if action == "uninstall" or action == "disable":
        hasChanged3 = setLocalExtensionState(module, uuid, state="disable")

    if action == "uninstall":
        hasChanged4 = uninstallExtension(module, uuid)

    if hasChanged1 or hasChanged2 or hasChanged3 or hasChanged4:
        hasChanged = True

    # todo
    # extra wrapper aroung dconf object...

    module.exit_json(changed=hasChanged, ansible_module_results="lol")


if __name__ == "__main__":
    main()
