#!/usr/bin/env bash

. ./scripts/packages.sh

add_ppa

libenchant_dev=$(apt-cache show libenchant-?[0-9]+?-dev | grep 'Package' | head -n 1 | cut -d ' ' -f 2)
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 apt-fast automake gcc g++ git jq make pkg-config shtool libtool sudo systemd unzip
DEBIAN_FRONTEND=noninteractive apt-get install -y autoconf firebird-dev freetds-dev libacl1-dev libapparmor-dev libargon2-dev libaspell-dev libc-client2007e-dev libcurl4-openssl-dev libdb-dev libedit-dev "$libenchant_dev" libfreetype6-dev libgomp1 libicu-dev libjpeg-dev libkrb5-dev libldap-dev liblmdb-dev liblz4-dev libmagickwand-dev libmemcached-dev libonig-dev libpng-dev libpq-dev libqdbm-dev librabbitmq-dev libsodium-dev libsnmp-dev libsqlite3-dev libtidy-dev libtool libwrap0-dev libxml2-dev libxslt1-dev libyaml-dev libzip-dev libzmq3-dev libzstd-dev make php-common snmp shtool systemd tzdata
purge_packages libfile-fcntllock-perl libalgorithm-merge-perl libalgorithm-diff-xs-perl unattended-upgrades libalgorithm-diff-perl manpages-dev
purge_packages libgd-dev libgd3 libavif13 libyuv0 libaom3 libdav1d5 libgav1-0 libabsl20210324 || true
if [ "$VERSION_ID" != '24.04' ]; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y unixodbc
fi
