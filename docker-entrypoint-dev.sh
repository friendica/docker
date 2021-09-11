#!/bin/sh
set -eu

# just check if we execute apache or php-fpm
if (expr "$1" : "apache" 1>/dev/null || [ "$1" = "php-fpm" ]) && [ "${FRIENDICA_DISABLE_UPGRADE:-false}" = "false" ]; then
  echo "Download sources for ${FRIENDICA_VERSION} (Addon: ${FRIENDICA_ADDONS})"

  # Removing the whole directory first
  rm -fr /usr/src/friendica
  export GNUPGHOME="$(mktemp -d)"

  gpg --batch --logger-fd=1 --no-tty --quiet --keyserver keyserver.ubuntu.com --recv-keys 08656443618E6567A39524083EE197EF3F9E4287

  curl -fsSL -o friendica-full-${FRIENDICA_VERSION}.tar.gz "https://files.friendi.ca/friendica-full-${FRIENDICA_VERSION}.tar.gz"
  curl -fsSL -o friendica-full-${FRIENDICA_VERSION}.tar.gz.asc "https://files.friendi.ca/friendica-full-${FRIENDICA_VERSION}.tar.gz.asc";
  gpg --batch --logger-fd=1 --no-tty --quiet --verify friendica-full-${FRIENDICA_VERSION}.tar.gz.asc friendica-full-${FRIENDICA_VERSION}.tar.gz
  echo "Core sources (${FRIENDICA_VERSION}) verified"

  tar -xzf friendica-full-${FRIENDICA_VERSION}.tar.gz -C /usr/src/
  rm friendica-full-${FRIENDICA_VERSION}.tar.gz friendica-full-${FRIENDICA_VERSION}.tar.gz.asc
  mv -f /usr/src/friendica-full-${FRIENDICA_VERSION}/ /usr/src/friendica
  echo "Core sources (${FRIENDICA_VERSION}) extracted"

  chmod 777 /usr/src/friendica/view/smarty3

  curl -fsSL -o friendica-addons-${FRIENDICA_ADDONS}.tar.gz "https://files.friendi.ca/friendica-addons-${FRIENDICA_ADDONS}.tar.gz"
  curl -fsSL -o friendica-addons-${FRIENDICA_ADDONS}.tar.gz.asc "https://files.friendi.ca/friendica-addons-${FRIENDICA_ADDONS}.tar.gz.asc"
  gpg --batch --logger-fd=1 --no-tty --quiet --verify friendica-addons-${FRIENDICA_ADDONS}.tar.gz.asc friendica-addons-${FRIENDICA_ADDONS}.tar.gz
  echo "Addon sources (${FRIENDICA_ADDONS}) verified"

  mkdir -p /usr/src/friendica/addon
  tar -xzf friendica-addons-${FRIENDICA_ADDONS}.tar.gz -C /usr/src/friendica/addon --strip-components=1
  rm friendica-addons-${FRIENDICA_ADDONS}.tar.gz friendica-addons-${FRIENDICA_ADDONS}.tar.gz.asc
  echo "Addon sources (${FRIENDICA_ADDONS}) extracted"

  gpgconf --kill all
  rm -rf "$GNUPGHOME"
fi

exec /entrypoint.sh "$@"
