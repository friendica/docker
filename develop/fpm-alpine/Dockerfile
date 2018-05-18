FROM php:7.1-fpm-alpine
LABEL maintainer="Philipp Holzer <admin@philipp.info>"

ENV IMAGICK_PECL 3.4.3
ENV AUTOINSTALL false

# entrypoint.sh and cron.sh dependencies
RUN set -ex; \
    \
    apk add --no-cache \
        rsync \
        git \
    ; \
    \
    rm /var/spool/cron/crontabs/root; \
    echo '*/10 * * * * cd /var/www/html && php -f bin/worker.php' > /var/spool/cron/crontabs/www-data

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
        libmcrypt \
        libmcrypt-dev \
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
    ; \
    pecl install imagick-${IMAGICK_PECL}; \
        docker-php-ext-enable imagick; \
        pecl clear-cache; \
    docker-php-ext-configure gd \
        --with-gd \
        --enable-gd-native-ttf \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    ; \
    docker-php-ext-install -j 4 curl pdo pdo_mysql xml gd zip opcache mbstring posix ctype json iconv mcrypt; \
    \
    runDeps="$( \
      scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
          | tr ',' '\n' \
          | sort -u \
          | awk 'system("[ -e /usr/local/lib" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --virtual .friendica-phpext-rundeps $runDeps; \
    apk del .build-deps;

RUN chown -R www-data:root /var/www; \
    chmod -R g=u /var/www

VOLUME /var/www/html

ENV FRIENDICA_VERSION develop
ENV ADDONS_VERSION develop

COPY bin/* /usr/local/bin/
COPY config/* /usr/src/config/
COPY *.sh /
RUN chmod +x /*.sh
RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]