#!/usr/bin/env bash

set -e

# update_fqdn - Updates fqdn for server name and certificate names
# Arguments:
#    $1 - FQDN
#    $2 - Filename
function update_fqdn() {
    sed -i -Ee "s/(.*)fqdn(.*)/\1$1\2/g" $2
}

function update_service() {
    sed -i -Ee "s/(.*)service(.*)/\1$1\2/g" $2
}

function update_serviceport() {
    sed -i -Ee "s/(.*)port(.*)/\1$1\2/g" $2
}

ssl_enabled=0

while [[ $# -gt 0 ]]
do
    case $1 in
        -ssl|--ssl-enabled)
            ssl_enabled=1
        ;;
    esac
    shift
done

if [[ $ssl_enabled -gt 0 ]]
then
    rm -f /etc/nginx/conf.d/http.conf
    update_fqdn $FQDN /etc/nginx/conf.d/https.conf
    update_service $SERVICE /etc/nginx/conf.d/https.conf
    update_serviceport $SERVICEPORT /etc/nginx/conf.d/https.conf
    
    # Issue certificate from letsencrypt and install in nginx folder
    [[ -z $ACME_DNSSLEEP ]] && ACME_DNSSLEEP=60
    set +e
    /root/.acme.sh/acme.sh --issue -d $FQDN --dns dns_lexicon --dnssleep $ACME_DNSSLEEP
    exitcode=$?
    if [ $exitcode -ne 0 ] && [ $exitcode -ne 2 ]; then exit $exitcode; fi
    if [ $exitcode -eq 0 ]
    then
        /root/.acme.sh/acme.sh --install-cert -d $FQDN --key-file /etc/nginx/ssl/fqdn_key.pem \
            --fullchain-file /etc/nginx/ssl/fqdn_cert.pem \
            --reloadcmd "nginx -s reload"
    fi
    set -e
else
    rm -f /etc/nginx/conf.d/https.conf
    update_fqdn $FQDN /etc/nginx/conf.d/http.conf
    update_service $SERVICE /etc/nginx/conf.d/https.conf
    update_serviceport $SERVICEPORT /etc/nginx/conf.d/https.conf
fi

exec nginx -g "daemon off;"
