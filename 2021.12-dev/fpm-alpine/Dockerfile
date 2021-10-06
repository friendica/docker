# DO NOT EDIT: created by update.sh from Dockerfile-alpine.template
FROM php:7.3-fpm-alpine

# entrypoint.sh and cron.sh dependencies
RUN set -ex; \
    apk add --no-cache \
        rsync \
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


ENV FRIENDICA_VERSION "2021.12-dev"
ENV FRIENDICA_ADDONS "2021.12-dev"

RUN set -ex; \
     apk add --no-cache --virtual .fetch-deps \
            gnupg \
        ;

COPY *.sh upgrade.exclude /
COPY config/* /usr/src/friendica/config/

ENTRYPOINT ["/entrypoint-dev.sh"]
CMD ["php-fpm"]
