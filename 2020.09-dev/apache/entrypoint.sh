#!/bin/sh
set -eu

# run an command with the www-data user
run_as() {
  set -- -c "cd /var/www/html; $*"
  if [ "$(id -u)" -eq 0 ]; then
    su - www-data -s /bin/sh "$@"
  else
    sh "$@"
  fi
}

# checks if the the first parameter is greater than the second parameter
version_greater() {
  [ "$(printf '%s\n' "$@" | sed -e 's/-rc/.1/' | sed -e 's/-dev/.2/' | sort -t '.' -k1,1n -k2,2n -k3,3nbr | head -n 1)" != "$(printf "$1" | sed -e 's/-rc/.1/' | sed -e 's/-dev/.2/')" ]
}

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    local varValue=$(env | grep -E "^${var}=" | sed -E -e "s/^${var}=//")
    local fileVarValue=$(env | grep -E "^${fileVar}=" | sed -E -e "s/^${fileVar}=//")
    if [ -n "${varValue}" ] && [ -n "${fileVarValue}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    if [ -n "${varValue}" ]; then
        export "$var"="${varValue}"
    elif [ -n "${fileVarValue}" ]; then
        export "$var"="$(cat "${fileVarValue}")"
    elif [ -n "${def}" ]; then
        export "$var"="$def"
    fi
    unset "$fileVar"
}

sh /setup_msmtp.sh

# just check if we execute apache or php-fpm
if expr "$1" : "apache" 1>/dev/null || [ "$1" = "php-fpm" ]; then
  installed_version="0.0.0.0"
  if [ -f /var/www/html/VERSION ]; then
    installed_version="$(cat /var/www/html/VERSION)"
  fi

  image_version="$(cat /usr/src/friendica/VERSION)"

  # no downgrading possible
  if version_greater "$installed_version" "$image_version"; then
    echo "Can't copy Friendica sources because the version of the data ($installed_version) is higher than the docker image ($image_version)"
    exit 1
  fi

  # check it just in case the version is greater or if we force the upgrade
  if version_greater "$image_version" "$installed_version" || [ "${FRIENDICA_UPGRADE:-false}" = "true" ]; then
    echo "Initializing Friendica $image_version ..."

    if [ "$installed_version" != "0.0.0.0" ]; then
      echo "Upgrading Friendica from $installed_version ..."
    fi

    if [ "$(id -u)" -eq 0 ]; then
      rsync_options="-rlDog --chown=www-data:www-data"
    else
      rsync_options="-rlD"
    fi

    rsync $rsync_options --delete --exclude-from=/upgrade.exclude /usr/src/friendica/ /var/www/html/

    # Update docker-based config files, but never delete other config files
    rsync $rsync_options --update /usr/src/friendica/config/ /var/www/html/config/

    # In case there is no .htaccess, copy it from the default dist file
    if [ ! -f "/var/www/html/.htaccess" ]; then
      cp "/var/www/html/.htaccess-dist" "/var/www/html/.htaccess"
    fi

    if [ -d /var/www/html/view/smarty3 ]; then
      chmod -R 777 /var/www/html/view/smarty3
    fi
    echo "Initializing finished"

    # install
    if [ "$installed_version" = "0.0.0.0" ]; then
      echo "New Friendica instance"

      file_env FRIENDICA_ADMIN_MAIL

      file_env MYSQL_DATABASE
      file_env MYSQL_USER
      file_env MYSQL_PASSWORD

      install=false
      if [ -n "${MYSQL_DATABASE+x}" ] && [ -n "${MYSQL_PASSWORD+x}" ] && [ -n "${MYSQL_HOST+x}" ] && [ -n "${MYSQL_USER+x}" ] && [ -n "${FRIENDICA_ADMIN_MAIL+x}" ] && [ -n "${FRIENDICA_URL+x}" ]; then
        echo "Installation with environment variables"

        FRIENDICA_TZ=${FRIENDICA_TZ:-America/LosAngeles}
        FRIENDICA_LANG=${FRIENDICA_LANG:-en}
        MYSQL_PORT=${MYSQL_PORT:-3306}

        # shellcheck disable=SC2016
        install_options='-s --dbhost "'$MYSQL_HOST'" --dbport "'$MYSQL_PORT'" --dbdata "'$MYSQL_DATABASE'" --dbuser "'$MYSQL_USER'" --dbpass "'$MYSQL_PASSWORD'"'

        # shellcheck disable=SC2016
        install_options=$install_options' --admin "'$FRIENDICA_ADMIN_MAIL'" --tz "'$FRIENDICA_TZ'" --lang "'$FRIENDICA_LANG'" --url "'$FRIENDICA_URL'"'
        install=true
      fi

      if [ "$install" = true ]; then
        echo "Waiting for MySQL $MYSQL_HOST initialization..."
        if run_as "php /var/www/html/bin/wait-for-connection $MYSQL_HOST ${MYSQL_PORT:-3306} 300"; then

          echo "Starting Friendica installation ..."
          run_as "php /var/www/html/bin/console.php autoinstall $install_options"

          rm -fr /var/www/html/view/smarty3/compiled

          # load other config files (*.config.php) to the config folder
          if [ -d "/usr/src/config" ]; then
            rsync $rsync_options --ignore-existing /usr/src/config/ /var/www/html/config/
          fi

          echo "Installation finished"
        else
          echo "[ERROR] Waited 300 seconds, no response" >&2
        fi
      else
        echo "Running web-based installer on first connect!"
      fi
    # upgrade
    else
      echo "Upgrading Friendica ..."
      run_as 'php /var/www/html/bin/console.php dbstructure update'
      echo "Upgrading finished"
    fi
  fi
fi

exec "$@"
