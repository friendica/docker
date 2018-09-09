FROM friendica/server:fpm-alpine

RUN set -ex; \
    apk add --no-cache \
 # For mail() support
        ssmtp;

ENV SMTP localhost
ENV SMTP_FROM no-reply

ENV SITENAME "Testsite"

# Setup SSMTP
RUN sed -i "s/:root:/:${SITENAME}:/g" /etc/passwd ;\
	sed -i "s/:Linux\ User:/:${SITENAME}:/g" /etc/passwd ;\
# add possible mail-senders
	{\
	 echo "www-data:$SMTP_FROM@$HOSTNAME:$SMTP" ;\
	 echo "root:$SMTP_FROM@$HOSTNAME:$SMTP" ;\
	} > /etc/ssmtp/revaliases;\
# replace ssmtp.conf settings
	{\
     echo "root=$SMTP_FROM@$HOSTNAME" ;\
     echo "hostname=$HOSTNAME" ;\
     echo "mailhub=$SMTP" ;\
     echo "FromLineOverride=YES" ;\
     [ -z "$SMTP_TLS" ] || echo "UseTLS=$SMTP_TLS" ;\
     [ -z "$SMTP_STARTTLS" ] || echo "UseSTARTTLS=$SMTP_STARTTLS" ;\
     [ -z "$SMTP_AUTH_USER" ] || echo "AuthUser=$SMTP_AUTH_USER" ;\
     [ -z "$SMTP_AUTH_PASS" ] || echo "AuthPass=$SMTP_AUTH_PASS" ;\
     [ -z "$SMTP_AUTH_METHOD" ] || echo "AuthMethod=$SMTP_AUTH_METHOD" ;\
    } > /etc/ssmtp/ssmtp.conf;
