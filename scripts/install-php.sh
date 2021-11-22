cp /var/lib/dpkg/status /var/lib/dpkg/status-orig
apt-get install -f
for version in $PHP_VERSION; do
  echo "Installing PHP $version"
  apt-fast install -y --no-install-recommends \
    php$version \
    php$version-amqp \
    php$version-apcu \
    php$version-bcmath \
    php$version-bz2 \
    php$version-cgi \
    php$version-cli \
    php$version-common \
    php$version-curl \
    php$version-dba \
    php$version-dev \
    php$version-enchant \
    php$version-fpm \
    php$version-gd \
    php$version-gmp \
    php$version-igbinary \
    php$version-imagick \
    php$version-imap \
    php$version-interbase \
    php$version-intl \
    php$version-ldap \
    php$version-mbstring \
    php$version-memcache \
    php$version-memcached \
    php$version-mongodb \
    php$version-mysql \
    php$version-odbc \
    php$version-opcache \
    php$version-pgsql \
    php$version-phpdbg \
    php$version-pspell \
    php$version-readline \
    php$version-redis \
    php$version-snmp \
    php$version-soap \
    php$version-sqlite3 \
    php$version-sybase \
    php$version-tidy \
    php$version-xdebug \
    php$version-xml \
    php$version-xsl \
    php$version-yaml \
    php$version-zip \
    php$version-zmq

  if [[ $version == "5.6" || $version == "7.0" || $version == "7.1" ]]; then
    apt-fast install -y --no-install-recommends php$version-mcrypt php$version-recode
  fi

  if [[ $version == "7.2" || $version == "7.3" ]]; then
    apt-fast install -y --no-install-recommends php$version-recode
  fi

  if [[ $version != "8.0" ]]; then
    apt-fast install -y --no-install-recommends php$version-xmlrpc php$version-json
  fi

  if [[ $version != "5.6" && $version != "7.0" ]]; then
    apt-fast install -y --no-install-recommends php$version-pcov
    phpdismod -v $version pcov
  fi

  if [[ $version = "7.0" || $version = "7.1" ]]; then
    apt-fast install -y --no-install-recommends php$version-sodium
  fi
done

for extension in ast pcov; do
  sudo apt-get install "php$PHP_VERSION-$extension" -y 2>/dev/null || true
done

sudo apt-get install libpcre3-dev libpcre2-dev libpcre2-8-0 libpq-dev unixodbc-dev -y || true
sudo rm -rf /var/cache/apt/archives/*.deb || true