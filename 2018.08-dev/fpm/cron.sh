#!/bin/sh
trap "break;exit" HUP INT TERM

while [ ! -f /var/www/html/.htconfig.php ]; do
    sleep 1
done

while true; do
    php -f /var/www/html/bin/worker.php
    sleep 10m
done