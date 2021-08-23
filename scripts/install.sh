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
  sudo tar -I zstd -xf /tmp/"$tar_file" -C /
  sudo python3 /usr/sbin/merge_status && sudo rm -f /usr/sbin/merge_status
  sudo mv /var/lib/dpkg/status-orig /var/lib/dpkg/status
}

fix_alternatives() {
  to_wait=()
  for tool in phpize php-config phpdbg php-cgi php phar.phar phar; do
    sudo update-alternatives --quiet --force --install "/usr/bin/$tool" "$tool" "/usr/bin/$tool$version" "${version/./}" \
                             --slave /usr/share/man/man1/"$tool".1.gz "$tool".1.gz /usr/share/man/man1/"$tool$version".1.gz &
    to_wait+=($!)
  done
  wait "${to_wait[@]}"
  sudo update-alternatives --quiet --force --install /usr/lib/cgi-bin/php php-cgi-bin "/usr/lib/cgi-bin/php$version" "${version/./}"
}

. /etc/os-release
version=$1
tar_file=php_"$version"%2Bubuntu"$VERSION_ID".tar.zst
install
fix_alternatives
