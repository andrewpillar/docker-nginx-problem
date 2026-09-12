#!/bin/sh
# vim:sw=4:ts=4:et

set -e

entrypoint_log() {
    if [ -z "${NGINX_ENTRYPOINT_QUIET_LOGS:-}" ]; then
        echo "$0: $@"
    fi
}

CN="localhost"

entrypoint_log "generating tls certificate for $CN"

openssl req -x509 \
    -newkey rsa:4096 \
    -keyout "/etc/nginx/$CN.key" \
    -out "/etc/nginx/$CN.pem" \
    -days 30 \
    -nodes \
    -subj "/CN=$CN"
