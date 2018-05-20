FROM friendica:develop-fpm-alpine

RUN set -ex; \
    \
    apk add --no-cache \
        ssmtp \
    ; \
    # disable the current mailhub
    sed -i "s|mailhub=|#mailhub= |g" /etc/ssmtp/ssmtp.conf; \
    # enable the new mailhub
    echo "mailhub=${:-localhost}" >> /etc/ssmtp/ssmtp.conf;SMTP_HOST

# simple = using an smtp without any credentials (mostly in local networks)
# custom = you need to set host, port, auth_options, authinfo (e.g. for GMX support)
ENV SMTP_TYPE simple