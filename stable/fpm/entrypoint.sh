#!/bin/sh
set -eu

FRIENDICA_VERSION=${FRIENDICA_VERSION:-develop}
FRIENDICA_ADDONS=${FRIENDICA_ADDONS:-develop}
AUTOINSTALL=${AUTOINSTALL:-false}

SOURCEDIR=/usr/src
WORKDIR=/var/www/html

# run an command with the www-data user
run_as() {
  if [ "$(id -u)" = 0 ]; then
    su - www-data -s /bin/sh -c "$1"
  else
    sh -c "$1"
  fi
}

# checks if the the first parameter is greater than the second parameter
version_greater() {
  [ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 | head -n 1)" != "$1" ]
}

# executes the Friendica console
console() {
  cd $WORKDIR
  # Todo starting a php-executable without quoting the arguments seems not secure (but is the only way it works)
  sh -c "php $WORKDIR/bin/console.php $@" > /dev/null 2&>1
}

# If there is no VERSION file or the command is "update", (re-)install Friendica
if [ ! -f $WORKDIR/VERSION -o "$1" = "update" ]; then

  installed_version="0.0.0.0"
  if [ -f $WORKDIR/VERSION ]; then
    installed_version="$(cat $WORKDIR/VERSION)"
  fi

  if [ "$FRIENDICA_VERSION" = "develop" ]; then
    # Removing the whole directory first
    rm -fr $SOURCEDIR/friendica

    git clone --quiet -b $FRIENDICA_VERSION https://github.com/friendica/friendica $SOURCEDIR/friendica > /dev/null 2&>1
    chmod 777 $SOURCEDIR/friendica/view/smarty3
    mkdir $SOURCEDIR/friendica/addon
    git clone --quiet -b $FRIENDICA_ADDONS https://github.com/friendica/friendica-addons $SOURCEDIR/friendica/addon > /dev/null 2&>1
  fi

  image_version="0.0.0.0"
  if [ -f $SOURCEDIR/friendica/VERSION ]; then
    image_version="$(cat $SOURCEDIR/friendica/VERSION)"
  else
    # no given installation and not using the developer branch => nothing to do
    echo "Friendica command '$1' failed, because no version found"
    exit 1;
  fi

  if version_greater "$installed_version" "$image_version"; then
    echo "Can't copy Friendica sources because the version of the data ($installed_version) is higher than the docker image ($image_version)"
    exit 1;
  fi

  if version_greater "$image_version" "$installed_version"; then
    if [ "$(id -u)" = 0 ]; then
        rsync_options="-rlDog --chown www-data:root"
    else
        rsync_options="-rlD"
    fi

    rsync $rsync_options --delete --exclude='.git/' ${SOURCEDIR}/friendica/ ${WORKDIR}/

    if [ "$FRIENDICA_VERSION" = "develop" ]; then
      if [ ! -f ${WORKDIR}/bin/composer.phar ]; then
        echo "no composer found"
        exit 1
      fi

      run_as "cd $WORKDIR;$WORKDIR/bin/composer.phar install -d $WORKDIR" > /dev/null 2&>1
    fi

    if [ ! -f $WORKDIR/.htconfig.php ] &&
       [ -f $SOURCEDIR/config/htconfig.php ] &&
       "$AUTOINSTALL" == "true"; then
      run_as "cp $SOURCEDIR/config/htconfig.php $WORKDIR/html/.htconfig.php"
      # TODO Pull Request for dba Change
      run_as "sed -i 's/\s+\sDNS_CNAME//g' $WORKDIR/include/dba.php"
      console "autoinstall -f .htconfig.php"
      # TODO Workaround because of a strange permission issue
      rm -fr $WORKDIR/view/smarty3/compiled
    elif [ "$1" = "update" ]; then
      console "dbstructure update"
    fi
  fi
fi

# Start sendmail if you find it
if [ -f /etc/init.d/sendmail ]; then

  line=$(head -n 1 /etc/hosts)
  line2=$(echo $line | awk '{print $2}')
  echo "$line $line2.localdomain" >> /etc/hosts

  nohup /etc/init.d/sendmail start > /dev/null 2>&1 &
fi

exec "$@"