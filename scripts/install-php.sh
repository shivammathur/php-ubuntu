cp /var/lib/dpkg/status /var/lib/dpkg/status-orig
apt-get install -f
echo "Installing PHP $PHP_VERSION"
apt-fast install -y --no-install-recommends \
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

if [[ $PHP_VERSION == "5.6" || $PHP_VERSION == "7.0" || $PHP_VERSION == "7.1" ]]; then
  apt-fast install -y --no-install-recommends php$PHP_VERSION-mcrypt php$PHP_VERSION-recode
fi

if [[ $PHP_VERSION == "7.2" || $PHP_VERSION == "7.3" ]]; then
  apt-fast install -y --no-install-recommends php$PHP_VERSION-recode
fi

if [[ $PHP_VERSION != "8.0" && $PHP_VERSION != "8.1" ]]; then
  apt-fast install -y --no-install-recommends php$PHP_VERSION-xmlrpc php$PHP_VERSION-json
fi

if [[ $PHP_VERSION != "5.6" ]]; then
  apt-fast install -y --no-install-recommends php$PHP_VERSION-ds
fi

if [[ $PHP_VERSION = "7.0" || $PHP_VERSION = "7.1" ]]; then
  apt-fast install -y --no-install-recommends php$PHP_VERSION-sodium
fi

if [[ $PHP_VERSION != "7.1" || $VERSION_ID != "22.04" ]]; then
  apt-fast install -y --no-install-recommends php$PHP_VERSION-mongodb
fi

apt-fast install -y --no-install-recommends libpcre3-dev libsodium-dev libpq-dev unixodbc-dev
apt-fast install -y --no-install-recommends php-pear

for extension in ast pcov; do
  sudo apt-get install "php$PHP_VERSION-$extension" -y 2>/dev/null || true
done

for extension in sqlsrv pdo_sqlsrv; do
  if [[ $PHP_VERSION =~ 7.[0-3] ]]; then
    sudo pecl install -f "$extension"-5.9.0
  elif [[ $PHP_VERSION =~ 7.4|8.[0-1] ]]; then
    sudo pecl install -f "$extension"
  fi
  if [[ $PHP_VERSION =~ 7.[0-4]|8.[0-1] ]]; then
    sudo curl -o /etc/php/"$PHP_VERSION"/mods-available/"$extension".ini -sL https://raw.githubusercontent.com/shivammathur/php-builder/main/config/modules/"$extension".ini
    phpenmod -v "$PHP_VERSION" "$extension"
  fi  
done

sudo rm -rf /var/cache/apt/archives/*.deb || true

if [ -d /run/systemd/system ]; then
  sudo systemctl daemon-reload 2>/dev/null || true
  sudo systemctl enable php"$PHP_VERSION"-fpm 2>/dev/null || true
fi

sed -i 's/TIMEOUT=.*/TIMEOUT=5/g' /etc/init.d/php"$PHP_VERSION"-fpm
service php"$PHP_VERSION"-fpm restart >/dev/null 2>&1 || service php"$PHP_VERSION"-fpm restart >/dev/null 2>&1 || service php"$PHP_VERSION"-fpm start >/dev/null 2>&1
service php"$PHP_VERSION"-fpm status
