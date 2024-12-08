#!/bin/bash

# shellcheck disable=SC1091
source "${HOME}/.bash_aliases"

#########################global variable
# shellcheck disable=SC2034
read -r t_chatid t_token <<<"$(kdbxQuery -g others -t telegram)"
read -r m_userid m_token m_url <<<"$(kdbxQuery -g others -t matrix -a username -a password -a url)"
read -r m_chatid m_deviceid <<<"$(kdbxQuery -g others -t matrix2)"

#########################functions

function notify() {
    msg=$1
    curl -sS -X POST -H "Content-Type: application/json" -d "{\"chat_id\":\"$t_chatid\",\"text\":\"$msg\", \"disable_notification\": false}" "https://api.telegram.org/bot${t_token}/sendMessage"
    echo "{\"homeserver\": \"${m_url}\", \"device_id\": \"${m_deviceid}\", \"user_id\": \"${m_userid}\", \"room_id\": \"${m_chatid}\", \"access_token\": \"${m_token}\"}" > "${HOME}/.config/matrix-commander/credentials.json"
    matrix-commander -m "${msg//\\n/<br />}" -w --encrypted -s "${COMMANDER_STORE_DIR}" -c "${HOME}/.config/matrix-commander/credentials.json"
    rm -f "${HOME}/.config/matrix-commander/credentials.json"
}

function backup() {
    db_scheme=$1
    db_host=$2
    db_name=$3
    db_username=$4
    db_password=$5
    dte=$6

    mkdir -p "/opt/DBBackups/${db_host}"
    CMD=("docker" "exec" "-u" "0" "$db_host" "sh" "-c")
    if [ "$db_scheme" == "mysql" ]; then
        CMD+=("mysqldump --no-tablespaces -u $db_username -p${db_password} $db_name")
    elif [ "$db_scheme" == "postgres" ]; then
        CMD+=("echo \"$db_password\" | pg_dump -a -U $db_username -d $db_name")
    else
        echo "export of database type ${db_scheme} not implemented"
        return
    fi
    "${CMD[@]}" >"/opt/DBBackups/${db_host}/${db_name}-${dte}.dmp"
}
function report() {
    db_host=$1
    db_name=$2
    dte=$3
    if [ -f "/opt/DBBackups/${db_host}/${db_name}-${dte}.dmp" ]; then
        # shellcheck disable=SC2012
        currSize=$(ls -lh "/opt/DBBackups/${db_host}/${db_name}-${dte}.dmp" | awk '{print $5}')
        currMD5=$(md5sum "/opt/DBBackups/${db_host}/${db_name}-${dte}.dmp" | awk '{print $1}')
        report="${report}\nBackup: Size ${currSize} / md5 ${currMD5}"
    else
        report="${report}\nBackup: Failed!"
    fi
}

function archive() {
    db_host=$1
    db_name=$2
    previousFileSize=0
    previousFileMonth=0
    rmCnt=0
    fileCnt=0
    startFileDate=""
    # shellcheck disable=SC2012
    for item in $(ls -1 "/opt/DBBackups/${db_host}/${db_name}-"*".dmp" | sort); do
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
    apt-get autoremove -yq
}

#########################Main script
dte=$(date "+%Y-%m-%d-%H%M%S")
echo "The script dbBackup is starting (${dte})!"

report="$dte"

for backup_item in "$@"; do # for example /databases/matrix-db/syncv3
    backup_group=$(dirname "$backup_item") # for example /databases/matrix-db
    backup_title=$(basename "$backup_item") # for example syncv3

    read -r db_username db_password backup_url <<<"$(kdbxQuery -g "$backup_group" -t "$backup_title" -a username -a password -a url)"
    db_name=$(basename "$backup_url") # for example syncv3
    IFS=":" read -r db_scheme db_host <<< "$(dirname "$backup_url")" # for example postgres //matrix-db
    db_host="${db_host/\/\//}" # for example matrix-db

    report="${report}\n\n${backup_url}"

    backup "$db_scheme" "$db_host" "$db_name" "$db_username" "$db_password" "$dte"
    report "$db_host" "$db_name" "$dte"
    archive "$db_host" "$db_name"
done

if [ -n "$report" ]; then
    notify "$report"
fi

purgeSystem

echo "The script dbBackup has finished!"
