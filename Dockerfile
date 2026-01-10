# Global ARG for version consistency
ARG PHP_VERSION=8.4
FROM mlocati/php-extension-installer:latest AS php-extension-installer

# ==============================================================================
# 1. BASE: Minimal OS with PHP and core extensions
# ==============================================================================
FROM php:${PHP_VERSION}-fpm-alpine AS base

# System-level dependencies and Extension Installer
COPY --from=php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Install PHP extensions required for Laravel 12 APIs
RUN apk add --no-cache icu-data-full \
    && install-php-extensions \
    bcmath \
    intl \
    opcache \
    pdo_mysql \
    zip \
    pcntl \
    redis \
    sodium \
    exif

WORKDIR /var/www

# ==============================================================================
# 2. VENDOR: Focused dependency installation
# ==============================================================================
FROM composer:2 AS vendor

WORKDIR /var/www

COPY composer.json composer.lock ./

RUN composer install \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --no-interaction \
    --prefer-dist

# ==============================================================================
# 3. DEVELOPMENT: Built for local DX
# ==============================================================================
FROM base AS development

# Bring in Composer for local package management
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Use development INI settings
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# Map user/group IDs to host to prevent permission headaches in volumes
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN apk add --no-cache shadow \
    && usermod -u ${USER_ID} www-data \
    && groupmod -g ${GROUP_ID} www-data

USER www-data

EXPOSE 9000
CMD ["php-fpm"]

# ==============================================================================
# 4. PRODUCTION: Immutable, Hardened, and Fast
# ==============================================================================
FROM base AS production

# Production PHP settings
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Optimized OPcache & JIT Configuration
COPY ./docker/opcache.ini $PHP_INI_DIR/conf.d/opcache.ini

# Enable PHP-FPM built-in ping + status + install fcgi (Alpine)
RUN sed -i 's/;ping\.path = \/ping/ping.path = \/ping/' /usr/local/etc/php-fpm.d/www.conf && \
    apk add --no-cache fcgi

# 1. Copy dependencies from vendor stage
COPY --from=vendor /var/www/vendor /var/www/vendor

# 2. Copy application code
COPY . .

# 3. Final Composer optimization (no-dev)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN composer dump-autoload --optimize --classmap-authoritative --no-dev \
    && rm /usr/bin/composer

# 4. Hardened Permissions: 
# Root owns the code (read-only for www-data), www-data owns the writable paths
RUN chown -R root:root /var/www \
    && chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache \
    && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

USER www-data

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET \
    cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1

EXPOSE 9000
CMD ["php-fpm"]