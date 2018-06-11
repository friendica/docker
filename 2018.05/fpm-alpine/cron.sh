#!/bin/sh
trap "break;exit" HUP INT TERM

while [ ! -f /var/www/html/.htconfig.php ]; do
    sleep 1
done

while true; do
    php /var/www/html/bin/worker.php no_cron
    sleep 5m
done