FROM nginx:latest

RUN usermod -u 82 www-data

COPY ./templates /etc/nginx/conf.d/templates
COPY nginx.conf /etc/nginx/nginx.conf

COPY *.sh /
RUN chmod +x /*.sh

CMD ["/cmd.sh"]
