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
	[ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 | head -n 1)" != "$1" ]
}

directory_empty() {
	[ -z "$(ls -A "$1/")" ]
}

# clones the whole develop branch (Friendica and Addons)
clone_develop() {
	friendica_git="${FRIENDICA_VERSION}"
	addons_git="${FRIENDICA_ADDONS}"

	if echo "$friendica_git" | grep -Eq '^.*\-dev'; then
		friendica_git="develop"
	fi

	if echo "$addons_git" | grep -Eq '^.*\-dev'; then
		addons_git="develop"
	fi

	echo "Downloading Friendica from GitHub '${friendica_git}' ..."

	# Removing the whole directory first
	rm -fr /usr/src/friendica
	sh -c "git clone -q -b ${friendica_git} https://github.com/friendica/friendica /usr/src/friendica"

	mkdir /usr/src/friendica/addon
	sh -c "git clone -q -b ${addons_git} https://github.com/friendica/friendica-addons /usr/src/friendica/addon"

	echo "Download finished"

	/usr/src/friendica/bin/composer.phar install --no-dev --no-plugins --no-scripts -d /usr/src/friendica
}

# just check if we execute apache or php-fpm
if expr "$1" : "apache" 1>/dev/null || [ "$1" = "php-fpm" ]; then
	installed_version="0.0.0.0"
	if [ -f /var/www/html/VERSION ]; then
		installed_version="$(cat /var/www/html/VERSION)"
	fi

	check=false
	# cloning from git is just possible for develop or Release Candidats
	if echo "$FRIENDICA_VERSION" | grep -Eq '^.*(\-dev|-rc)'; then
		# just clone & check if it's a new install or upgrade
		if [ "$installed_version" = "0.0.0.0" ] || [ "$FRIENDICA_UPGRADE" = "true" ]; then
			clone_develop
			image_version="$(cat /usr/src/friendica/VERSION)"
			check=true
		fi
	else
		image_version="$(cat /usr/src/friendica/VERSION)"

		# check it just in case the version is greater
		if version_greater "$image_version" "$installed_version"; then
			check=true
		fi

		# no downgrading possible
		if version_greater "$installed_version" "$image_version"; then
			echo 'Can'\''t copy Friendica sources because the version of the data ($installed_version) is higher than the docker image ('$image_version')', 0
			exit 1;
		fi
	fi

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

		# copy every *.ini.php from the config directory except they are already copied (in case of an upgrade)
		for dir in config; do
			if [ ! -d "/var/www/html/$dir" ] || directory_empty "/var/www/html/$dir"; then
				rsync $rsync_options --include="/$dir/" --exclude="/*" /usr/src/friendica/ /var/www/html/
			fi
		done

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

				# TODO Bug in PHP Path for automatic installation
				#FRIENDICA_PHP_PATH=${FRIENDICA_PHP_PATH:-/usr/local/php}
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
			elif [ -f "/usr/src/config/local.ini.php" ]; then
				echo "Installation with prepared local.ini.php"

				install_options="-f /usr/src/local.ini.php"
				install=true
			fi

			if [ "$install" = true ]; then
				echo "Starting Friendica installation ..."
				# TODO Let the database time to warm up - not winning a beauty contest
				sleep 10s
				run_as "/var/www/html/bin/console autoinstall $install_options"

				# TODO Workaround because of a strange permission issue
				rm -fr /var/www/html/view/smarty3/compiled

				# load other config files (*.ini.php) to the config folder (currently only local.ini.php and addon.ini.php supported)
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
			run_as '/var/www/html/bin/console dbstructure update'
			echo "Upgrading finished"
		fi
	fi
fi

exec "$@"
