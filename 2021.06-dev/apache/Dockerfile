# DO NOT EDIT: created by update.sh from Dockerfile-debian.template
FROM php:7.3-apache-buster

# entrypoint.sh and cron.sh dependencies
RUN set -ex; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        rsync \
        bzip2 \
        git \
# For mail() support
        msmtp \
# For tini installation
        gnupg dirmngr \
    ; \
    rm -rf /var/lib/apt/lists/*;

# Add tini for reaping processes
ENV TINI_VERSION v0.19.0
RUN export BUILD_ARCH=$(dpkg-architecture --query DEB_BUILD_ARCH) \
 && mkdir ~/.gnupg \
 && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
 && curl -L -o /sbin/tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-${BUILD_ARCH} \
 && curl -L -o /tini.asc https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-${BUILD_ARCH}.asc \
 && gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
 && gpg --batch --verify /tini.asc /sbin/tini \
 && chmod +x /sbin/tini

# install the PHP extensions we need
# see https://friendi.ca/resources/requirements/
RUN set -ex; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        mariadb-client \
        bash \
        libpng-dev \
        libjpeg62-turbo-dev \
        libtool \
        libmagick++-dev \
        libmemcached-dev \
        libgraphicsmagick1-dev \
        libfreetype6-dev \
        librsvg2-2 \
        libzip-dev \
        libldap2-dev \
    ; \
    \
        debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
    \
    docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    ; \
    docker-php-ext-configure ldap \
        --with-libdir=lib/$debMultiarch/ \
    ;\
    docker-php-ext-install -j "$(nproc)" \
        pdo_mysql \
        gd \
        zip \
        opcache \
        ctype \
        pcntl \
        ldap \
    ; \
    \
# pecl will claim success even if one install fails, so we need to perform each install separately
    pecl install apcu-5.1.20; \
    pecl install memcached-3.1.5; \
    pecl install redis-5.3.4; \
    pecl install imagick-3.5.0; \
    \
    docker-php-ext-enable \
        apcu \
        memcached \
        redis \
        imagick \
    ; \
    \
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

RUN set -ex;\
    a2enmod rewrite remoteip ;\
    {\
     echo RemoteIPHeader X-Real-IP ;\
     echo RemoteIPTrustedProxy 10.0.0.0/8 ;\
     echo RemoteIPTrustedProxy 172.16.0.0/12 ;\
     echo RemoteIPTrustedProxy 192.168.0.0/16 ;\
    } > /etc/apache2/conf-available/remoteip.conf;\
    a2enconf remoteip

ENV FRIENDICA_VERSION "2021.06-dev"
ENV FRIENDICA_ADDONS "2021.06-dev"


COPY *.sh upgrade.exclude /
COPY config/* /usr/src/friendica/config/

ENTRYPOINT ["/entrypoint-dev.sh"]
CMD ["apache2-foreground"]
