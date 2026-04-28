#!/usr/bin/env bash

cp /var/lib/dpkg/status /var/lib/dpkg/status-orig
DEBIAN_FRONTEND=noninteractive apt-get install -y libxpm-dev libwebp-dev libpcre3-dev libpcre2-dev libxmlrpc-epi-dev libblkid-dev libmount-dev libselinux1-dev
curl -o /tmp/install.sh -sL "https://github.com/shivammathur/php-builder/releases/download/$PHP_VERSION/install.sh"
bash /tmp/install.sh github "$PHP_VERSION" "${BUILDS:?}" "${TS:?}"

. /etc/os-release
. ./scripts/packages.sh
if [ "$VERSION_ID" = '24.04' ]; then
  purge_packages libbz2-dev libcairo2-dev libdav1d-dev libfontconfig-dev libfreetype-dev libgd-dev libgdk-pixbuf-2.0-dev libheif-dev libmagickcore-dev libmagickcore-6.q16-dev libpng-dev libwmf-dev libxpm-dev
fi
