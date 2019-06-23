#!/bin/sh
set -eu

# run an command with the www-data user
run_as() {
	if [ "$(id -u)" -eq 0 ]; then
		su - www-data -s /bin/sh -c "cd /var/www/html;$1"
	else
		sh -c "$1"
	fi
}

# checks if the the first parameter is greater than the second parameter
version_greater() {
	[ "$(printf '%s\n' "$@" | sort -r -t '-' -k2,2  | sort -t '.' -n -k1,1 -k2,2 -s | head -n 1)" != "$1" ]
}

# clones the whole develop branch (Friendica and Addons)
clone_develop() {
	friendica_git="${FRIENDICA_VERSION}"
	addons_git="${FRIENDICA_ADDONS}"
	friendica_repo="${FRIENDICA_REPOSITORY:-friendica}"
	friendica_addons_repo="${FRIENDICA_ADDONS_REPO:-friendica}"

	if echo "{$friendica_git,,}" | grep -Eq '^.*\-dev'; then
		friendica_git="develop"
	fi

	if echo "{$addons_git,,}" | grep -Eq '^.*\-dev'; then
		addons_git="develop"
	fi

	echo "Downloading Friendica from GitHub '${friendica_repo}/${friendica_git}' ..."

	# Removing the whole directory first
	rm -fr /usr/src/friendica
	sh -c "git clone -q -b ${friendica_git} https://github.com/${friendica_repo}/friendica /usr/src/friendica"

	mkdir /usr/src/friendica/addon
	sh -c "git clone -q -b ${addons_git} https://github.com/${friendica_addons_repo}/friendica-addons /usr/src/friendica/addon"

	echo "Download finished"

	if [ ! -f /usr/src/friendica/VERSION ]; then
		echo "Couldn't clone repository"
		exit 1
	fi

	/usr/src/friendica/bin/composer.phar install --no-dev -d /usr/src/friendica
}

setup_ssmtp() {
	if [ -n "${SITENAME+x}" ] && [ -n "${SMTP+x}" ] && [ "${SMTP}" != "localhost" ]; then
		echo "Setup SSMTP for '$SITENAME' with '$SMTP' ..."

		smtp_from=${SMTP_FROM:-no-reply}

		# Setup SSMTP
		sed -i "s/:root:/:${SITENAME}:/g" /etc/passwd
		sed -i "s/:Linux\ User:/:${SITENAME}:/g" /etc/passwd

		# add possible mail-senders
		{
		 echo "www-data:$smtp_from@$HOSTNAME:$SMTP" ;
		 echo "root::$smtp_from@$HOSTNAME:$SMTP" ;
		} > /etc/ssmtp/revaliases;

		# replace ssmtp.conf settings
		{
		 echo "root=:$smtp_from@$HOSTNAME" ;
		 echo "hostname=$HOSTNAME" ;
		 echo "mailhub=$SMTP" ;
		 echo "FromLineOverride=YES" ;
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

	check=false
	# cloning from git is just possible for develop or Release Candidats
	if echo "${FRIENDICA_VERSION}" | grep -Eq '^.*(\-dev|-rc|-RC)' || [ "${FRIENDICA_UPGRADE:-false}" = "true" ] || [ ! -f /usr/src/friendica/VERSION ]; then
		# just clone & check if it's a new install or upgrade
		clone_develop
		image_version="$(cat /usr/src/friendica/VERSION)"
		check=true
	else
		image_version="$(cat /usr/src/friendica/VERSION)"

		# check it just in case the version is greater
		if version_greater "$image_version" "$installed_version"; then
			check=true
		fi

		# no downgrading possible
		if version_greater "$installed_version" "$image_version"; then
			echo 'Can'\''t copy Friendica sources because the version of the data ('$installed_version') is higher than the docker image ('$image_version')', 0
			exit 1;
		fi
	fi

	setup_ssmtp

	if [ "$check" = true ]; then
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
			if [ -n "${MYSQL_DATABASE+x}" ] && [ -n "${MYSQL_PASSWORD+x}" ] && [ -n "${MYSQL_HOST+x}" ] && [ -n "${MYSQL_USER+x}" -o -n "${MYSQL_USERNAME+x}" ] && [ -n ${FRIENDICA_ADMIN_MAIL+x} ]; then
				echo "Installation with environment variables"

				FRIENDICA_PHP_PATH=${FRIENDICA_PHP_PATH:-/usr/local/php}
				FRIENDICA_TZ=${FRIENDICA_TZ:-America/LosAngeles}
				FRIENDICA_LANG=${FRIENDICA_LANG:-en}
				MYSQL_PORT=${MYSQL_PORT:-3306}
				if [ -n "${MYSQL_USER+x}" ]; then
					MYSQL_USERNAMEFULL=${MYSQL_USER}
				else
					MYSQL_USERNAMEFULL=${MYSQL_USERNAME}
				fi

				# shellcheck disable=SC2016
				install_options='-s --dbhost "'$MYSQL_HOST'" --dbport "'$MYSQL_PORT'" --dbdata "'$MYSQL_DATABASE'" --dbuser "'$MYSQL_USERNAMEFULL'" --dbpass "'$MYSQL_PASSWORD'"'

				# shellcheck disable=SC2016
				install_options=$install_options' --admin "'$FRIENDICA_ADMIN_MAIL'" --tz "'$FRIENDICA_TZ'" --lang "'$FRIENDICA_LANG'"'
				install=true
			elif [ -f "/usr/src/config/local.config.php" ]; then
				echo "Installation with prepared local.config.php"

				install_options="-f /usr/src/local.config.php"
				install=true
			fi

			if [ "$install" = true ]; then
				echo "Starting Friendica installation ..."
				# TODO Let the database time to warm up - not winning a beauty contest
				sleep 10s
				run_as "cd /var/www/html; php /var/www/html/bin/console.php autoinstall $install_options"

				# TODO Workaround because of a strange permission issue
				rm -fr /var/www/html/view/smarty3/compiled

				# load other config files (*.config.php) to the config folder (currently only local.config.php and addon.config.php supported)
				if [ -d "/usr/src/config" ]; then
					rsync $rsync_options --ignore-existing /usr/src/config/ /var/www/html/config/
				fi

				echo "Installation finished"
			else
				echo "Running web-based installer on first connect!"
			fi
		# upgrade
		else
			echo "Upgrading Friendica ..."
			run_as 'cd /var/www/html; php /var/www/html/bin/console.php dbstructure update'
			echo "Upgrading finished"
		fi
	fi
fi

exec "$@"
