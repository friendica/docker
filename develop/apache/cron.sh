#!/bin/sh
set -eu

trap "break;exit" SIGHUP SIGINT SIGTERM

while [ ! -f /var/www/html/.htconfig.php ]; do
    sleep 1
done

while true; do
    cd /var/www/html
    php -f /var/www/html/bin/worker.php
    sleep 10m
done