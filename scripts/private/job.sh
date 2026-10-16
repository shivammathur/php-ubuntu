#!/usr/bin/env bash
set -euo pipefail
[ "${GITHUB_ACTIONS:-}" = true ] || { echo 'Private jobs require disposable Actions runners'; exit 1; }
export DEBIAN_FRONTEND=noninteractive
case "$1" in
  package)
    bash scripts/install-requirements.sh
    bash scripts/install-zstd.sh
    bash scripts/configure-filesystem-snapshot.sh
    bash scripts/install-php.sh
    [ "$(php -n -r 'echo PHP_VERSION;')" = "$PHP_PRIVATE_RELEASE_VERSION" ]
    [ "$(php -n -r 'echo PHP_ZTS ? "zts" : "nts";')" = "$TS" ]
    bash scripts/package-php.sh
    for archive in builds/*.zst; do zstd -t "$archive"; done
    ;;
  test)
    # Container checks need the same base runtime tools present on hosted images.
    if [ "$PRIVATE_TEST_KIND" = container ]; then
      apt-get update
      apt-get install -y sudo curl zstd python3 file
    fi
    PHP_UBUNTU_SKIP_PACKAGE_REPAIR=true bash "$PHP_UBUNTU_ARCHIVE_DIR/install.sh" "$PHP_VERSION" "$BUILDS" "$TS"
    [ "$(php -n -r 'echo PHP_VERSION;')" = "$PHP_PRIVATE_RELEASE_VERSION" ]
    [ "$(php -n -r 'echo PHP_ZTS ? "zts" : "nts";')" = "$TS" ]
    php-config --version
    php-fpm -v
    sudo php-fpm -t
    php-cgi -v
    phpize -v
    php -m
    sudo service "php$PHP_VERSION-fpm" status
    phpize -v | grep -q "$(php-config --phpapi)"
    bash scripts/test-optional-extensions.sh
    bash scripts/check-test-packages.sh "$PHP_VERSION" "$PRIVATE_TEST_OS" success success
    source "reports/$PHP_VERSION-$PRIVATE_TEST_OS.env"
    [ "$broken" != true ]
    ;;
  *) exit 1 ;;
esac
