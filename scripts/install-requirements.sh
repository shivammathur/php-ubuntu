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
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 apt-fast automake gcc g++ git jq make pkg-config shtool libtool sudo systemd unzip 
DEBIAN_FRONTEND=noninteractive apt-get purge -y libfile-fcntllock-perl libalgorithm-merge-perl libalgorithm-diff-xs-perl unattended-upgrades libalgorithm-diff-perl manpages-dev
if [[ "${LIBS:?}" = "false" ]]; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y php"${PHP_VERSION:?}"-common php"${PHP_VERSION:?}"-imagick
  DEBIAN_FRONTEND=noninteractive apt-get purge -y php"${PHP_VERSION:?}"-imagick php"${PHP_VERSION:?}"-common
  DEBIAN_FRONTEND=noninteractive apt-get install -y snmp firebird-dev freetds-dev libargon2-dev libaspell-dev libc-client2007e libdb-dev libhunspell-dev libjson-c-dev libkmod-dev libmemcached-dev libnorm-dev libpgm-dev libpq-dev libqdbm-dev librabbitmq-dev libsnmp-dev libssl-dev libtidy-dev libtommath-dev libtiff5-dev libwebp-dev libxpm-dev libxslt1-dev libyaml-dev libzip-dev tzdata
  DEBIAN_FRONTEND=noninteractive apt-get purge -y libgd3 libavif13 libaom3 libdav1d5 libgav1-0 
   libabsl20210324 || true
  DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
fi
