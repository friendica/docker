FROM friendica/server:apache

ENV AUTOINSTALL true
ENV MARIADB_VERSION 10.3

RUN set -ex; \
    ; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        supervisor \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir /var/log/supervisord /var/run/supervisord

COPY ./supervisord.conf /etc/supervisor/supervisord.conf

CMD ["/usr/bin/supervisord"]