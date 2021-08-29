. /etc/os-release
export _APTMGR=apt-get
apt-get update && apt-get install -y curl sudo software-properties-common
add-apt-repository ppa:git-core/ppa
add-apt-repository ppa:apt-fast/stable
LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
echo "deb https://apt.postgresql.org/pub/repos/apt/ $VERSION_CODENAME-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list
echo "deb [arch=amd64] https://packages.microsoft.com/ubuntu/$VERSION_ID/prod $VERSION_CODENAME main" | tee /etc/apt/sources.list.d/microsoft-prod.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 apt-fast automake gcc git jq make pkg-config shtool snmp sudo unzip php"${PHP_VERSION:?}"-common php"${PHP_VERSION:?}"-imagick
DEBIAN_FRONTEND=noninteractive apt-get purge -y libfile-fcntllock-perl libalgorithm-merge-perl libalgorithm-diff-xs-perl unattended-upgrades libalgorithm-diff-perl manpages-dev php"${PHP_VERSION:?}"-imagick php"${PHP_VERSION:?}"-common
DEBIAN_FRONTEND=noninteractive apt-get install -y libssl-dev librabbitmq-dev libmemcached-dev libpgm-dev libargon2-dev libsodium-dev libnorm-dev libpq-dev libzmq5 firebird-dev libaspell-dev freetds-dev libhunspell-dev libxpm-dev libtommath-dev libqdbm-dev libtidy-dev libdb-dev libxslt1-dev
