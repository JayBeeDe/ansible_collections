#!/bin/bash

#########################global variable
abs_path=$(readlink -f "$0")
script_name=$(basename "$abs_path" ".sh")
# shellcheck disable=SC2034
rel_dir=$(pwd)
# shellcheck disable=SC2034
oid=$(kdbxQuery "/others/pushbullet" password 2>/dev/null)

#########################functions

function notify() {
    msg=$1
    curl -sS -X POST -H "Access-Token: $oid" -H "Content-type: application/json" -d "{\"type\":\"note\", \"title\":\"$script_name\", \"body\":\"$msg\"}" "https://api.pushbullet.com/v2/pushes"
}

function backup() {
    database=$1
    dte=$2
    username=$(kdbxQuery "/database/${database}" username 2>/dev/null)
    password=$(kdbxQuery "/database/${database}" password 2>/dev/null)
    url=$(kdbxQuery "/database/${database}" url 2>/dev/null)
    mkdir -p "/opt/DBBackups/${database}"
    docker exec -u 0 "$database" sh -c "mysqldump --no-tablespaces -u $username -p${password} $url" >"/opt/DBBackups/${database}/${database}-${dte}.dmp"
}
function report() {
    database=$1
    dte=$2
    if [ -f "/opt/DBBackups/${database}/${database}-${dte}.dmp" ]; then
        # shellcheck disable=SC2012
        currSize=$(ls -lh "/opt/DBBackups/${database}/${database}-${dte}.dmp" | awk '{print $5}')
        currMD5=$(md5sum "/opt/DBBackups/${database}/${database}-${dte}.dmp" | awk '{print $1}')
        report="${report}\nBackup: Size ${currSize} / md5 ${currMD5}"
    else
        report="${report}\nBackup: Failed!"
    fi
}

function archive() {
    database=$1
    previousFileSize=0
    previousFileMonth=0
    rmCnt=0
    fileCnt=0
    startFileDate=""
    # shellcheck disable=SC2012
    for item in $(ls -1 "/opt/DBBackups/${database}/${database}-"*".dmp" | sort); do
        currentFileDate=$(basename "$item" | sed -r 's/^(.*)([0-9]{4}(-[0-9]{2}){2})(.*)$/\2/g')
        if [ "$startFileDate" == "" ]; then
            startFileDate=$currentFileDate
        fi
        currentFileDateStamp=$(date -d "$currentFileDate" +%s)
        currentFileSize=$(stat --printf="%s" "$item")
        currentFileMonth=$(date -d "$(date -d "$currentFileDate" '+%Y-%m-01')" +%s)
        echo "Processing archiving on file $item..."
        if [ "$currentFileDateStamp" -gt "$(date +%s)" ]; then
            echo "File ${item} is in the future !" "ERROR"
        else
            if [ "$currentFileDateStamp" -lt "$(date -d "$(date -d "-2 days" '+%Y-%m-%d')" +%s)" ]; then
                if [ "$currentFileSize" == "$previousFileSize" ]; then
                    rm -f "$item"
                    rmCnt=$(("$rmCnt" + 1))
                    echo "File ${item} has been removed due to same size."
                else
                    if [ "$currentFileDateStamp" -lt "$(date -d "$(date -d "-1 month" '+%Y-%m-%d')" +%s)" ]; then
                        if [ "$currentFileMonth" == "$previousFileMonth" ]; then
                            rm -f "$item"
                            rmCnt=$((rmCnt + 1))
                            echo "File ${item} has been removed since older that one month and not the first of the month."
                            currentFileSize=0
                        else
                            if [ "$currentFileDateStamp" -lt "$(date -d "$(date -d "-1 year" '+%Y-%m-%d')" +%s)" ]; then
                                rm -f "$item"
                                rmCnt=$((rmCnt + 1))
                                echo "File ${item} has been removed since older that one year."
                                currentFileSize=0
                            fi
                        fi
                    fi
                fi
            fi
        fi
        fileCnt=$((fileCnt + 1))
        previousFileSize=$currentFileSize
        previousFileMonth=$currentFileMonth
    done
    report="${report}\nArchived: Removed ${rmCnt}/${fileCnt} / Period ${startFileDate} => ${currentFileDate}"
}

function purgeSystem() {
    volList=""
    resCnt=$(docker volume ls -qf dangling=true | grep -Pvc vol$)
    if [ "$resCnt" -gt 0 ]; then
        for volume in $(docker volume ls -qf dangling=true | grep -Pv vol$); do
            # shellcheck disable=SC2154
            echo "Removing volume ${volume}..."
            docker volume rm "$volume"
            if [ "$volList" == "" ]; then
                volList="${volume}"
            else
                volList="${volList}, ${volume}"
            fi
        done
        notify "${resCnt} dangling docker volumes have been removed : ${volList} !"
    fi
    echo "Cleaning apt..."
    apt-get autoremove
    echo "System clean !"
}

#########################Main script
dte=$(date "+%Y-%m-%d-%H%M%S")
echo "The script dbBackup is starting (${dte})!"

report="$dte"

for database in etherpad-db virtual-desktop-db blog-db limesurvey-db; do
    report="${report}\n\n${database}"
    backup "$database" "$dte"
    report "$database" "$dte"
    archive "$database"
done

if [ -n "$report" ]; then
    notify "$report"
fi

purgeSystem

echo "The script dbBackup has finished!"
