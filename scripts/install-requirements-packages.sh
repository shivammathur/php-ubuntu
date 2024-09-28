#!/usr/bin/env bash

. ./scripts/packages.sh
add_ppa

DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 apt-fast automake gcc g++ git jq make pkg-config shtool libtool sudo systemd unzip 
purge_packages libfile-fcntllock-perl libalgorithm-merge-perl libalgorithm-diff-xs-perl unattended-upgrades libalgorithm-diff-perl manpages-dev
DEBIAN_FRONTEND=noninteractive apt-get install -y php"${PHP_VERSION:?}"-common php"${PHP_VERSION:?}"-imagick
purge_packages php"${PHP_VERSION:?}"-imagick php"${PHP_VERSION:?}"-common php-common
DEBIAN_FRONTEND=noninteractive apt-get install -y snmp snmp-mibs-downloader firebird-dev freetds-dev libargon2-dev libaspell-dev libbrotli-dev libc-client2007e libdb-dev libexpat1-dev libhunspell-dev libjson-c-dev libkmod-dev libnorm-dev libpgm-dev libpq-dev libqdbm-dev librabbitmq-dev libsnmp-dev libssl-dev libtidy-dev libtiff-dev libtommath-dev libwebp-dev libxpm-dev libxslt1-dev libyaml-dev libzip-dev udev tzdata
purge_packages libgd3 libimagequant0 libraqm0 libavif13 libyuv0 libaom3 libdav1d5 libgav1-0 libabsl20210324 debsuryorg-archive-keyring
