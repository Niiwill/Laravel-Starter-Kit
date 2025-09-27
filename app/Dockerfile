# Stage 1: PHP Composer stage
FROM composer:2 AS composer-builder

WORKDIR /app
COPY . .
RUN composer install --no-scripts

# Stage 3: Production stage
FROM php:8.4-fpm-alpine


RUN apk add --no-cache \
    curl \
    libzip-dev \
    supervisor \
    oniguruma-dev \
    icu-dev \
    libxml2-dev \
    libsodium-dev \
    libpng-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    zlib-dev

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Copy and configure PHP OPCache
COPY docker/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Create application user
RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy application files
COPY --chown=appuser:appgroup . .
COPY --from=composer-builder --chown=appuser:appgroup /app/vendor ./vendor

# Set permissions
RUN chown -R appuser:appgroup /app/storage /app/bootstrap/cache && \
    chmod -R 775 /app/storage /app/bootstrap/cache


COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf


# COPY docker/healthcheck.sh /usr/local/bin/healthcheck.sh

# Make healthcheck executable
# RUN chmod +x /usr/local/bin/healthcheck.sh

# Expose port
EXPOSE 9000 

# Health check
# HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
#     CMD /usr/local/bin/healthcheck.sh

# Switch to non-root user
# USER appuser

# CMD ["php-fpm"]
CMD ["supervisord", "-c", "/app/docker/supervisord.conf"]