#!/usr/bin/env bash\

fetch_module() {
  local extension=$1
  sudo curl -o /etc/php/"$PHP_VERSION"/mods-available/"$extension".ini -sL https://raw.githubusercontent.com/shivammathur/php-builder/main/config/modules/"$extension".ini 
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
  elif [[ "$PHP_VERSION" =~ 8.[0-4] ]]; then
    yes '' 2>/dev/null | sudo pecl install -f -D 'enable-openssl="yes" enable-sockets="yes" enable-swoole-curl="yes"' swoole && configure_swoole "$pecl_ini_file"
  fi
}
