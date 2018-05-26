# Based on .exmples/dockerfiles/smtp/apache
FROM friendica/server:apache

# simple = using an smtp without any credentials (mostly in local networks)
# custom = you need to set host, port, auth_options, authinfo (e.g. for GMX support)
ENV SMTP_TYPE simple

ENV SMTP_HOST smtp.example.org

COPY *.sh /
RUN chmod +x /*.sh
RUN /smtp-config.sh