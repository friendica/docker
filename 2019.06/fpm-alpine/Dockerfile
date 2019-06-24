# DO NOT EDIT: created by update.sh from Dockerfile-alpine.template
FROM php:7.3-fpm-alpine
LABEL maintainer="Philipp Holzer <admin@philipp.info>"

# entrypoint.sh and cron.sh dependencies
RUN set -ex; \
    apk add --no-cache \
        rsync \
        git \
# For mail() support
        ssmtp;

# install the PHP extensions we need
# see https://friendi.ca/resources/requirements/
RUN set -ex; \
    \
    apk add -U --no-cache --virtual .build-deps \
        libxml2-dev \
        mysql-client \
        bash \
        autoconf \
        g++ \
        make \
        openssl \
        openssl-dev \
        libpng \
        libpng-dev \
        libjpeg-turbo-dev \
        imagemagick-dev \
        imagemagick \
        libtool \
        libmemcached-dev \
        cyrus-sasl-dev \
        freetype \
        libpng \
        libjpeg-turbo-dev \
        freetype-dev \
        librsvg \
        libcurl \
        curl \
        curl-dev \
        rsync \
        bzip2 \
        pcre-dev \
        libzip-dev \
    ; \
    \
    docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    ; \
    \
    docker-php-ext-install -j 4 \
       curl \
       pdo \
       pdo_mysql \
       xml \
       gd \
       zip \
       opcache \
       mbstring \
       posix \
       ctype \
       json \
       iconv \
    ; \
    \
# pecl will claim success even if one install fails, so we need to perform each install separately
    pecl install APCu-5.1.17; \
    pecl install memcached-3.1.3; \
    pecl install redis-4.3.0; \
    pecl install imagick-3.4.4; \
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
    apk add --virtual .friendica-phpext-rundeps $runDeps; \
    apk del .build-deps;

RUN {\
        echo sendmail_path = "/usr/sbin/sendmail -t -i" ;\
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


COPY *.sh upgrade.exclude /
RUN chmod +x /*.sh

ENV FRIENDICA_VERSION 2019.06
ENV FRIENDICA_ADDONS 2019.06

RUN set -ex; \
    curl -fsSL -o friendica.tar.gz \
        "https://github.com/friendica/friendica/archive/${FRIENDICA_VERSION}.tar.gz"; \
    tar -xzf friendica.tar.gz -C /usr/src/; \
    rm friendica.tar.gz; \
    mv -f /usr/src/friendica-${FRIENDICA_VERSION}/ /usr/src/friendica; \
    chmod 777 /usr/src/friendica/view/smarty3; \
    curl -fsSL -o friendica_addons.tar.gz \
        "https://github.com/friendica/friendica-addons/archive/${FRIENDICA_ADDONS}.tar.gz"; \
    mkdir -p /usr/src/friendica/proxy; \
    mkdir -p /usr/src/friendica/addon; \
    tar -xzf friendica_addons.tar.gz -C /usr/src/friendica/addon --strip-components=1; \
    rm friendica_addons.tar.gz; \
    /usr/src/friendica/bin/composer.phar install --no-dev -d /usr/src/friendica;

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
