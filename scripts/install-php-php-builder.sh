. ./scripts/extensions.sh
cp /var/lib/dpkg/status /var/lib/dpkg/status-orig
DEBIAN_FRONTEND=noninteractive apt-get install -y libxpm-dev libwebp-dev libpcre3-dev libpcre2-dev libxmlrpc-epi-dev
curl -o /tmp/install.sh -sL "https://github.com/shivammathur/php-builder/releases/download/$PHP_VERSION/install.sh"
bash /tmp/install.sh github "$PHP_VERSION" "${BUILDS:?}" "${TS:?}"
add_swoole

. /etc/os-release
. ./scripts/packages.sh
if [ "$VERSION_ID" = '24.04' ]; then
  purge_packages libdav1d-dev libgd-dev libxpm-dev libheif-dev
fi  
