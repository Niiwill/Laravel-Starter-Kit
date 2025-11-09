# Base stage
FROM php:8.4-fpm-alpine AS base

RUN apk add --no-cache \
    unzip \
    libzip-dev \
    icu-dev \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        opcache \
        intl \
        zip \
        bcmath \
    && rm -rf /tmp/* /var/cache/apk/*

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www

# Development stage
FROM base AS development

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# Add custom settings for development
COPY docker/php-dev.ini "$PHP_INI_DIR/conf.d/custom.ini"

ARG USER_ID=1000
ARG GROUP_ID=1000

RUN apk add --no-cache shadow \
    && usermod -u ${USER_ID} www-data \
    && groupmod -g ${GROUP_ID} www-data \
    && chown -R www-data:www-data /var/www \
    && apk del shadow

COPY . .

RUN composer install \
    --no-interaction \
    --no-progress \
    --prefer-dist \
    --no-scripts \
    --no-autoloader

RUN composer dump-autoload --optimize

EXPOSE 9000
USER www-data
CMD ["php-fpm"]

# Production stage
FROM base AS production

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Copy composer files first
COPY composer.json composer.lock ./

# Install only production dependencies
RUN composer install \
    --optimize-autoloader \
    --no-interaction \
    --no-progress \
    --no-dev \
    --prefer-dist \
    --no-scripts \
    --no-autoloader

# Copy rest of application
COPY . .

# Generate autoloader and optimize Laravel
RUN composer dump-autoload --optimize --classmap-authoritative \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache \
    && chown -R www-data:www-data /var/www

USER www-data

EXPOSE 9000
CMD ["php-fpm"]