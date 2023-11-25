purge_packages() {
    packages=("$@")
    for package in "${packages[@]}"; do
      DEBIAN_FRONTEND=noninteractive apt-get purge -y "$package" || true
    done
}

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
libenchant_dev=$(apt-cache show libenchant-?[0-9]+?-dev | grep 'Package' | head -n 1 | cut -d ' ' -f 2)
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 apt-fast automake gcc g++ git jq make pkg-config shtool libtool sudo systemd unzip
DEBIAN_FRONTEND=noninteractive apt-get install -y autoconf firebird-dev freetds-dev libacl1-dev libapparmor-dev libargon2-dev libaspell-dev libc-client2007e-dev libcurl4-openssl-dev libdb-dev libedit-dev "$libenchant_dev" libfreetype6-dev libgomp1 libicu-dev libjpeg-dev libkrb5-dev libldap-dev liblmdb-dev liblz4-dev libmagickwand-dev libmemcached-dev libonig-dev libpng-dev libpq-dev libqdbm-dev librabbitmq-dev libsodium-dev libsqlite3-dev libtidy-dev libtool libxslt1-dev libyaml-dev libzip-dev libzstd-dev make php-common shtool systemd tzdata unixodbc-dev
purge_packages libfile-fcntllock-perl libalgorithm-merge-perl libalgorithm-diff-xs-perl unattended-upgrades libalgorithm-diff-perl manpages-dev
purge_packages libgd-dev libgd3 libpcre3-dev libpcre16-3 libpcre32-3 libpcrecpp0v5 libavif13 libyuv0 libaom3 libdav1d5 libgav1-0 libabsl20210324 || true
