#!/bin/bash

# shellcheck disable=SC1091
source "${HOME}/.bash_aliases"

#########################global variable
# shellcheck disable=SC2034
t_chatid=$(kdbxQuery "/others/telegram" username 2>/dev/null)
t_token=$(kdbxQuery "/others/telegram" password 2>/dev/null)

#########################functions

function notify() {
    msg=$1
    echo "$msg"
    curl -sS -X POST -H "Content-Type: application/json" -d "{\"chat_id\":\"$t_chatid\",\"text\":\"$msg\", \"disable_notification\": false}" "https://api.telegram.org/bot${t_token}/sendMessage"
}

function restartProxy() {
    tmpProto=$1
    targetProto=${2:-http}
    echo "Restarting Server Proxy to ${targetProto}..."
    if [ "$tmpProto" == "https" ]; then
        docker restart web-proxy
    else
        if ! [ -f "/etc/letsencrypt/conf/nginx-http.conf" ]; then
            echo "Missing /etc/letsencrypt/conf/nginx-http.conf file"
            exit 1
        fi
        if ! [ -f "/etc/letsencrypt/conf/nginx-https.conf" ]; then
            echo "Missing /etc/letsencrypt/conf/nginx-https.conf file"
            exit 1
        fi
        docker stop web-proxy
        cp -f "/etc/letsencrypt/conf/nginx-${targetProto}.conf" "/var/lib/docker/volumes/web-proxy-conf-vol/_data/nginx.conf"
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
    if [ "$res" == "" ]; then
        echo "Error while getting data for domain ${domain} : not reachable!"
        exit 1
    fi
    date -d "${res}" '+%Y-%m-%d %T'
}

#########################processing arguments

# shellcheck disable=SC2128
if [[ "$BASH_SOURCE" != "$0" ]]; then
    echo -e "\e[31mThe script must be runned with sh command: no source or dot!\e[0m"
    return 1
fi

domain="$1"
certEmail="$2"
if [ "$3" == "force" ]; then
    mode="request"
    tmpPort=80
    tmpProto="http"
else
    mode="renewing"
    tmpPort=443
    tmpProto="https"
fi
#########################Main script

echo "The script renewCert is starting!"
dte=$(date "+%s")

set -x

if [ "$mode" == "renewing" ]; then
    prettyDteCert=$(getCertificateExpiration "$domain")
    dteCert=$(date -d "${prettyDteCert}" +%s)
    if [ "$dte" -lt "$dteCert" ]; then
        echo "Certificate expiration date is ${prettyDteCert}, no certificate ${mode} is required"
        exit 1
    fi
    notify "Certificate expiration date is ${prettyDteCert}, ${mode} is required and will be performed"
fi

restartProxy "$tmpProto" "http"
wait4curl "${domain}:${tmpPort}"

echo "Performing certificate ${mode}..."
if [ "$mode" == "renewing" ]; then
    certbot renew --cert-name "$domain"
else
    certbot certonly --webroot --email="$certEmail" --webroot-path=/var/lib/docker/volumes/web-proxy-vol/_data/ -d "$domain" -d "www.${domain}" --agree-tos --force-renew
fi

mkdir -p "/var/lib/docker/volumes/web-proxy-conf-vol/_data/ssl/${domain}/"
# /etc/letsencrypt/live/${domain}/ is a symlink to /etc/letsencrypt/archive/${domain}-00XX/, where 00XX is incrementing at each renew
# symink is created by certbot just above, so no need to worry, /etc/letsencrypt/live/${domain}/ is always latest
cp -f "/etc/letsencrypt/live/${domain}/privkey.pem" "/var/lib/docker/volumes/web-proxy-conf-vol/_data/ssl/${domain}/privkey.pem"
cp -f "/etc/letsencrypt/live/${domain}/fullchain.pem" "/var/lib/docker/volumes/web-proxy-conf-vol/_data/ssl/${domain}/fullchain.pem"

if [ "$tmpProto" == "http" ]; then
    cp -f "/etc/letsencrypt/conf/nginx-https.conf" "/var/lib/docker/volumes/web-proxy-conf-vol/_data/nginx.conf"
fi
restartProxy "$tmpProto" "https"
wait4curl "${domain}:443"

dte=$(date "+%Y-%m-%d-%H%M%S")
echo "Backuping artefacts, timestamp is ${dte}..."
mkdir -p "/opt/CrtBackups/${domain}"
cp "/etc/letsencrypt/live/${domain}/privkey.pem" "/opt/CrtBackups/${domain}/${dte}.key"
cp "/etc/letsencrypt/live/${domain}/fullchain.pem" "/opt/CrtBackups/${domain}/${dte}.crt"

echo "Removing temporary artefacts..."

prettyDteCert=$(getCertificateExpiration "$domain")

echo "Server proxy started, certificate ${mode} successfull, certificate expiration is now $prettyDteCert"
notify "Server proxy started, certificate ${mode} successfull, certificate expiration is now $prettyDteCert"
