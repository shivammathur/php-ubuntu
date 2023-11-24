cp /var/lib/dpkg/status /var/lib/dpkg/status-orig
curl -o /tmp/install.sh -sL "https://github.com/shivammathur/php-builder/releases/download/$PHP_VERSION/install.sh"
bash /tmp/install.sh github "$PHP_VERSION" "${BUILDS:?}" nts
