#!/bin/bash

set -eo pipefail

# shellcheck disable=SC1091
source "${HOME}/.bash_aliases"

#########################global variable
# shellcheck disable=SC2034
read -r t_chatid t_token <<<"$(kdbxQuery -g others -t telegram)"
read -r m_userid m_token m_url <<<"$(kdbxQuery -g others -t matrix -a username -a password -a url)"
read -r m_chatid m_deviceid <<<"$(kdbxQuery -g others -t matrix2)"

#########################functions

function notify() {
    set +e
    msg=$1
    echo "$msg"
    curl -sS -X POST -H "Content-Type: application/json" -d "{\"chat_id\":\"$t_chatid\",\"text\":\"$msg\", \"disable_notification\": false}" "https://api.telegram.org/bot${t_token}/sendMessage"
    echo "{\"homeserver\": \"${m_url}\", \"device_id\": \"${m_deviceid}\", \"user_id\": \"${m_userid}\", \"room_id\": \"${m_chatid}\", \"access_token\": \"${m_token}\"}" > "${HOME}/.config/matrix-commander/credentials.json"
    matrix-commander -m "$msg" --encrypted -s "${COMMANDER_STORE_DIR}" -c "${HOME}/.config/matrix-commander/credentials.json"
    rm -f "${HOME}/.config/matrix-commander/credentials.json"
    set -e
}

function restartProxy() {
    srcProto=$1
    dstProto=${2:-http}
    echo "Restarting Server Proxy to ${dstProto}..."
    if [ "$srcProto" == "$dstProto" ]; then
        docker restart web-proxy
    else
        if ! [ -f "/etc/letsencrypt/conf/nginx-${dstProto}.conf" ]; then
            echo "Missing /etc/letsencrypt/conf/nginx-${dstProto}.conf file"
            exit 1
        fi
        docker stop web-proxy
        cp -f "/etc/letsencrypt/conf/nginx-${dstProto}.conf" "/var/lib/docker/volumes/web-proxy-conf-vol/_data/nginx.conf"
        docker start web-proxy
    fi
}

function wait4curl() {
    target=$1
    timeout=${2:-60}
    exitFlag=0
    i=0
    while [ $i -lt "$timeout" ] && [ $exitFlag == 0 ]; do
        sleep 1
        if curl "$target" 2>/dev/null >/dev/null; then
            exitFlag=1
        fi
        i=$((i + 1))
    done
    if [ $exitFlag == 0 ]; then
        echo "Could not connect after Server Proxy restart (1) : the certificate action has been aborted..."
        exit 1
    fi
    echo "Server proxy reachable to ${target}"
}

function getCertificateExpiration() {
    domain=$1
    res=$(: | openssl s_client -connect "${domain}:443" 2>/dev/null | openssl x509 -text 2>/dev/null | grep "Not After" | awk '{print $4" "$5" "$7" "$8}')
    if [ ! "$res" ] || [ "$res" == "" ]; then
        return 1
    fi
    date -d "${res}" '+%Y-%m-%d %T'
}

#########################processing arguments

# shellcheck disable=SC2128
if [[ "$BASH_SOURCE" != "$0" ]]; then
    echo -e "\e[31mThe script must be run with sh command: no source or dot!\e[0m"
    return 1
fi

domain="$1"
certEmail="$2"
if [ "$3" == "force" ]; then
    mode="request"
    IFS="," read -r -a subDomains <<< "$4"
else
    mode="renewing"
fi
#########################Main script

echo "The script renewCert is starting!"
dte=$(date "+%s")

if [ "$mode" == "renewing" ]; then
    prettyDteCert=$(getCertificateExpiration "$domain" || date -d @"${dte}" '+%Y-%m-%d %T')
    dte=$((dte + 86000)) # need to renew 1 day before because challenges are using the certificate itself
    dteCert=$(date -d "${prettyDteCert}" +%s)
    if [ "$dte" -lt "$dteCert" ]; then
        echo "Certificate expiration date is ${prettyDteCert}, no certificate ${mode} is required"
        exit 0
    fi
    notify "Certificate expiration date is ${prettyDteCert}, ${mode} is required and will be performed"
fi

restartProxy "https" "http"
wait4curl "${domain}:80"

echo "Performing certificate ${mode}..."
CMD=("certbot")
if [ "$mode" == "renewing" ]; then
    CMD+=("renew" "--cert-name" "$domain")
else
    CMD+=("certonly" "--webroot" "--email" "$certEmail" "--webroot-path" "/var/lib/docker/volumes/web-proxy-vol/_data/" "--agree-tos" "--force-renew" "-d" "$domain")
    for subDomain in "${subDomains[@]}"; do
        CMD+=("-d" "$subDomain")
    done
fi

echo "${CMD[@]}"
"${CMD[@]}"
echo $?

mkdir -p "/var/lib/docker/volumes/web-proxy-conf-vol/_data/ssl/${domain}/"
# /etc/letsencrypt/live/${domain}/ is a symlink to /etc/letsencrypt/archive/${domain}-00XX/, where 00XX is incrementing at each renew
# symink is created by certbot just above, so no need to worry, /etc/letsencrypt/live/${domain}/ is always latest
cp -f "/etc/letsencrypt/live/${domain}/privkey.pem" "/var/lib/docker/volumes/web-proxy-conf-vol/_data/ssl/${domain}/privkey.pem"
cp -f "/etc/letsencrypt/live/${domain}/fullchain.pem" "/var/lib/docker/volumes/web-proxy-conf-vol/_data/ssl/${domain}/fullchain.pem"

restartProxy "http" "https"
wait4curl "${domain}:443"

dte=$(date "+%Y-%m-%d-%H%M%S")
echo "Backuping artefacts, timestamp is ${dte}..."
mkdir -p "/opt/CrtBackups/${domain}"
cp "/etc/letsencrypt/live/${domain}/privkey.pem" "/opt/CrtBackups/${domain}/${dte}.key"
cp "/etc/letsencrypt/live/${domain}/fullchain.pem" "/opt/CrtBackups/${domain}/${dte}.crt"

prettyDteCert=$(getCertificateExpiration "$domain")

echo "Server proxy started, certificate ${mode} successfull, certificate expiration is now ${prettyDteCert}"
notify "Server proxy started, certificate ${mode} successfull, certificate expiration is now ${prettyDteCert}"
