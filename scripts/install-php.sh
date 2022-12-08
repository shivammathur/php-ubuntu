[ "${BUILDS:?}" = "debug" ] && PHP_PKG_SUFFIX=-dbgsym
cp /var/lib/dpkg/status /var/lib/dpkg/status-orig
DEBIAN_FRONTEND=noninteractive apt-get install -f
echo "Installing PHP $PHP_VERSION"

DEBIAN_FRONTEND=noninteractive apt-fast install -y --no-install-recommends \
  php$PHP_VERSION \
  php$PHP_VERSION-amqp \
  php$PHP_VERSION-apcu \
  php$PHP_VERSION-bcmath \
  php$PHP_VERSION-bz2 \
  php$PHP_VERSION-cgi \
  php$PHP_VERSION-cli \
  php$PHP_VERSION-common \
  php$PHP_VERSION-curl \
  php$PHP_VERSION-dba \
  php$PHP_VERSION-dev \
  php$PHP_VERSION-enchant \
  php$PHP_VERSION-fpm \
  php$PHP_VERSION-gd \
  php$PHP_VERSION-gmp \
  php$PHP_VERSION-igbinary \
  php$PHP_VERSION-imagick \
  php$PHP_VERSION-imap \
  php$PHP_VERSION-interbase \
  php$PHP_VERSION-intl \
  php$PHP_VERSION-ldap \
  php$PHP_VERSION-mbstring \
  php$PHP_VERSION-memcache \
  php$PHP_VERSION-memcached \
  php$PHP_VERSION-mongodb \
  php$PHP_VERSION-msgpack \
  php$PHP_VERSION-mysql \
  php$PHP_VERSION-odbc \
  php$PHP_VERSION-opcache \
  php$PHP_VERSION-pgsql \
  php$PHP_VERSION-phpdbg \
  php$PHP_VERSION-pspell \
  php$PHP_VERSION-readline \
  php$PHP_VERSION-redis \
  php$PHP_VERSION-snmp \
  php$PHP_VERSION-soap \
  php$PHP_VERSION-sqlite3 \
  php$PHP_VERSION-sybase \
  php$PHP_VERSION-tidy \
  php$PHP_VERSION-xdebug \
  php$PHP_VERSION-xml \
  php$PHP_VERSION-xsl \
  php$PHP_VERSION-yaml \
  php$PHP_VERSION-zip \
  php$PHP_VERSION-zmq

[ "${BUILDS:?}" = "debug" ] && DEBIAN_FRONTEND=noninteractive apt-fast install -y --no-install-recommends \
  php$PHP_VERSION$PHP_PKG_SUFFIX \
  php$PHP_VERSION-amqp$PHP_PKG_SUFFIX \
  php$PHP_VERSION-apcu$PHP_PKG_SUFFIX \
  php$PHP_VERSION-bcmath$PHP_PKG_SUFFIX \
  php$PHP_VERSION-bz2$PHP_PKG_SUFFIX \
  php$PHP_VERSION-cgi$PHP_PKG_SUFFIX \
  php$PHP_VERSION-cli$PHP_PKG_SUFFIX \
  php$PHP_VERSION-common$PHP_PKG_SUFFIX \
  php$PHP_VERSION-curl$PHP_PKG_SUFFIX \
  php$PHP_VERSION-dba$PHP_PKG_SUFFIX \
  php$PHP_VERSION-enchant$PHP_PKG_SUFFIX \
  php$PHP_VERSION-fpm$PHP_PKG_SUFFIX \
  php$PHP_VERSION-gd$PHP_PKG_SUFFIX \
  php$PHP_VERSION-gmp$PHP_PKG_SUFFIX \
  php$PHP_VERSION-igbinary$PHP_PKG_SUFFIX \
  php$PHP_VERSION-imagick$PHP_PKG_SUFFIX \
  php$PHP_VERSION-imap$PHP_PKG_SUFFIX \
  php$PHP_VERSION-interbase$PHP_PKG_SUFFIX \
  php$PHP_VERSION-intl$PHP_PKG_SUFFIX \
  php$PHP_VERSION-ldap$PHP_PKG_SUFFIX \
  php$PHP_VERSION-mbstring$PHP_PKG_SUFFIX \
  php$PHP_VERSION-memcache$PHP_PKG_SUFFIX \
  php$PHP_VERSION-memcached$PHP_PKG_SUFFIX \
  php$PHP_VERSION-mongodb$PHP_PKG_SUFFIX \
  php$PHP_VERSION-msgpack$PHP_PKG_SUFFIX \
  php$PHP_VERSION-mysql$PHP_PKG_SUFFIX \
  php$PHP_VERSION-odbc$PHP_PKG_SUFFIX \
  php$PHP_VERSION-opcache$PHP_PKG_SUFFIX \
  php$PHP_VERSION-pgsql$PHP_PKG_SUFFIX \
  php$PHP_VERSION-phpdbg$PHP_PKG_SUFFIX \
  php$PHP_VERSION-pspell$PHP_PKG_SUFFIX \
  php$PHP_VERSION-readline$PHP_PKG_SUFFIX \
  php$PHP_VERSION-redis$PHP_PKG_SUFFIX \
  php$PHP_VERSION-snmp$PHP_PKG_SUFFIX \
  php$PHP_VERSION-soap$PHP_PKG_SUFFIX \
  php$PHP_VERSION-sqlite3$PHP_PKG_SUFFIX \
  php$PHP_VERSION-sybase$PHP_PKG_SUFFIX \
  php$PHP_VERSION-tidy$PHP_PKG_SUFFIX \
  php$PHP_VERSION-xml$PHP_PKG_SUFFIX \
  php$PHP_VERSION-yaml$PHP_PKG_SUFFIX \
  php$PHP_VERSION-zip$PHP_PKG_SUFFIX \
  php$PHP_VERSION-zmq$PHP_PKG_SUFFIX

if [[ $PHP_VERSION == "5.6" || $PHP_VERSION == "7.0" || $PHP_VERSION == "7.1" ]]; then
  DEBIAN_FRONTEND=noninteractive apt-fast install -y --no-install-recommends php$PHP_VERSION-mcrypt php$PHP_VERSION-recode
  [ "${BUILDS:?}" = "debug" ] && DEBIAN_FRONTEND=noninteractive apt-fast install -y --no-install-recommends php$PHP_VERSION-mcrypt$PHP_PKG_SUFFIX php$PHP_VERSION-recode$PHP_PKG_SUFFIX
fi

if [[ $PHP_VERSION == "7.2" || $PHP_VERSION == "7.3" ]]; then
  DEBIAN_FRONTEND=noninteractive apt-fast install -y --no-install-recommends php$PHP_VERSION-recode
  [ "${BUILDS:?}" = "debug" ] && apt-fast install -y --no-install-recommends php$PHP_VERSION-recode$PHP_PKG_SUFFIX
fi

if [[ $PHP_VERSION != "8.0" && $PHP_VERSION != "8.1" && $PHP_VERSION != "8.2" ]]; then
  DEBIAN_FRONTEND=noninteractive apt-fast install -y --no-install-recommends php$PHP_VERSION-xmlrpc php$PHP_VERSION-json
  [ "${BUILDS:?}" = "debug" ] && DEBIAN_FRONTEND=noninteractive apt-fast install -y --no-install-recommends php$PHP_VERSION-xmlrpc$PHP_PKG_SUFFIX php$PHP_VERSION-json$PHP_PKG_SUFFIX
fi

if [[ $PHP_VERSION != "5.6" ]]; then
  DEBIAN_FRONTEND=noninteractive apt-fast install -y --no-install-recommends php$PHP_VERSION-ds
fi

if [[ $PHP_VERSION = "7.0" || $PHP_VERSION = "7.1" ]]; then
  DEBIAN_FRONTEND=noninteractive apt-fast install -y --no-install-recommends php$PHP_VERSION-sodium
  [ "${BUILDS:?}" = "debug" ] && apt-fast install -y --no-install-recommends php$PHP_VERSION-sodium$PHP_PKG_SUFFIX
fi

DEBIAN_FRONTEND=noninteractive apt-fast install -y --no-install-recommends libpcre3-dev libsodium-dev libpq-dev unixodbc-dev
DEBIAN_FRONTEND=noninteractive apt-fast install -y --no-install-recommends php-pear

for extension in ast pcov; do
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "php$PHP_VERSION-$extension" 2>/dev/null || true
  [ "${BUILDS:?}" = "debug" ] && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "php$PHP_VERSION-$extension$PHP_PKG_SUFFIX" 2>/dev/null || true
done


tools=(pear pecl php phar phar.phar php-cgi php-config phpize phpdbg)
for tool in "${tools[@]}"; do
  if [ -e "/usr/bin/$tool$PHP_VERSION" ]; then
    sudo update-alternatives --set "$tool" /usr/bin/"$tool$PHP_VERSION"
  fi
done

for extension in sqlsrv pdo_sqlsrv; do
  if [[ $PHP_VERSION =~ 7.[0-3] ]]; then
    sudo pecl install -f "$extension"-5.9.0
  elif [[ $PHP_VERSION =~ 7.4|8.[0-2] ]]; then
    sudo pecl install -f "$extension"
  fi
  if [[ $PHP_VERSION =~ 7.[0-4]|8.[0-2] ]]; then
    sudo curl -o /etc/php/"$PHP_VERSION"/mods-available/"$extension".ini -sL https://raw.githubusercontent.com/shivammathur/php-builder/main/config/modules/"$extension".ini
    phpenmod -v "$PHP_VERSION" "$extension"
  fi  
done

sudo rm -rf /var/cache/apt/archives/*.deb || true
sudo rm -rf /var/cache/apt/archives/*.ddeb || true

if [ -d /run/systemd/system ]; then
  sudo systemctl daemon-reload 2>/dev/null || true
  sudo systemctl enable php"$PHP_VERSION"-fpm 2>/dev/null || true
fi

sed -i 's/TIMEOUT=.*/TIMEOUT=5/g' /etc/init.d/php"$PHP_VERSION"-fpm
service php"$PHP_VERSION"-fpm restart >/dev/null 2>&1 || service php"$PHP_VERSION"-fpm restart >/dev/null 2>&1 || service php"$PHP_VERSION"-fpm start >/dev/null 2>&1
service php"$PHP_VERSION"-fpm status
