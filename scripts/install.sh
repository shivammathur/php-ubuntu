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
  sudo mkdir -p /tmp/php
  get /tmp/"$tar_file" "https://github.com/shivammathur/php-ubuntu/releases/latest/download/$tar_file" "https://dl.cloudsmith.io/public/shivammathur/php-ubuntu/raw/files/$tar_file"
  sudo tar -I zstd -xf /tmp/"$tar_file" -C /
}

fix_alternatives() {
  to_wait=()
  for tool in phpize php-config phpdbg php-cgi php phar.phar phar; do
    (sudo sed -i '/gz/d' "/var/lib/dpkg/alternatives/$tool" && sudo update-alternatives --quiet --force --install "/usr/bin/$tool" "$tool" "/usr/bin/$tool$version" "${version/./}") &
    to_wait+=($!)
  done
  wait "${to_wait[@]}"
  sudo update-alternatives --quiet --force --install /usr/lib/cgi-bin/php php-cgi-bin "/usr/lib/cgi-bin/php$version" "${version/./}"
}

. /etc/lsb-release
version=$1
tar_file=php_"$version"%2Bubuntu"$DISTRIB_RELEASE".tar.zst
install
fix_alternatives
