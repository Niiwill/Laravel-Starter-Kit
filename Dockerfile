FROM dunglas/frankenphp

# Set working directory
WORKDIR /app

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/* \
    && install-php-extensions \
    pcntl \
    zip \
    pdo \
    pdo_mysql
    

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Copy application code
COPY . .

# Install PHP dependencies (production only)
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

ENTRYPOINT ["php", "artisan", "octane:frankenphp", "--workers=1", "--max-requests=1"]
