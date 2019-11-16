#!/bin/sh
trap "break;exit" HUP INT TERM

while [ ! -f /var/www/html/config/local.ini.php ] && [ ! -f /var/www/html/config/local.config.php ]; do
    sleep 1
done

# TODO let the database and the autoinstall time to complete - not winning a beauty contest
sleep 15s

exec php /var/www/html/bin/daemon.php -f start
