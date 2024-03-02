FROM nginx:latest

RUN usermod -u 82 www-data

RUN set -ex; \
    mkdir -p /var/www/html; \
    mkdir -p /etc/nginx/snippets;

COPY ./templates /etc/nginx/conf.d/templates
COPY nginx.conf /etc/nginx/nginx.conf

COPY error-page.html /var/www/html/error-page.html
COPY custom-error-page.conf /etc/nginx/snippets/custom-error-page.conf

COPY *.sh /
RUN chmod +x /*.sh

CMD ["/cmd.sh"]
