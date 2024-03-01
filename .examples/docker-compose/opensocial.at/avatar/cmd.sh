#!/bin/sh
set -eu

envsubst < /etc/nginx/conf.d/templates/server_name.template > /etc/nginx/conf.d/server_name.active
nginx -qt
until ping app -c1 > /dev/null; do sleep 1; done

exec nginx -g 'daemon off;'
