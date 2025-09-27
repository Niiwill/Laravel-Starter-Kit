#!/bin/sh

# Laravel Docker Health Check Script

# Check if PHP-FPM is running
if ! pgrep -f "php-fpm" > /dev/null; then
    echo "PHP-FPM is not running"
    exit 1
fi

# Check if Nginx is running
if ! pgrep -f "nginx" > /dev/null; then
    echo "Nginx is not running"
    exit 1
fi

# Check if Laravel application is responding
if ! curl -f http://localhost/health > /dev/null 2>&1; then
    echo "Laravel application is not responding"
    exit 1
fi


# Check storage permissions
if [ ! -w "/var/www/html/storage" ]; then
    echo "Storage directory is not writable"
    exit 1
fi

# Check bootstrap cache permissions
if [ ! -w "/var/www/html/bootstrap/cache" ]; then
    echo "Bootstrap cache directory is not writable"
    exit 1
fi

echo "All health checks passed"
exit 0