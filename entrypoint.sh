#!/bin/sh
# entrypoint.sh

# Cache configuration using the REAL runtime env vars
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start the main process
exec "$@"