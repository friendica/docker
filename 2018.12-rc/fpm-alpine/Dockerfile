# DO NOT EDIT: created by update.sh from Dockerfile-alpine.template
FROM php:7.1-fpm-alpine
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
        libressl \
        libressl-dev \
        libpng \
        libpng-dev \
        libjpeg-turbo-dev \
        imagemagick-dev \
        imagemagick \
        libtool \
        libmcrypt \
        libmcrypt-dev \
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
    ; \
    pecl install imagick-3.4.3; \
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
# pecl will claim success even if one install fails, so we need to perform each install separately
    pecl install memcached-3.0.4; \
    pecl install redis-3.1.6; \
    \
    docker-php-ext-enable \
        memcached \
        redis \
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

RUN chown -R www-data:www-data /var/www; \
    chmod -R g=u /var/www

VOLUME /var/www/html
WORKDIR /var/www/html


RUN {\
      echo sendmail_path = "/usr/sbin/sendmail -t -i" ;\
    } > /usr/local/etc/php/conf.d/sendmail.ini;

COPY *.sh upgrade.exclude /
RUN chmod +x /*.sh

ENV FRIENDICA_VERSION 2018.12-rc
ENV FRIENDICA_ADDONS 2018.12-rc


ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
