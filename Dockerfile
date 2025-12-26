# Build arguments for flexibility
ARG PHP_VERSION=8.4

# ==============================================================================
# 1. BASE: Shared foundation for all stages
# ==============================================================================
FROM php:${PHP_VERSION}-fpm-alpine AS base

# Install PHP extension installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Install system dependencies and PHP extensions in one layer
RUN apk add --no-cache \
    icu-data-full \
    fcgi \
    && install-php-extensions \
    bcmath \
    intl \
    opcache \
    pdo_mysql \
    zip \
    gd \
    exif \
    pcntl \
    redis \
    && rm -rf /tmp/* /var/cache/apk/*

WORKDIR /var/www

# ==============================================================================
# 2. BUILD: Install Dependencies (Composer)
# ==============================================================================
FROM base AS build
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy only dependency files for caching
COPY composer.json composer.lock ./

# Install without scripts or autoloader to avoid errors
RUN composer install --no-dev --no-scripts --no-autoloader --no-interaction --prefer-dist

# Copy full code now that dependencies are installed
COPY . .

# Dump autoloader, which triggers scripts safely
RUN composer dump-autoload --optimize --classmap-authoritative --no-dev

# ==============================================================================
# 3. DEVELOPMENT: Local Dev Environment
# ==============================================================================
FROM base AS development

# Install Composer for dev use
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Use the default development configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# Create a user with the same ID as your host user (avoids permission issues)
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN apk add --no-cache shadow \
    && usermod -u ${USER_ID} www-data \
    && groupmod -g ${GROUP_ID} www-data-l

# Switch to user
USER www-data

CMD ["php-fpm"]

# ==============================================================================
# 4. PRODUCTION: Lean, Secure, Optimized
# ==============================================================================
FROM base AS production

# Production PHP/OPcache settings
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY ./docker/php/opcache.ini $PHP_INI_DIR/conf.d/opcache.ini

COPY --from=build --chown=www-data:www-data /var/www /var/www

# Security: Set application root to read-only, specifically allow storage/cache
RUN chmod -R 755 /var/www && \
    chmod -R 775 /var/www/storage /var/www/bootstrap/cache
    
# Final cleanup
RUN rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

USER www-data

# Lightweight healthcheck using PHP-FPM status
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET \
    cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1

EXPOSE 9000

CMD ["php-fpm"]