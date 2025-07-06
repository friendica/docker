#!/bin/sh
set -eu

if [ -f /var/www/html/config/local.config.php ]; then

  if [ -n "$MYSQL_HOST" ] && [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_PASSWORD" ] && [ -n "$MYSQL_DATABASE" ]; then
    echo "Setting up database as '$MYSQL_DATABASE' on '$MYSQL_HOST' with user '$MYSQL_USER'..."

     sed -i "/'database' => \[/,/\],/s/\('hostname' => \s*\)\('[^']*'\)/\1'${MYSQL_HOST}'/" /var/www/html/config/local.config.php
     sed -i "/'database' => \[/,/\],/s/\('username' => \s*\)\('[^']*'\)/\1'${MYSQL_USER}'/" /var/www/html/config/local.config.php
     sed -i "/'database' => \[/,/\],/s/\('password' => \s*\)\('[^']*'\)/\1'${MYSQL_PASSWORD}'/" /var/www/html/config/local.config.php
     sed -i "/'database' => \[/,/\],/s/\('database' => \s*\)\('[^']*'\)/\1'${MYSQL_DATABASE}'/" /var/www/html/config/local.config.php

     echo "Database setup finished"
  fi
fi
