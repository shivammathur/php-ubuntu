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
  fetch_module swoole
  pecl_ini_file="$(sudo pecl config-get php_ini)"
  if [[ -n "$pecl_ini_file" && -e "$pecl_ini_file" ]]; then
    grep -q swoole "$pecl_ini_file" && sudo sed -i -e '/swoole/d' "$pecl_ini_file"
  fi
}

add_swoole() {
  if [[ "$PHP_VERSION" =~ 7.[2-4] ]]; then
    sudo pecl install -f swoole-4.8.13 && configure_swoole
  elif [[ "$PHP_VERSION" =~ 8.[0-4] ]]; then
    sudo pecl install -f swoole && configure_swoole
  fi
}