#!/bin/sh
set -e

# Install composer
if [ ! -f composer.phar ]; then
  echo "composer.phar is not found in . Installing..."
  curl --insecure -sSL https://getcomposer.org/installer | php -- -2.2
fi

# Remove cache
if [ -d bootstrap/cache ]; then
  find bootstrap/cache -type f -name "*.php" | xargs rm -rf
fi

# Install vendor libraries
php composer.phar install

# Link of phpunit
if [ ! -L /usr/local/bin/phpunit ]; then
  ln -s ${DEPLOY_DIR}/vendor/bin/phpunit /usr/local/bin/phpunit
fi
