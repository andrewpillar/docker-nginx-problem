#!/bin/sh
# vim:sw=4:ts=4:et

# This script will fetch the latest 404 custom error page

set -e

entrypoint_log() {
    if [ -z "${NGINX_ENTRYPOINT_QUIET_LOGS:-}" ]; then
        echo "$0: $@"
    fi
}

entrypoint_log "downloading 404 page"

curl --silent \
    --show-error \
    --output "/var/www/nginx/errors/#1.html" \
    "https://raw.githubusercontent.com/asmithdt/docker-nginx-problem/main/{404}.html"
