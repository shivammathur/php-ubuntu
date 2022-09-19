#!/usr/bin/env bash

get() {
  file_path=$1
  shift
  links=("$@")
  for link in "${links[@]}"; do
    status_code=$(sudo curl -w "%{http_code}" -o "$file_path" -sL "$link")
    [ "$status_code" = "200" ] && break
  done
}

install() {
  get /tmp/"$tar_file" "https://github.com/shivammathur/php-ubuntu/releases/latest/download/$tar_file" "https://dl.cloudsmith.io/public/shivammathur/php-ubuntu/raw/files/$tar_file"
  sudo cp /var/lib/dpkg/status /var/lib/dpkg/status-orig
  sudo rm -rf /var/lib/apt/lists/*ondrej*
  sudo tar -I zstd -xf /tmp/"$tar_file" -C /
  sudo LC_ALL=C.UTF-8 python3 /usr/sbin/merge_status && sudo rm -f /usr/sbin/merge_status
  sudo mv /var/lib/dpkg/status-orig /var/lib/dpkg/status
}

fix_service() {
  if [ "$reload" = "true" ]; then
    sudo systemctl daemon-reload 2>/dev/null || true
    sudo systemctl start php"$version"-fpm 2>/dev/null || true
  fi
}

fix_packages() {
  if [ "$VERSION_ID" = "18.04" ] && ! sudo apt-get check 2>/dev/null; then
    sudo apt --fix-broken install
  fi
}

fix_list() {
  if [ "$builds" = "debug" ]; then
    list=/etc/apt/sources.list.d/"$(basename "$(grep -lr "ondrej/php" /etc/apt/sources.list.d)")"
    sudo apt-get update -o Dir::Etc::sourcelist="$list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
  fi
}

fix_alternatives() {
  to_wait=()
  sudo update-alternatives --force --install /usr/lib/cgi-bin/php php-cgi-bin /usr/lib/cgi-bin/php"$version" "${version/./}" & to_wait+=($!)
  sudo update-alternatives --force --install /usr/sbin/php-fpm php-fpm /usr/sbin/php-fpm"$version" "${version/./}" & to_wait+=($!)
  sudo update-alternatives --force --install /run/php/php-fpm.sock php-fpm.sock /run/php/php"$version"-fpm.sock "${version/./}" & to_wait+=($!)
  for tool in phpize php-config phpdbg php-cgi php phar.phar phar; do
    sudo update-alternatives --force --install /usr/bin/"$tool" "$tool" /usr/bin/"$tool$version" "${version/./}" \
                             --slave /usr/share/man/man1/"$tool".1.gz "$tool".1.gz /usr/share/man/man1/"$tool$version".1.gz &
    to_wait+=($!)
  done
  wait "${to_wait[@]}"
}

check_reload() {
  if ! [ -e /lib/systemd/system/php"$version"-fpm.service ]; then
    reload=true
  fi
  if [ "$(readlink -f /etc/systemd/system/php"$version"-fpm.service)" = "/dev/null" ]; then
    sudo rm -f /etc/systemd/system/php"$version"-fpm.service
    reload=true
  fi
}

. /etc/os-release
version=$1
builds=${2:-release}
[ "${builds:?}" = "debug" ] && PHP_PKG_SUFFIX=-dbgsym
tar_file=php_"$version$PHP_PKG_SUFFIX"+ubuntu"$VERSION_ID".tar.zst
check_reload
install
fix_alternatives
fix_service
fix_list
fix_packages
