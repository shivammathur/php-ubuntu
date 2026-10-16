#!/usr/bin/env bash

# shellcheck source=/dev/null
. /etc/os-release

if [ -n "${PHP_BUILDER_ARCHIVE_DIR:-}" ]; then
  echo php-builder
  exit 0
fi

if [ "${NIGHTLY:?}" = 'true' ] || [ "${TS:?}" = 'zts' ] || [ "$VERSION_ID" = "24.04" ] || [ "$VERSION_ID" = "26.04" ] || [[ "$PHP_VERSION" =~ 8.[2-5] ]]; then
  echo php-builder;
else
  echo 'packages';
fi
