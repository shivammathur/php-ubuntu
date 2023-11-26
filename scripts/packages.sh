#!/usr/bin/env bash

purge_packages() {
    packages=("$@")
    for package in "${packages[@]}"; do
      DEBIAN_FRONTEND=noninteractive apt-get purge -y "$package" || true
    done
}

purge_packages() {
    packages=("$@")
    for package in "${packages[@]}"; do
      DEBIAN_FRONTEND=noninteractive apt-get purge -y "$package" || true
    done
}

add_ppa() {
    . /etc/os-release
    export _APTMGR=apt-get
    apt-get update && apt-get install -y curl sudo software-properties-common
    add-apt-repository ppa:git-core/ppa
    add-apt-repository ppa:apt-fast/stable
    LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
    [ "${BUILDS:?}" = "debug" ] && sed -i "h;s/^//;p;x" /etc/apt/sources.list.d/ondrej-*.list && sed -i '2s/main$/main\/debug/' /etc/apt/sources.list.d/ondrej-*.list
    curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
    curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
    echo "deb https://apt.postgresql.org/pub/repos/apt/ $VERSION_CODENAME-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list
    echo "deb [arch=amd64] https://packages.microsoft.com/ubuntu/$VERSION_ID/prod $VERSION_CODENAME main" | tee /etc/apt/sources.list.d/microsoft-prod.list
    apt-get update
}
