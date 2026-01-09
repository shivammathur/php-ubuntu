#!/usr/bin/env bash

. ./scripts/packages.sh
add_ppa

add_packages apache2 apt-fast automake file gcc g++ git jq make pkg-config shtool libtool sudo systemd unzip
purge_packages libfile-fcntllock-perl libalgorithm-merge-perl libalgorithm-diff-xs-perl unattended-upgrades libalgorithm-diff-perl manpages-dev
add_packages php"${PHP_VERSION:?}"-common php"${PHP_VERSION:?}"-imagick
purge_packages php"${PHP_VERSION:?}"-imagick php"${PHP_VERSION:?}"-common php-common
add_packages snmp snmp-mibs-downloader firebird-dev freetds-dev libargon2-dev libaspell-dev libc-client2007e libcurl4-openssl-dev libdb-dev libexpat1-dev libhunspell-dev libjson-c-dev libkmod-dev libnorm-dev libpgm-dev libpq-dev libqdbm-dev librabbitmq-dev libsodium-dev libsnmp-dev libssl-dev libtidy-dev libtiff-dev libtommath-dev libwebp-dev libxpm-dev libxslt1-dev libyaml-dev libzip-dev udev tzdata
purge_packages libgd3 libimagequant0 libraqm0 libavif13 libyuv0 libaom3 libdav1d5 libgav1-0 libabsl20210324 debsuryorg-archive-keyring
