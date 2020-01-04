#!/bin/sh
trap "break;exit" HUP INT TERM

while [ ! -f /var/www/html/bin/daemon.php ]; do
    sleep 1
done

echo "Waiting for MySQL $MYSQL_HOST initialization..."
if run_as "php /var/www/html/bin/wait-for-connection $MYSQL_HOST ${MYSQL_PORT:-3306}" 300; then
  exec php /var/www/html/bin/daemon.php -f start
else
  echo "[ERROR] Waited 300 seconds, no response" >&2
fi
