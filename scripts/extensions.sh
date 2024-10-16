#!/usr/bin/env bash\

fetch_module() {
  local extension=$1
  sudo curl -o /etc/php/"$PHP_VERSION"/mods-available/"$extension".ini -sL https://raw.githubusercontent.com/shivammathur/php-builder/main/config/modules/"$extension".ini 
}

add_module() {
  local extension=$1
  local priority=${2:-20}
  echo -e "; priority=$priority\nextension=$extension.so" | tee /etc/php/"$PHP_VERSION"/mods-available/"$extension".ini
}

enable_pecl_extension() {
  local extension=$1
  fetch_module "$extension"
  phpenmod -v "$PHP_VERSION" "$extension"
}

configure_swoole() {
  pecl_ini_file=$1
  fetch_module swoole  
  if [[ -n "$pecl_ini_file" && -e "$pecl_ini_file" ]]; then
    grep -q swoole "$pecl_ini_file" && sudo sed -i -e '/swoole/d' "$pecl_ini_file"
  fi
}

add_swoole() {
  pecl_ini_file="$(sudo pecl config-get php_ini)"
  if [[ "$PHP_VERSION" =~ 7.[2-4] ]]; then
    yes '' 2>/dev/null | sudo pecl install -f -D 'enable-openssl="yes" enable-sockets="yes" enable-swoole-curl="yes"' swoole-4.8.13 && configure_swoole "$pecl_ini_file"
  elif [[ "$PHP_VERSION" =~ 8.[0-3] ]]; then
    yes '' 2>/dev/null | sudo pecl install -f -D 'enable-openssl="yes" enable-sockets="yes" enable-swoole-curl="yes"' swoole && configure_swoole "$pecl_ini_file"
  elif [[ "$PHP_VERSION" =~ 8.[4-5] ]]; then
    git clone https://github.com/swoole/swoole-src
    (
      cd swoole-src
      phpize
      ./configure --enable-openssl=yes --enable-sockets=yes --enable-swoole-curl="yes"
      make -j$(nproc)
      make install
      configure_swoole "$pecl_ini_file"
    )
  fi
}

add_oauth_php_70() {
  git clone https://github.com/php/pecl-web_services-oauth -b 2.0.8
  (
    cd pecl-web_services-oauth
    phpize
    ./configure --enable-oauth
    make -j$(nproc)
    make install
    add_module oauth
  )
}
