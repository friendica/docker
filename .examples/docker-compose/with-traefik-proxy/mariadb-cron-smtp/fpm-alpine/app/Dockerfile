# Based on .exmples/dockerfiles/smtp/fpm-alpine
FROM friendica/server:fpm-alpine

ENV SMTP_HOST smtp.example.org

RUN set -ex; \
    \
    apk add --no-cache \
        ssmtp \
    ; \
    # disable the current mailhub
    sed -i "s|mailhub=|#mailhub= |g" /etc/ssmtp/ssmtp.conf; \
    # enable the new mailhub
    echo "mailhub=${SMTP_HOST:-localhost}" >> /etc/ssmtp/ssmtp.conf;

# simple = using an smtp without any credentials (mostly in local networks)
# custom = you need to set host, port, auth_options, authinfo (e.g. for GMX support)
ENV SMTP_TYPE simple