#!/bin/bash

#########################global variable
# shellcheck disable=SC2128
if [[ "$BASH_SOURCE" != "$0" ]]; then
    echo -e "\e[31mThe script must be runned with sh command: no source or dot!\e[0m"
    return 1
fi
tid=$(kdbxQuery "/others/telegram" password 2>/dev/null)
logDir="/var/log/ssl"
# script not finished

#########################processing arguments

domain="$1"
certEmail="$2"
if [ "$3" == "force" ]; then
    mode="request"
    tmpPort=80
    tmpProto="http"
    logFlag="0"
else
    mode="renewing"
    tmpPort=443
    tmpProto="https"
    logFlag="4"
fi
#########################Main script

echo "The script renewCert is starting!" "SUCCESS"
dte=$(date "+%s")

if [ "$mode" == "renewing" ]; then
    res=$(: | openssl s_client -connect "${domain}:443" 2>/dev/null | openssl x509 -text 2>/dev/null | grep "Not After" | awk '{print $4" "$5" "$7" "$8}')
    if [ "$res" == "" ]; then
        echo "Error while getting data for domain ${domain} : not reachable!" "ERROR" "${logFlag}"
        exit 1
    fi
    dteCert=$(date "-d \"${res}\" +%s")
    prettyDteCert=$(date "-d \"${res}\" '+%Y-%m-%d %T'")
    if [ "$dte" -lt "$dteCert" ]; then
        echo "Certificate expiration date is ${prettyDteCert}, no certificate ${mode} is required"
        exit 1
    fi
    echo "Certificate expiration date is ${prettyDteCert}, ${mode} is required and will be performed" "WARNING" 4
fi

echo "Restarting Server Proxy (1)"
# resnul=$(Conn_CMDquery "sh" "/opt/scripts/docker-scripts/service-web-proxy.sh ${tmpProto}")
exitFlag=0
timeout=60
i=0
while [ $i -lt $timeout ] && [ $exitFlag == 0 ]; do
    sleep 1
    if ! curl "${domain}:${tmpPort}" 2>/dev/null >/dev/null; then
        exitFlag=1
    fi
    i=$((i + 1))
done
if [ $exitFlag == 0 ]; then
    echo "Could not connect after Server Proxy restart (1) : the certificate $mode has been aborted..." "ERROR" "${logFlag}"
    exit 1
fi
echo "Server proxy started"

rm -fr "/var/lib/docker/volumes/web-proxy-vol/_data/ssl/${domain}.key"
rm -fr "/var/lib/docker/volumes/web-proxy-vol/_data/ssl/${domain}.crt"
rm -fr "/var/lib/docker/volumes/web-proxy-vol/_data/ssl/${domain}-dhparam2048.pem"

openssl dhparam -out "/etc/letsencrypt/live/${domain}/${domain}-dhparam2048.pem 2048"

rm -fr "/etc/letsencrypt/live/${domain}/privkey.pem"
ln -s "/etc/letsencrypt/archive/${domain}/privkey.pem" "/etc/letsencrypt/live/${domain}/privkey.pem"
rm -fr "/etc/letsencrypt/live/${domain}/fullchain.pem"
ln -s "/etc/letsencrypt/archive/${domain}/fullchain.pem" "/etc/letsencrypt/live/${domain}/fullchain.pem"
#these 2 lines are a certbot bug fixing
# next time if one cert is ok and not the other, then it means that we have to ln really the very last one (incremented number each time)

echo "Performing certificate ${mode}..."
if [ "$mode" == "renewing" ]; then
    certbot renew --cert-name "$domain"
else
    certbot certonly --webroot --email="$certEmail" --webroot-path=/var/lib/docker/volumes/web-proxydata-vol/_data/ -d "$domain" -d "www.${domain}" --agree-tos --force-renew
fi

canonicalSrcDhparam=$(readlink -qsf "/etc/letsencrypt/live/${domain}/${domain}-dhparam2048.pem")
cp "$canonicalSrcDhparam" "/var/lib/docker/volumes/web-proxy-vol/_data/ssl/${domain}/${domain}-dhparam2048.pem"
canonicalSrcPrivkey=$(readlink -qsf "/etc/letsencrypt/live/${domain}/privkey.pem")
cp "$canonicalSrcPrivkey" "/var/lib/docker/volumes/web-proxy-vol/_data/ssl/${domain}/${domain}.key" "/var/lib/docker/volumes/web-proxy-vol/_data/ssl/${domain}/privkey.pem"
canonicalSrcFullchain=$(readlink -qsf "/etc/letsencrypt/live/${domain}/fullchain.pem")
cp "$canonicalSrcFullchain" "/var/lib/docker/volumes/web-proxy-vol/_data/ssl/${domain}/${domain}.crt"

echo "Restarting Server Proxy (2)"
# resnul=$(Conn_CMDquery "sh" "/opt/scripts/docker-scripts/service-web-proxy.sh")
exitFlag=0
i=0
while [ $i -lt $timeout ] && [ $exitFlag == 0 ]; do
    sleep 1
    if ! curl "${domain}:443" 2>/dev/null >/dev/null; then
        exitFlag=1
    fi
    i=$((i + 1))
done
if [ $exitFlag == 0 ]; then
    echo "Could not connect after Server Proxy restart (2) : the certificate ${mode} has been aborted..." "ERROR" "${logFlag}"
    exit 1
fi

dte=$(date "+%Y-%m-%d-%H%M%S")
echo "Backuping artefacts, timestamp is ${dte}..."
cp "$canonicalSrcDhparam" "/opt/CrtBackups/${domain}/${dte}-dhparam2048.pem"
cp "$canonicalSrcPrivkey" "/opt/CrtBackups/${domain}/${dte}.key"
cp "$canonicalSrcFullchain" "/opt/CrtBackups/${domain}/${dte}.crt"

echo "Removing temporary artefacts..."
rm -fr "$canonicalSrcDhparam"
rm -fr "$canonicalSrcPrivkey"
rm -fr "$canonicalSrcFullchain"

echo "Server proxy started, certificate ${mode} successfull, the script has finished!" "SUCCESS" "${logFlag}"
