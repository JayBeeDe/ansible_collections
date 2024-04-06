#!/bin/bash

# @title: windows connect script
# @author: JayBeeDe, https://github.com/JayBeeDe/ansible_collections
# @date: 13/06/2021
# @version: 0.2
# @description: this script can be used as launcher for windows VM connection over RDP

#########################global variable
if [[ $BASH_SOURCE != $0 ]]; then
    echo -e "\e[31mThe script must be runned with sh command: no source or dot!\e[0m"
    return 1
fi
abs_path=$(readlink -f "$0")
abs_dir=$(dirname "$abs_path")
rel_dir=$(pwd)
logFile="connectWindows.log"
conf_VMTimeout=50

#########################processing arguments

if [ -n "$1" ]; then
	re='\.remmina$'
	if [[ $1 =~ $re ]]; then
		if [ -f "$abs_dir/$1" ]; then
			filePath="$abs_dir/$1"
		elif [ -f "$rel_dir/$1" ]; then
			filePath="$rel_dir/$1"
		elif [ -f "$1" ]; then
			filePath="$1"
		else
		    echo -e "\e[31mYou must precise an absolute path or relative path to the remmina file!\e[0m"
	        exit 1
		fi
	else
	    echo -e "\e[31mThe extension must be .remmina for the remmina file!\e[0m"
	    exit 1
	fi
else
	echo -e "\e[31mPlease specify a remmina file\e[0m"
	exit 1
fi

#########################functions

function waitNetworkToBeUp() {
	ip=$1
	i=0
	flagError=1
	while [ $i -lt $conf_VMTimeout ]
	do
	 	sleep 1
		set +e
		ping -c 1 -w 2 -i 1 $ip 2>&1 >/dev/null
		res=$?
		set -e
		if [ $res == 0 ]; then
			flagError=0
			echo 0
			break 2
		fi
		i=$((i+1))
	done
	if [ "$flagError" != 0 ]; then
		echo 1
	fi
}

#########################main script

ip=$(cat $filePath | grep -P "^server=" | sed -r "s/^server=(.*):[0-9]+$/\1/g")
echo -e "\e[32mConnecting to target $ip...\e[0m"

vmState=$(virsh list --state-running --name | grep $ip)
if [ "$vmState" != "$ip" ]; then
    fnret=$(virsh start $ip)
fi

fnret=$(waitNetworkToBeUp "$ip")
if [ "$fnret" == "1" ]; then
    echo -e "\e[31mTarget machine ${ip} not reachable!\e[0m"
    exit 1
fi

remmina -c "$filePath" 2>&1 >/dev/null
