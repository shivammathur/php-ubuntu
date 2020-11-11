. /etc/lsb-release
tar_file=php_"$1"%2Bubuntu"$DISTRIB_RELEASE".tar.zst
release_url=https://github.com/shivammathur/php-ubuntu/releases/latest/download/"$tar_file"
sudo mkdir -p /tmp/php
sudo curl -o /tmp/"$tar_file" -sSL "$release_url"
sudo tar -I zstd -xf /tmp/"$tar_file" -C /tmp/php
sudo DEBIAN_FRONTEND=noninteractive dpkg -i --force-conflicts /tmp/php/"$1"/*.deb
