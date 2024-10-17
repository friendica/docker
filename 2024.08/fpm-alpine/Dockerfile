# DO NOT EDIT: created by update.sh from Dockerfile-alpine.template
FROM php:8.2-fpm-alpine

# entrypoint.sh and cron.sh dependencies
RUN set -ex; \
    apk add --no-cache \
        rsync \
        imagemagick \
# For mail() support
        msmtp \
        shadow \
        tini;

ENV GOSU_VERSION 1.17
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
        libwebp-dev \
        librsvg \
        pcre-dev \
        libzip-dev \
        icu-dev \
        openldap-dev \
        gmp-dev \
    ; \
    \
    docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
    ; \
    \
    docker-php-ext-install -j "$(nproc)" \
        pdo_mysql \
        exif \
        gd \
        zip \
        opcache \
        pcntl \
        ldap \
        gmp \
        intl \
    ; \
    \
# pecl will claim success even if one install fails, so we need to perform each install separately
    pecl install APCu-5.1.24; \
    pecl install memcached-3.3.0; \
    pecl install redis-6.1.0; \
    pecl install imagick-3.7.0; \
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
ENV PHP_MEMORY_LIMIT 512M
ENV PHP_UPLOAD_LIMIT 512M
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
    { \
        echo 'memory_limit=${PHP_MEMORY_LIMIT}'; \
        echo 'upload_max_filesize=${PHP_UPLOAD_LIMIT}'; \
        echo 'post_max_size=${PHP_UPLOAD_LIMIT}'; \
    } > /usr/local/etc/php/conf.d/friendica.ini; \
    ln -s /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini; \
    \
    mkdir /var/www/data; \
    chown -R www-data:root /var/www; \
    chmod -R g=u /var/www

VOLUME /var/www/html


# 39 = LOG_PID | LOG_ODELAY | LOG_CONS | LOG_PERROR
ENV FRIENDICA_SYSLOG_FLAGS 39
ENV FRIENDICA_VERSION "2024.08"
ENV FRIENDICA_ADDONS "2024.08"
ENV FRIENDICA_DOWNLOAD_SHA256 "3e93178734bc82abd0c7c8b8b7c13baa4c18ae33a0f07c169518c13c4317717d"
ENV FRIENDICA_DOWNLOAD_ADDONS_SHA256 "748d399f64670e37a5afc94ef65483291c52e9374e26c0ee5235f91b55449f54"

RUN set -ex; \
     apk add --no-cache --virtual .fetch-deps \
            gnupg \
        ; \
        \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 08656443618E6567A39524083EE197EF3F9E4287; \
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
