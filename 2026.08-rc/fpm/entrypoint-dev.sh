#!/bin/sh
set -eu

curl_opts="-fsSL --retry 3 --retry-connrefused --retry-delay 10 --connect-timeout 30"

download_sources() {
  curl ${curl_opts} -o "/usr/src/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz.sum256" "https://files.friendi.ca/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz.sum256"

  # Don't download already latest sources
  if [ -f "/usr/src/friendica.tar.gz.sum256" ] && \
    cmp -s "/usr/src/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz.sum256" "/usr/src/friendica.tar.gz.sum256"; then
     echo "Already latest sources - skipped download"
  else

    echo "Download sources for ${FRIENDICA_VERSION}"

    # Removing the previous sources (except config) first
    find /usr/src/friendica -mindepth 1 -maxdepth 1 ! -name 'config' -exec rm -rf {} +
    export GNUPGHOME="$(mktemp -d)"
    trap 'gpgconf --kill all; rm -rf "$GNUPGHOME"' EXIT

    gpg --batch --logger-fd=1 --no-tty --quiet --keyserver keyserver.ubuntu.com --recv-keys 08656443618E6567A39524083EE197EF3F9E4287

    curl ${curl_opts} -o "/usr/src/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz" "https://files.friendi.ca/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz"
    curl ${curl_opts} -o "/usr/src/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz.asc" "https://files.friendi.ca/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz.asc";
    gpg --batch --logger-fd=1 --no-tty --quiet --verify "/usr/src/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz.asc" "/usr/src/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz"
    echo "Core sources (${FRIENDICA_VERSION}) verified"

    tar -xzf "/usr/src/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz" -C /usr/src/
    rm "/usr/src/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz" "/usr/src/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz.asc"
    cp -an /usr/src/friendica/config/* /usr/src/friendica-all-in-one-${FRIENDICA_VERSION}/config/
    rm -fr /usr/src/friendica
    mv -f /usr/src/friendica-all-in-one-${FRIENDICA_VERSION}/ /usr/src/friendica
    echo "Core sources (${FRIENDICA_VERSION}) extracted"

    chmod 777 /usr/src/friendica/view/smarty3

    mv -f /usr/src/friendica-all-in-one-${FRIENDICA_VERSION}.tar.gz.sum256 /usr/src/friendica.tar.gz.sum256
  fi
}

# just check if we execute apache or php-fpm
if (expr "$1" : "apache" 1>/dev/null || [ "$1" = "php-fpm" ]) && [ "${FRIENDICA_UPGRADE:-false}" = "true" ]; then
  # Run in a subshell outside of a condition, so "set -e" still aborts on the first failing step
  set +e
  (set -e; download_sources)
  status=$?
  set -e

  if [ "$status" -ne 0 ]; then
    if [ -f /var/www/html/VERSION ]; then
      echo "Downloading the sources for ${FRIENDICA_VERSION} failed, keeping installed Friendica $(cat /var/www/html/VERSION)"
      export FRIENDICA_UPGRADE=false
    else
      echo "Downloading the sources for ${FRIENDICA_VERSION} failed and no Friendica is installed"
      exit "$status"
    fi
  fi
fi

exec /entrypoint.sh "$@"
