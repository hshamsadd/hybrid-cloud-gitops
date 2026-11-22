FROM docker.io/wallabag/wallabag:2.6.18

USER root

# Configure nginx for unprivileged execution.
RUN set -eu; \
    sed -i \
      -e '/^user[[:space:]]/d' \
      -e 's|pid[[:space:]]*/var/run/nginx.pid;|pid /tmp/nginx.pid;|' \
      -e 's|:80 ipv6only=off|:8080 ipv6only=off|' \
      -e 's|/var/log/nginx/access.log|/dev/stdout|g' \
      -e 's|/var/log/nginx/error.log|/dev/stderr|g' \
      /etc/nginx/nginx.conf; \
    rm -f /etc/nginx/http.d/default.conf; \
    sed -i '/^http {/a\
    client_body_temp_path /tmp/nginx-client;\
    proxy_temp_path /tmp/nginx-proxy;\
    fastcgi_temp_path /tmp/nginx-fastcgi;\
    uwsgi_temp_path /tmp/nginx-uwsgi;\
    scgi_temp_path /tmp/nginx-scgi;' \
      /etc/nginx/nginx.conf; \
    sed -i \
      's|^error_log = .*|error_log = /proc/self/fd/2|' \
      /etc/php83/php-fpm.conf; \
    printf 'memory_limit = 512M\n' \
      > /etc/php83/conf.d/50_wallabag.ini; \
    chown -R 65534:65534 \
      /etc/s6 \
      /var/www/wallabag/app/config \
      /var/www/wallabag/var
      
# Route nginx diagnostics to stderr for non-root execution.
RUN sed -i \
      's|^[[:space:]]*error_log off;|    error_log /dev/stderr warn;|' \
      /etc/nginx/nginx.conf \
    && sed -i \
      's|exec nginx -c|exec nginx -e /dev/stderr -c|' \
      /etc/s6/nginx/run

COPY --chown=65534:65534 entrypoint.sh /usr/local/bin/wallabag-rootless

RUN chmod 0755 /usr/local/bin/wallabag-rootless

USER 65534:65534

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/wallabag-rootless"]
