#!/usr/bin/env bash

. ./scripts/packages.sh
add_ppa

DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 apt-fast automake file gcc g++ git jq make shtool libtool sudo systemd unzip
DEBIAN_FRONTEND=noninteractive apt-get install -y autoconf firebird-dev freetds-dev libacl1-dev libapparmor-dev libargon2-dev libaspell-dev libc-client2007e-dev libcurl4-openssl-dev libdb-dev libedit-dev libelf1t64 libgomp1 libicu-dev libkrb5-dev libldap-dev liblmdb-dev liblz4-dev libmemcached-dev libonig-dev libpq-dev libqdbm-dev librabbitmq-dev libsodium-dev libsnmp-dev libsqlite3-dev libtidy-dev libtool libwrap0-dev libxml2-dev libxslt1-dev libyaml-dev libzip-dev libzmq3-dev make php-common snmp shtool systemd tzdata
purge_packages libfile-fcntllock-perl libalgorithm-merge-perl libalgorithm-diff-xs-perl unattended-upgrades libalgorithm-diff-perl manpages-dev
purge_packages libgd-dev uuid-dev libfreetype-dev libfreetype6 libfribidi-dev libharfbuzz-dev libgd3 libavif13 libavif16 libimagequant0 libraqm0 libyuv0 libaom3 libdav1d5 libgav1-0 libabsl20210324 libdav1d7 libgav1-1 librav1e0 libsvtav1enc1d1 libabsl20220623t64 || true
arch="$(arch)"
if [[ "$VERSION_ID" != '24.04' && "$arch" != "aarch64" && "$arch" != "arm64" ]]; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y unixodbc
fi
