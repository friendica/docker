#!/bin/bash
set -eo pipefail

declare -A php_version=(
  [default]='8.1'
)

declare -A cmd=(
  [apache]='apache2-foreground'
  [fpm]='php-fpm'
  [fpm-alpine]='php-fpm'
)

declare -A base=(
  [apache]='debian'
  [fpm]='debian'
  [fpm-alpine]='alpine'
)

declare -A extras=(
  [apache]='\nRUN set -ex;\\\n    a2enmod rewrite remoteip ;\\\n    {\\\n     echo RemoteIPHeader X-Real-IP ;\\\n     echo RemoteIPTrustedProxy 10.0.0.0/8 ;\\\n     echo RemoteIPTrustedProxy 172.16.0.0/12 ;\\\n     echo RemoteIPTrustedProxy 192.168.0.0/16 ;\\\n    } > /etc/apache2/conf-available/remoteip.conf;\\\n    a2enconf remoteip'
  [fpm]=''
  [fpm-alpine]=''
)

declare -A entrypoints=(
  [stable]='entrypoint.sh'
  [develop]='entrypoint-dev.sh'
)

# Only for debian variant
tini_version="$(
  git ls-remote --tags https://github.com/krallin/tini.git \
    | cut -d/ -f3 \
    | grep -vE -- '.pre' \
    | sed -E 's/^v//' \
    | sort -V \
    | tail -1
)"

apcu_version="$(
  git ls-remote --tags https://github.com/krakjoe/apcu.git \
    | cut -d/ -f3 \
    | grep -vE -- '-rc|-b' \
    | sed -E 's/^v//' \
    | sort -V \
    | tail -1
)"

memcached_version="$(
  git ls-remote --tags https://github.com/php-memcached-dev/php-memcached.git \
    | cut -d/ -f3 \
    | grep -vE -- '-rc|-b' \
    | sed -E 's/^[rv]//' \
    | sort -V \
    | tail -1
)"

redis_version="$(
  git ls-remote --tags https://github.com/phpredis/phpredis.git \
    | cut -d/ -f3 \
    | grep -viE '[a-z]' \
    | tr -d '^{}' \
    | sort -V \
    | tail -1
)"

imagick_version="$(
  git ls-remote --tags https://github.com/mkoppanen/imagick.git \
    | cut -d/ -f3 \
    | grep -viE '[a-z]' \
    | tr -d '^{}' \
    | sort -V \
    | tail -1
)"

declare -A pecl_versions=(
  [APCu]="$apcu_version"
  [memcached]="$memcached_version"
  [redis]="$redis_version"
  [imagick]="$imagick_version"
)

declare -A install_extras=(
  ['stable-debian']='\nRUN set -ex; \\\n    fetchDeps=" \\\n        gnupg \\\n    "; \\\n    apt-get update; \\\n    apt-get install -y --no-install-recommends $fetchDeps; \\\n    \\\n    export GNUPGHOME="$(mktemp -d)"; \\\n    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 08656443618E6567A39524083EE197EF3F9E4287; \\\n    \\\n    curl -fsSL -o friendica-full-${FRIENDICA_VERSION}.tar.gz \\\n        "https://files.friendi.ca/friendica-full-${FRIENDICA_VERSION}.tar.gz"; \\\n    curl -fsSL -o friendica-full-${FRIENDICA_VERSION}.tar.gz.asc \\\n        "https://files.friendi.ca/friendica-full-${FRIENDICA_VERSION}.tar.gz.asc"; \\\n    gpg --batch --verify friendica-full-${FRIENDICA_VERSION}.tar.gz.asc friendica-full-${FRIENDICA_VERSION}.tar.gz; \\\n    echo "${FRIENDICA_DOWNLOAD_SHA256} *friendica-full-${FRIENDICA_VERSION}.tar.gz" \| sha256sum -c; \\\n    tar -xzf friendica-full-${FRIENDICA_VERSION}.tar.gz -C /usr/src/; \\\n    rm friendica-full-${FRIENDICA_VERSION}.tar.gz friendica-full-${FRIENDICA_VERSION}.tar.gz.asc; \\\n    mv -f /usr/src/friendica-full-${FRIENDICA_VERSION}/ /usr/src/friendica; \\\n    chmod 777 /usr/src/friendica/view/smarty3; \\\n    \\\n    curl -fsSL -o friendica-addons-${FRIENDICA_ADDONS}.tar.gz \\\n            "https://files.friendi.ca/friendica-addons-${FRIENDICA_ADDONS}.tar.gz"; \\\n    curl -fsSL -o friendica-addons-${FRIENDICA_ADDONS}.tar.gz.asc \\\n            "https://files.friendi.ca/friendica-addons-${FRIENDICA_ADDONS}.tar.gz.asc"; \\\n    gpg --batch --verify friendica-addons-${FRIENDICA_ADDONS}.tar.gz.asc friendica-addons-${FRIENDICA_ADDONS}.tar.gz; \\\n    echo "${FRIENDICA_DOWNLOAD_ADDONS_SHA256} *friendica-addons-${FRIENDICA_ADDONS}.tar.gz" \| sha256sum -c; \\\n    mkdir -p /usr/src/friendica/proxy; \\\n    mkdir -p /usr/src/friendica/addon; \\\n    tar -xzf friendica-addons-${FRIENDICA_ADDONS}.tar.gz -C /usr/src/friendica/addon --strip-components=1; \\\n    rm friendica-addons-${FRIENDICA_ADDONS}.tar.gz friendica-addons-${FRIENDICA_ADDONS}.tar.gz.asc; \\\n    \\\n    gpgconf --kill all; \\\n    rm -rf "$GNUPGHOME"; \\\n    \\\n    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps; \\\n    rm -rf /var/lib/apt/lists/*\n'
  ['stable-alpine']='\nRUN set -ex; \\\n     apk add --no-cache --virtual .fetch-deps \\\n            gnupg \\\n        ; \\\n        \\\n    export GNUPGHOME="$(mktemp -d)"; \\\n    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 08656443618E6567A39524083EE197EF3F9E4287; \\\n    \\\n    curl -fsSL -o friendica-full-${FRIENDICA_VERSION}.tar.gz \\\n        "https://files.friendi.ca/friendica-full-${FRIENDICA_VERSION}.tar.gz"; \\\n    curl -fsSL -o friendica-full-${FRIENDICA_VERSION}.tar.gz.asc \\\n        "https://files.friendi.ca/friendica-full-${FRIENDICA_VERSION}.tar.gz.asc"; \\\n    gpg --batch --verify friendica-full-${FRIENDICA_VERSION}.tar.gz.asc friendica-full-${FRIENDICA_VERSION}.tar.gz; \\\n    echo "${FRIENDICA_DOWNLOAD_SHA256} *friendica-full-${FRIENDICA_VERSION}.tar.gz" \| sha256sum -c; \\\n    tar -xzf friendica-full-${FRIENDICA_VERSION}.tar.gz -C /usr/src/; \\\n    rm friendica-full-${FRIENDICA_VERSION}.tar.gz friendica-full-${FRIENDICA_VERSION}.tar.gz.asc; \\\n    mv -f /usr/src/friendica-full-${FRIENDICA_VERSION}/ /usr/src/friendica; \\\n    chmod 777 /usr/src/friendica/view/smarty3; \\\n    \\\n    curl -fsSL -o friendica-addons-${FRIENDICA_ADDONS}.tar.gz \\\n            "https://files.friendi.ca/friendica-addons-${FRIENDICA_ADDONS}.tar.gz"; \\\n    curl -fsSL -o friendica-addons-${FRIENDICA_ADDONS}.tar.gz.asc \\\n            "https://files.friendi.ca/friendica-addons-${FRIENDICA_ADDONS}.tar.gz.asc"; \\\n    gpg --batch --verify friendica-addons-${FRIENDICA_ADDONS}.tar.gz.asc friendica-addons-${FRIENDICA_ADDONS}.tar.gz; \\\n    echo "${FRIENDICA_DOWNLOAD_ADDONS_SHA256} *friendica-addons-${FRIENDICA_ADDONS}.tar.gz" \| sha256sum -c; \\\n    mkdir -p /usr/src/friendica/proxy; \\\n    mkdir -p /usr/src/friendica/addon; \\\n    tar -xzf friendica-addons-${FRIENDICA_ADDONS}.tar.gz -C /usr/src/friendica/addon --strip-components=1; \\\n    rm friendica-addons-${FRIENDICA_ADDONS}.tar.gz friendica-addons-${FRIENDICA_ADDONS}.tar.gz.asc; \\\n    \\\n    gpgconf --kill all; \\\n    rm -rf "$GNUPGHOME"; \\\n    \\\n    apk del .fetch-deps\n'
  ['develop-debian']='RUN set -ex; \\\n    fetchDeps=" \\\n        gnupg \\\n    "; \\\n    apt-get update; \\\n    apt-get install -y --no-install-recommends $fetchDeps;\n'
  ['develop-alpine']='RUN set -ex; \\\n     apk add --no-cache --virtual .fetch-deps \\\n            gnupg \\\n        ;\n'
)

variants=(
  apache
  fpm
  fpm-alpine
)

min_version='2024.08'

# version_greater_or_equal A B returns whether A >= B
function version_greater_or_equal() {
	[[ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" || "$1" == "$2" ]];
}

function is_hotfix() {
  [[ "$1" =~ ^.*-[[:digit:]]+$ ]]
}

function get_sha256_string() {
  install_type="$1"
  version="${2,,}"
  if [[ $install_type == "develop" ]]; then
    echo ""
  else
    echo "ENV FRIENDICA_DOWNLOAD_SHA256 \"$(curl -fsSL https://files.friendi.ca/friendica-full-${version}.tar.gz.sum256 | cut -d' ' -f1)\"\nENV FRIENDICA_DOWNLOAD_ADDONS_SHA256 \"$(curl -fsSL https://files.friendi.ca/friendica-addons-${version}.tar.gz.sum256 | cut -d' ' -f1)\""
  fi
}

function create_variant() {
  dockerName=${1,,}
  dir="$dockerName/$variant"

  # Create the version+variant directory with a Dockerfile.
  mkdir -p "$dir"

  template="Dockerfile-${base[$variant]}.template"
  echo "# DO NOT EDIT: created by update.sh from $template" > "$dir/Dockerfile"
  cat "$template" >> "$dir/Dockerfile"

  # Check which installation typ we need. If develop, the source will get downloaded by git.
  install_type='stable'
  if [[ "${1,,}" == *-dev ]] || [[ "${1,,}" == *-rc ]]; then
    install_type='develop'
  fi

  echo "updating $1 [$install_type] $variant"

  # Replace the variables.
  sed -ri -e '
    s/%%PHP_VERSION%%/'"${php_version[$version]-${php_version[default]}}"'/g;
    s/%%VARIANT%%/'"$variant"'/g;
    s/%%VERSION%%/'"${2:-${1}}"'/g;
    s/%%CMD%%/'"${cmd[$variant]}"'/g;
    s|%%VARIANT_EXTRAS%%|'"${extras[$variant]}"'|g;
    s|%%DOWNLOAD_SHA256%%|'"$(get_sha256_string $install_type ${2:-${1}})"'|g;
    s|%%INSTALL_EXTRAS%%|'"${install_extras[$install_type-${base[$variant]}]}"'|g;
    s/%%APCU_VERSION%%/'"${pecl_versions[APCu]}"'/g;
    s/%%IMAGICK_VERSION%%/'"${pecl_versions[imagick]}"'/g;
    s/%%MEMCACHED_VERSION%%/'"${pecl_versions[memcached]}"'/g;
    s/%%REDIS_VERSION%%/'"${pecl_versions[redis]}"'/g;
    s/%%ENTRYPOINT%%/'"${entrypoints[$install_type]}"'/g;
    s/%%TINI_VERSION%%/'"${tini_version}"'/g;
  ' "$dir/Dockerfile"

  for name in entrypoint cron setup_msmtp; do
    cp "docker-$name.sh" "$dir/$name.sh"
  done

  if [[ $install_type == "develop" ]]; then
    cp "docker-entrypoint-dev.sh" "$dir/entrypoint-dev.sh"
  fi

  cp upgrade.exclude "$dir/"

  cp -rT .config "$dir/config"
}

# latest, stable version (just save the major version, not every hotfix)
latest_version=( $(curl -fsSL 'https://files.friendi.ca/' |tac|tac| \
	grep -oE 'friendica-full-[[:digit:]]+\.[[:digit:]]+(\-[[:digit:]]+){0,1}\.tar\.gz' | \
	grep -oE '[[:digit:]]+\.[[:digit:]]+' | \
	sort -uV | \
	tail -1) )
 echo $latest_version > latest.txt

curl -fsSl 'https://raw.githubusercontent.com/friendica/friendica/develop/VERSION' > develop.txt

find . -maxdepth 1 -type d -regextype sed -regex '\./[[:digit:]]\+\(\.\|\-\)[[:digit:]]\+\(-rc\|-dev\|\-[[:digit:]]\)\?' -exec rm -r '{}' \;

fullversions=( $( curl -fsSL 'https://files.friendi.ca/' |tac|tac| \
	grep -oE 'friendica-full-[[:digit:]]+\.[[:digit:]]+(\-[[:digit:]]+){0,1}\.tar\.gz' | \
	grep -oE '[[:digit:]]+\.[[:digit:]]+(\-[[:digit:]]+){0,1}' | \
	sort -urV ) )
for version in "${fullversions[@]}"; do
  # hotfixes are just for Version ENV in the Dockerfile
  if is_hotfix "$version"; then
    continue;
  fi

  fullversion="$( printf '%s\n' "${fullversions[@]}" | grep -E "^$version" | sort -urV | head -1 )"

	if version_greater_or_equal "$fullversion" "$min_version"; then
    for variant in "${variants[@]}"; do

      create_variant "$version" "$fullversion"
    done
  fi
done

githubversions_rc=( $( git ls-remote --heads -q 'https://github.com/friendica/friendica' | \
  grep -oE '[[:digit:]]+\.[[:digit:]]+\-rc' || true | \
  sort -urV ) )
versions_rc=( $( printf '%s\n' "${githubversions_rc[@]}" | cut -d. -f1-2 | sort -urV ) )
for version in "${versions_rc[@]}"; do
	if version_greater_or_equal "$version" "$latest_version"; then
    for variant in "${variants[@]}"; do

      create_variant "$version"
    done
  fi
done

for variant in "${variants[@]}"; do
  create_variant "$(cat develop.txt)"
done
