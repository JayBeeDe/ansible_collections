#!/bin/bash
DIFS=$IFS
for item in $(acpitool -w | sed -r "s:^ *([0-9]+)\.\s+([A-Z0-9]+)\s+[A-Z0-9]+\s+\*(enabled|disabled).*$:\1-\2-\3:" | grep -P "^[0-9]+-[A-Z0-9]+-(enabled|disabled)$" --color=never); do
    IFS=- read -r number type status <<<$item
    if [ "$status" == "enabled" ] && [ "$type" != "PWRB" ]; then
        sudo acpitool -W $number >/dev/null
    fi
done
IFS=$DIFS
acpitool -w
