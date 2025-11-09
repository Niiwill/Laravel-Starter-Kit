FROM php:8.4-fpm-alpine

# System dependencies
RUN apk add --no-cache unzip libzip-dev icu-dev shadow \
    && docker-php-ext-install -j$(nproc) pdo_mysql opcache intl zip bcmath \
    && rm -rf /tmp/*

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Set user ID to match host (default to 1000, can be overridden at build time)
ARG UID=1000
ARG GID=1000

# Modify www-data user to use the specified UID/GID
RUN usermod -u ${UID} www-data && groupmod -g ${GID} www-data

WORKDIR /var/www

# Copy and install as root
COPY . /var/www

RUN composer install --optimize-autoloader --no-interaction --no-progress --prefer-dist \
    && chown -R www-data:www-data /var/www

USER www-data

EXPOSE 9000
CMD ["php-fpm"]