#!/usr/bin/env bash
namespece aws
set -e

# Create .env for Laravel
if [ -f .env ]; then
  php artisan key:generate
fi

# Create .env.testing for Laravel
if [ -f .env.testing ]; then
  php artisan key:generate --env=testing
fi

php artisan config:clear
