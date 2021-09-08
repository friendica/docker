# DO NOT EDIT: created by update.sh from Dockerfile-alpine.template
FROM php:7.3-fpm-alpine

# entrypoint.sh and cron.sh dependencies
RUN set -ex; \
    apk add --no-cache \
        rsync \
        git \
# For mail() support
        msmtp \
        shadow \
        tini;

ENV GOSU_VERSION 1.14
RUN set -eux; \
	\
	apk add --no-cache --virtual .gosu-deps \
		ca-certificates \
		dpkg \
		gnupg \
	; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
# verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	command -v gpgconf && gpgconf --kill all || :; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	\
# clean up fetch dependencies
	apk del --no-network .gosu-deps; \
	\
	chmod +x /usr/local/bin/gosu; \
# verify that the binary works
	gosu --version; \
	gosu nobody true

# install the PHP extensions we need
# see https://friendi.ca/resources/requirements/
RUN set -ex; \
    \
    apk add --no-cache --virtual .build-deps \
        mariadb-client \
        bash \
        $PHPIZE_DEPS \
        libpng-dev \
        libjpeg-turbo-dev \
        imagemagick-dev \
        libtool \
        libmemcached-dev \
        cyrus-sasl-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        librsvg \
        pcre-dev \
        libzip-dev \
        icu-dev \
        openldap-dev \
    ; \
    \
    docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    ; \
    \
    docker-php-ext-install -j "$(nproc)" \
        pdo_mysql \
        gd \
        zip \
        opcache \
        pcntl \
        ldap \
    ; \
    \
# pecl will claim success even if one install fails, so we need to perform each install separately
    pecl install APCu-5.1.20; \
    pecl install memcached-3.1.5; \
    pecl install redis-5.3.4; \
    pecl install imagick-3.5.1; \
    \
    docker-php-ext-enable \
        apcu \
        memcached \
        redis \
        imagick \
    ; \
    \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-network --virtual .friendica-phpext-rundeps $runDeps; \
    apk del --no-network .build-deps;

# set recommended PHP.ini settings
RUN set -ex; \
    { \
        echo 'opcache.enable=1' ; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=10000'; \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.save_comments=1'; \
        echo 'opcache.revalidte_freq=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini; \
    \
    { \
        echo sendmail_path = "/usr/bin/msmtp -t"; \
    } > /usr/local/etc/php/conf.d/sendmail.ini; \
    \
    echo 'apc.enable_cli=1' >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini; \
    \
    echo 'memory_limit=512M' > /usr/local/etc/php/conf.d/memory-limit.ini; \
    \
    mkdir /var/www/data; \
    chown -R www-data:root /var/www; \
    chmod -R g=u /var/www

VOLUME /var/www/html


ENV FRIENDICA_VERSION "2021.04"
ENV FRIENDICA_ADDONS "2021.04"
ENV FRIENDICA_DOWNLOAD_SHA256 "440d3a39cd701c3a4179f89fcb1a7197c3bf03f02c087c4a6e1bbe88932a1ce4"
ENV FRIENDICA_DOWNLOAD_ADDONS_SHA256 "6c798634ce75d25bb71c80a00fcd3b6dd48be3ca2e233ca0f9ed80981cba83af"

RUN set -ex; \
     apk add --no-cache --virtual .fetch-deps \
            gnupg \
        ; \
        \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keyserver.ubuntu.com --recv-keys 08656443618E6567A39524083EE197EF3F9E4287; \
    \
    curl -fsSL -o friendica-full-${FRIENDICA_VERSION}.tar.gz \
        "https://files.friendi.ca/friendica-full-${FRIENDICA_VERSION}.tar.gz"; \
    curl -fsSL -o friendica-full-${FRIENDICA_VERSION}.tar.gz.asc \
        "https://files.friendi.ca/friendica-full-${FRIENDICA_VERSION}.tar.gz.asc"; \
    gpg --batch --verify friendica-full-${FRIENDICA_VERSION}.tar.gz.asc friendica-full-${FRIENDICA_VERSION}.tar.gz; \
    echo "${FRIENDICA_DOWNLOAD_SHA256} *friendica-full-${FRIENDICA_VERSION}.tar.gz" | sha256sum -c; \
    tar -xzf friendica-full-${FRIENDICA_VERSION}.tar.gz -C /usr/src/; \
    rm friendica-full-${FRIENDICA_VERSION}.tar.gz friendica-full-${FRIENDICA_VERSION}.tar.gz.asc; \
    mv -f /usr/src/friendica-full-${FRIENDICA_VERSION}/ /usr/src/friendica; \
    chmod 777 /usr/src/friendica/view/smarty3; \
    \
    curl -fsSL -o friendica-addons-${FRIENDICA_ADDONS}.tar.gz \
            "https://files.friendi.ca/friendica-addons-${FRIENDICA_ADDONS}.tar.gz"; \
    curl -fsSL -o friendica-addons-${FRIENDICA_ADDONS}.tar.gz.asc \
            "https://files.friendi.ca/friendica-addons-${FRIENDICA_ADDONS}.tar.gz.asc"; \
    gpg --batch --verify friendica-addons-${FRIENDICA_ADDONS}.tar.gz.asc friendica-addons-${FRIENDICA_ADDONS}.tar.gz; \
    echo "${FRIENDICA_DOWNLOAD_ADDONS_SHA256} *friendica-addons-${FRIENDICA_ADDONS}.tar.gz" | sha256sum -c; \
    mkdir -p /usr/src/friendica/proxy; \
    mkdir -p /usr/src/friendica/addon; \
    tar -xzf friendica-addons-${FRIENDICA_ADDONS}.tar.gz -C /usr/src/friendica/addon --strip-components=1; \
    rm friendica-addons-${FRIENDICA_ADDONS}.tar.gz friendica-addons-${FRIENDICA_ADDONS}.tar.gz.asc; \
    \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME"; \
    \
    apk del .fetch-deps

COPY *.sh upgrade.exclude /
COPY config/* /usr/src/friendica/config/

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
