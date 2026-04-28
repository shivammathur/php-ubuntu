#!/usr/bin/env bash
set -euo pipefail

PHP_VERSION=${PHP_VERSION:?}
optional_extensions_file=${OPTIONAL_EXTENSIONS_FILE:-scripts/optional-extensions}
mods_dir=/etc/php/"$PHP_VERSION"/mods-available
ext_dir="$(php-config --extension-dir)"
enabled_extensions=()

enable_extension() {
  local extension=$1
  local ini_file=$mods_dir/$extension.ini
  local priority

  if command -v phpenmod >/dev/null 2>&1; then
    sudo phpenmod -v "$PHP_VERSION" -s ALL "$extension"
    return
  fi

  priority="$(sed -n 's/^; priority=//p' "$ini_file" | head -n 1)"
  priority="${priority:-20}"
  for conf_dir in /etc/php/"$PHP_VERSION"/*/conf.d; do
    [ -d "$conf_dir" ] || continue
    sudo ln -sf "$ini_file" "$conf_dir"/"$priority-$extension.ini"
  done
}

while read -r extension; do
  [ -n "$extension" ] || continue

  if [ ! -f "$ext_dir/$extension.so" ]; then
    continue
  fi

  if [ ! -f "$mods_dir/$extension.ini" ]; then
    echo "$extension module is present, but $mods_dir/$extension.ini is missing"
    exit 1
  fi

  echo "Enabling optional extension: $extension"
  enable_extension "$extension"
  enabled_extensions+=("$extension")
done < "$optional_extensions_file"

if [ "${#enabled_extensions[@]}" -eq 0 ]; then
  echo "No optional extensions found in $ext_dir"
  exit 0
fi

php_modules="$(php -m 2>&1)" || {
  echo "$php_modules"
  exit 1
}

echo "$php_modules"
if echo "$php_modules" | grep -Eiq 'PHP (Warning|Fatal error|Parse error)|Unable to load|Cannot load|undefined symbol|already loaded'; then
  exit 1
fi

for extension in "${enabled_extensions[@]}"; do
  echo "Checking optional extension info: $extension"
  php --ri "$extension"
done
