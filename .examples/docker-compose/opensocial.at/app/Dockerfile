FROM friendica:fpm-alpine

ENV FRIENDICA_UPGRADE=true
ENV PHP_MEMORY_LIMIT 2G

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

ENV FRIENDICA_PHP_OUT="/var/www/html/php.out"

RUN set -ex; \
  touch ${FRIENDICA_PHP_OUT:-"php.out"}; \
  chown www-data:www-data ${FRIENDICA_PHP_OUT:-"php.out"};

RUN sed -i 's/access.log = \/proc\/self\/fd\/2/access.log = \/proc\/self\/fd\/1/g' /usr/local/etc/php-fpm.d/docker.conf
