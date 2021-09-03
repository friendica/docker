#!/bin/sh
trap "break;exit" HUP INT TERM

while [ ! -f /var/www/html/bin/daemon.php ]; do
  sleep 1
done

echo "Waiting for MySQL $MYSQL_HOST initialization..."
if php /var/www/html/bin/wait-for-connection "$MYSQL_HOST" "${MYSQL_PORT:-3306}" 300; then
  sh /setup_msmtp.sh
  exec gosu www-data:www-data tini -- php /var/www/html/bin/daemon.php -f start
else
  echo "[ERROR] Waited 300 seconds, no response" >&2
fi
