#!/bin/sh
set -eu

# just check if we execute apache or php-fpm
if (expr "$1" : "apache" 1>/dev/null || [ "$1" = "php-fpm" ]) && [ "${FRIENDICA_UPGRADE:-false}" = "true" ]; then
  curl -fsSL -o "/usr/src/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz.sum256" "https://files.friendi.ca/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz.sum256"

  # Don't download already latest sources
  if [ -f "/usr/src/friendica.tar.gz.sum256" ] && \
    cmp -s "/usr/src/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz.sum256" "/usr/src/friendica.tar.gz.sum256"; then
     echo "Already latest sources - skipped download"
  else

    echo "Download sources for ${FRIENDICA_VERSION}"

    # Removing the previous sources (except config) first
    find /usr/src/friendica -mindepth 1 -maxdepth 1 ! -name 'config' -exec rm -rf {} +
    export GNUPGHOME="$(mktemp -d)"

    gpg --batch --logger-fd=1 --no-tty --quiet --keyserver keyserver.ubuntu.com --recv-keys 08656443618E6567A39524083EE197EF3F9E4287

    curl -fsSL -o friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz "https://files.friendi.ca/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz"
    curl -fsSL -o friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz.asc "https://files.friendi.ca/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz.asc";
    gpg --batch --logger-fd=1 --no-tty --quiet --verify friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz.asc friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz
    echo "Core sources (${FRIENDICA_VERSION}) verified"

    tar -xzf friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz -C /usr/src/
    rm friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz.asc
    cp -an /usr/src/friendica/config/* /usr/src/friendica-all-in-one-${FRIENDICA_VERSION}/config/    
    rm -fr /usr/src/friendica
    mv -f /usr/src/friendica-all-in-one-${FRIENDICA_VERSION}/ /usr/src/friendica
    echo "Core sources (${FRIENDICA_VERSION}) extracted"

    chmod 777 /usr/src/friendica/view/smarty3

    gpgconf --kill all
    rm -rf "$GNUPGHOME"

    mv -f /usr/src/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz.sum256 /usr/src/friendica.tar.gz.sum256
  fi
fi

exec /entrypoint.sh "$@"
