. ./scripts/extensions.sh
cp /var/lib/dpkg/status /var/lib/dpkg/status-orig
DEBIAN_FRONTEND=noninteractive apt-get install -y libxpm-dev libwebp-dev libpcre3-dev libxmlrpc-epi-dev
curl -o /tmp/install.sh -sL "https://github.com/shivammathur/php-builder/releases/download/$PHP_VERSION/install.sh"
bash /tmp/install.sh github "$PHP_VERSION" "${BUILDS:?}" "${TS:?}"
