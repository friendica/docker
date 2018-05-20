FROM php:7.1-fpm
LABEL maintainer="Philipp Holzer <admin@philipp.info>"

ENV IMAGICK_PECL 3.4.3
ENV AUTOINSTALL false

# entrypoint.sh and cron.sh dependencies
RUN set -ex; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        rsync \
        bzip2 \
        busybox-static \
        git \
# For mail() support
        sendmail \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    \
    mkdir -p /var/spool/cron/crontabs; \
    echo '*/10 * * * * cd /var/www/html && php -f bin/worker.php' > /var/spool/cron/crontabs/www-data

# install the PHP extensions we need
# see https://friendi.ca/resources/requirements/
RUN set -ex; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libxml2-dev \
        mysql-client \
        bash \
        autoconf \
        g++ \
        make \
        openssl \
        libssl-dev \
        libpng12-0 \
        libpng12-dev \
        libjpeg62-turbo-dev \
        libtool \
        libmcrypt4 \
        libmcrypt-dev \
        imagemagick \
        libmagick++-dev \
        libgraphicsmagick1-dev \
        libfreetype6 \
        libfreetype6-dev \
        librsvg2-2 \
        libcurl4-openssl-dev \
        curl \
    ; \
    \
    debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
    pecl install imagick-${IMAGICK_PECL}; \
        docker-php-ext-enable imagick; \
        pecl clear-cache \
    ; \
    docker-php-ext-configure gd \
        --with-gd \
        --enable-gd-native-ttf \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    ; \
    docker-php-ext-install -j 4 curl pdo pdo_mysql xml gd zip opcache mbstring posix ctype json iconv mcrypt \
    ; \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
      | awk '/=>/ { print $3 }' \
      | sort -u \
      | xargs -r dpkg-query -S \
      | cut -d: -f1 \
      | sort -u \
      | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

RUN chown -R www-data:root /var/www; \
    chmod -R g=u /var/www

VOLUME /var/www/html

RUN {\
      echo sendmail_path = "/usr/sbin/sendmail -t -i" ;\
    } > /usr/local/etc/php/conf.d/sendmail.ini;

ENV FRIENDICA_VERSION develop
ENV ADDONS_VERSION develop

COPY config/* /usr/src/config/
COPY *.sh /
RUN chmod +x /*.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]