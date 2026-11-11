# Pin a major in .env (WORDPRESS_TAG=7-php8.3-fpm-alpine) for production; latest by default.
ARG WORDPRESS_TAG=php8.3-fpm-alpine
FROM wordpress:${WORDPRESS_TAG}

# Redis object cache needs the phpredis extension; opcache is already enabled.
RUN set -eux; \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS; \
    pecl install redis; \
    docker-php-ext-enable redis; \
    apk del .build-deps; \
    apk add --no-cache fcgi mariadb-client less; \
    # php-fpm healthcheck (uses the status page enabled in www.conf)
    wget -qO /usr/local/bin/php-fpm-healthcheck \
      https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/v0.5.0/php-fpm-healthcheck; \
    chmod +x /usr/local/bin/php-fpm-healthcheck; \
    # WP-CLI for the cron container and one-off tasks
    curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; \
    chmod +x /usr/local/bin/wp
