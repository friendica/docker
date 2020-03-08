#!/bin/sh
set -eu

# run an command with the www-data user
run_as() {
	set -- -c "cd /var/www/html; $*"
	if [ "$(id -u)" -eq 0 ]; then
		su - www-data -s /bin/sh "$@"
	else
		sh  "$@"
	fi
}

# checks if the the first parameter is greater than the second parameter
version_greater() {
	[ "$(printf '%s\n' "$@" | sort -r -t '-' -k2,2  | sort -t '.' -n -k1,1 -k2,2 -s | head -n 1)" != "$1" ]
}

setup_ssmtp() {
	if [ -n "${SMTP_DOMAIN+x}" ] && [ -n "${SMTP+x}" ] && [ "${SMTP}" != "localhost" ]; then
		SITENAME="${FRIENDICA_SITENAME:-Friendica Social Network}"
		echo "Setup SSMTP for '$SITENAME' with '$SMTP' ..."

		smtp_from=${SMTP_FROM:-no-reply}

		# Setup SSMTP
		usermod --comment "$(echo "$SITENAME" | tr -dc '[:print:]')" root
		usermod --comment "$(echo "$SITENAME" | tr -dc '[:print:]')" www-data

		# add possible mail-senders
		{
		 echo "www-data:$smtp_from@$SMTP_DOMAIN:$SMTP"
		 echo "root::$smtp_from@$SMTP_DOMAIN:$SMTP"
		} > /etc/ssmtp/revaliases

		# replace ssmtp.conf settings
		{
		 echo "root=:$smtp_from@$SMTP_DOMAIN"
		 echo "hostname=$SMTP_DOMAIN"
		 echo "mailhub=$SMTP"
		 echo "FromLineOverride=YES"
		 if [ -n "${SMTP_TLS+x}" ]; then echo "UseTLS=$SMTP_TLS"; fi
		 if [ -n "${SMTP_STARTTLS+x}" ]; then echo "UseSTARTTLS=$SMTP_STARTTLS"; fi
		 if [ -n "${SMTP_AUTH_USER+x}" ]; then echo "AuthUser=$SMTP_AUTH_USER"; fi
		 if [ -n "${SMTP_AUTH_PASS+x}" ]; then echo "AuthPass=$SMTP_AUTH_PASS";fi
		 if [ -n "${SMTP_AUTH_METHOD+x}" ]; then echo "AuthMethod=$SMTP_AUTH_METHOD"; fi
		} > /etc/ssmtp/ssmtp.conf

		echo "Setup finished"
	fi
}

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

	setup_ssmtp

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
