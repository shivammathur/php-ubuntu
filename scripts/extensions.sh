#!/usr/bin/env bash

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

disable_extension() {
  local extension=$1
  pecl_ini_file="$(sudo pecl config-get php_ini)"
  if [[ -n "$pecl_ini_file" && -e "$pecl_ini_file" ]]; then
    grep -q $extension "$pecl_ini_file" && sudo sed -i -e "/$extension/d" "$pecl_ini_file"
  fi
  find /etc/php/"$PHP_VERSION" -name "*-$extension" -delete
}

configure_extension() {
  local extension=$1
  fetch_module "$extension"
  disable_extension "$extension"
}

add_swoole() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y libbrotli-dev
  pecl_ini_file="$(sudo pecl config-get php_ini)"
  if [[ "$PHP_VERSION" =~ 7.[2-4] ]]; then
    yes '' 2>/dev/null | sudo pecl install -f -D 'enable-openssl="yes" enable-sockets="yes" enable-swoole-curl="yes"' swoole-4.8.13 && configure_extension swoole
  elif [[ "$PHP_VERSION" = "8.0" ]]; then
    yes '' 2>/dev/null | sudo pecl install -f -D 'enable-openssl="yes" enable-sockets="yes" enable-swoole-curl="yes"' swoole-5.1.6 && configure_extension swoole
  elif [[ "$PHP_VERSION" =~ 8.[1-4] ]]; then
    yes '' 2>/dev/null | sudo pecl install -f -D 'enable-openssl="yes" enable-sockets="yes" enable-swoole-curl="yes"' swoole && configure_extension swoole
  elif [[ "$PHP_VERSION" =~ 8.[5-6] ]]; then
    git clone https://github.com/swoole/swoole-src
    (
      cd swoole-src
      curl -o swoole.patch -sL https://patch-diff.githubusercontent.com/raw/swoole/swoole-src/pull/5823.patch
      git apply swoole.patch
      phpize
      ./configure --enable-openssl=yes --enable-sockets=yes --enable-swoole-curl="yes"
      make -j$(nproc)
      make install
      configure_extension swoole "$pecl_ini_file"
    )
  fi
}

build_oauth() {
  phpize
  ./configure --enable-oauth
  make -j$(nproc)
  make install
  add_module oauth
  disable_extension oauth
}

add_oauth() {
  local source=$1
  if [[ "$PHP_VERSION" =~ 7.0 ]]; then
    git clone https://github.com/php/pecl-web_services-oauth -b 2.0.8
    (
      cd pecl-web_services-oauth
      build_oauth
    )
  elif [ "$source" = "packages" ]; then
    DEBIAN_FRONTEND=noninteractive apt-fast install -y --no-install-recommends "php$PHP_VERSION-oauth"
    disable_extension oauth
  elif [ "$source" = "php-builder" ]; then  
    sudo pecl download oauth
    sudo tar xf oauth-*
    (
      cd oauth-*/
      if [[ "$PHP_VERSION" =~ 8.[5-6] ]]; then
        for file in provider.c oauth.c; do sed -i 's/zend_exception_get_default()/zend_ce_exception/' $file; done
        sed -i 's#ext/standard/php_smart_string.h#Zend/zend_smart_string.h#' php_oauth.h
      fi
      build_oauth
    )
  fi
}
