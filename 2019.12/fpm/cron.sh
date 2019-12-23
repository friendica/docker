#!/bin/sh
trap "break;exit" HUP INT TERM

while [ ! -f /var/www/html/bin/daemon.php ]; do
    sleep 1
done

echo "Waiting for MySQL $MYSQL_HOST initialization..."
if /usr/local/bin/wait-for-connection "$MYSQL_HOST" "$MYSQL_PORT" 300; then
  exec php /var/www/html/bin/daemon.php -f start
  echo "[ERROR] Waited 300 seconds, no response" >&2
fi
