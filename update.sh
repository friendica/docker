#!/bin/bash
set -eo pipefail

declare -A php_version=(
  [default]='7.3'
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
  ['stable']='\nRUN set -ex; \\\n    curl -fsSL -o friendica.tar.gz \\\n        "https://github.com/friendica/friendica/releases/download/${FRIENDICA_VERSION}/friendica-full-${FRIENDICA_VERSION}.tar.gz"; \\\n    tar -xzf friendica.tar.gz -C /usr/src/; \\\n    rm friendica.tar.gz; \\\n    mv -f /usr/src/friendica-full-${FRIENDICA_VERSION}/ /usr/src/friendica; \\\n    chmod 777 /usr/src/friendica/view/smarty3; \\\n    curl -fsSL -o friendica_addons.tar.gz \\\n        "https://github.com/friendica/friendica-addons/archive/${FRIENDICA_ADDONS}.tar.gz"; \\\n    mkdir -p /usr/src/friendica/proxy; \\\n    mkdir -p /usr/src/friendica/addon; \\\n    tar -xzf friendica_addons.tar.gz -C /usr/src/friendica/addon --strip-components=1; \\\n    rm friendica_addons.tar.gz;'
  ['develop']=''
)

variants=(
  apache
  fpm
  fpm-alpine
)

versions=(
  2020.07
  2020.09-dev
)

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
    s/%%VERSION%%/'"$1"'/g;
    s/%%CMD%%/'"${cmd[$variant]}"'/g;
    s|%%VARIANT_EXTRAS%%|'"${extras[$variant]}"'|g;
    s|%%INSTALL_EXTRAS%%|'"${install_extras[$install_type]}"'|g;
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

find . -maxdepth 1 -type d -regextype sed -regex '\./[[:digit:]]\+\(\.\|\-\)[[:digit:]]\+\(-rc\|-dev\)\?' -exec rm -r '{}' \;

for version in "${versions[@]}"; do
  for variant in "${variants[@]}"; do

    create_variant "$version"
  done
done
