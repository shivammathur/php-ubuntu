#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd / || exit 1
[ "${BUILDS:?}" = "debug" ] && PHP_PKG_SUFFIX=-dbgsym

# shellcheck source=scripts/filesystem-snapshot.sh
. "$script_dir/filesystem-snapshot.sh"

remove_extension_debug_symbols() {
  extension=$1

  [ "${BUILDS:?}" = "debug" ] || return 0
  command -v readelf >/dev/null 2>&1 || return 0

  for module in /tmp/php/usr/lib/php/*/"$extension".so; do
    [ -e "$module" ] || continue
    build_id="$(readelf -n "$module" 2>/dev/null | awk '/Build ID:/ { print $3; exit }')"
    [ -n "$build_id" ] || continue
    sudo rm -f /tmp/php/usr/lib/debug/.build-id/"${build_id:0:2}"/"${build_id:2}".debug
  done
}

remove_optional_extension_debug_symbols() {
  optional_extensions_file="${GITHUB_WORKSPACE:-}"/scripts/optional-extensions

  [ "${BUILDS:?}" = "debug" ] || return 0
  [ -f "$optional_extensions_file" ] || return 0

  while read -r extension; do
    [ -n "$extension" ] || continue
    remove_extension_debug_symbols "$extension"
  done < "$optional_extensions_file"
}

verify_cleanup_candidates() {
  candidates_file=$(mktemp)
  needed_file=$(mktemp)

  find /tmp/php -type f \( -name '*.a' -o -name '*.gir' \) -printf '%f\n' | sort -u > "$candidates_file"
  while IFS= read -r -d '' file; do
    readelf -d "$file" 2>/dev/null | awk -F '[][]' '/NEEDED/ { print $2 }' >> "$needed_file"
  done < <(find /tmp/php -type f -print0)

  if grep -Fxf "$candidates_file" "$needed_file"; then
    echo "Refusing to remove a file that is referenced by an ELF dependency"
    rm -f "$candidates_file" "$needed_file"
    exit 1
  fi
  rm -f "$candidates_file" "$needed_file"
}

remove_dev_artifacts() {
  verify_cleanup_candidates
  sudo find /tmp/php -type f \( -name '*.a' -o -name '*.gir' \) -delete
}

package_matches_patterns() {
  local package package_name pattern patterns_file

  package=$1
  package_name=${package%%:*}
  patterns_file=$2

  [ -f "$patterns_file" ] || return 1

  while IFS= read -r pattern; do
    [ -n "$pattern" ] || continue
    # shellcheck disable=SC2053
    [[ $package == $pattern || $package_name == $pattern ]] && return 0
  done < "$patterns_file"

  return 1
}

write_excluded_package_files() {
  local output package tmp_files

  output=$1
  tmp_files="$(mktemp)"

  if [ -f /tmp/excluded ]; then
    dpkg-query -W -f='${binary:Package}\n' 2>/dev/null | while IFS= read -r package; do
      [ -n "$package" ] || continue
      package_matches_patterns "$package" /tmp/excluded || continue

      dpkg-query -L "$package" 2>/dev/null
      find /var/lib/dpkg/info -maxdepth 1 \( -name "$package.*" -o -name "$package:*" \) -print 2>/dev/null
    done > "$tmp_files"
  fi

  LC_ALL=C sort -u "$tmp_files" > "$output"
  rm -f "$tmp_files"
}

remove_excluded_package_files() {
  excluded_file=/tmp/excluded

  [ -f "$excluded_file" ] || return 0

  dpkg-query -W -f='${binary:Package}\n' 2>/dev/null | while IFS= read -r package; do
    [ -n "$package" ] || continue
    package_matches_patterns "$package" "$excluded_file" || continue

    dpkg-query -L "$package" 2>/dev/null | while IFS= read -r file; do
      cached_file="/tmp/php$file"
      if [ -f "$cached_file" ] || [ -L "$cached_file" ]; then
        sudo rm -f "$cached_file"
      elif [ -d "$cached_file" ]; then
        sudo rmdir "$cached_file" 2>/dev/null || true
      fi
    done
    sudo rm -f /tmp/php/var/lib/dpkg/info/"$package".* /tmp/php/var/lib/dpkg/info/"$package":*
  done
}

copy_package_info() {
  package=$1

  sudo mkdir -p /tmp/php/var/lib/dpkg/info
  sudo cp -a /var/lib/dpkg/info/"$package".* /tmp/php/var/lib/dpkg/info/ 2>/dev/null || true
  sudo cp -a /var/lib/dpkg/info/"$package":* /tmp/php/var/lib/dpkg/info/ 2>/dev/null || true
}

copy_cache_path() {
  local file

  file=$1

  if [ -d "$file" ] && ! [ -L "$file" ]; then
    sudo mkdir -p /tmp/php"$file"
    return 0
  fi

  [ -e "$file" ] || [ -L "$file" ] || return 0

  sudo mkdir -p /tmp/php"$(dirname "$file")"
  if [ -f "$file" ]; then
    sudo cp -a -l --parents "$file" /tmp/php 2>/dev/null || sudo cp -a --parents "$file" /tmp/php || true
  else
    sudo cp -a --parents "$file" /tmp/php || true
  fi
}

copy_package_files() {
  local file package
  package=$1

  copy_package_info "$package"
  dpkg -L "$package" 2>/dev/null | while IFS= read -r file; do
    copy_cache_path "$file"
  done
}

copy_required_package_files() {
  local package

  while IFS= read -r package; do
    [ -n "$package" ] && copy_package_files "$package"
  done < /tmp/required
}

copy_changed_files() {
  local after_file before_file changed_file copy_file excluded_file file

  before_file=/tmp/php-ubuntu-before-files
  after_file="$(mktemp)"
  changed_file="$(mktemp)"
  excluded_file="$(mktemp)"
  copy_file="$(mktemp)"

  write_filesystem_manifest "$after_file"
  if [ -f "$before_file" ]; then
    comm -13 "$before_file" "$after_file" | cut -f 1 > "$changed_file"
  else
    cut -f 1 "$after_file" > "$changed_file"
  fi
  LC_ALL=C sort -u "$changed_file" -o "$changed_file"
  write_excluded_package_files "$excluded_file"
  comm -23 "$changed_file" "$excluded_file" > "$copy_file"

  sudo mkdir -p /tmp/php
  while IFS= read -r file; do
    copy_cache_path "$file"
  done < "$copy_file"

  rm -f "$after_file" "$changed_file" "$excluded_file" "$copy_file"
}

rules_source_for_php_source() {
  case "$1" in
    packages)
      echo ondrej
      ;;
    php-builder)
      echo php-builder
      ;;
    *)
      echo "$1"
      ;;
  esac
}

write_package_patterns() {
  local arch base_file list_dir list_file output rules_source tmp_list type

  # shellcheck disable=SC1091
  . /etc/os-release
  type=$1
  output=$2
  base_file="${3:-}"
  arch="$(dpkg --print-architecture)"
  rules_source="$(rules_source_for_php_source "$source")"
  list_dir="$GITHUB_WORKSPACE"/scripts/"$type".d/"$rules_source"
  tmp_list="$(mktemp)"

  [ -n "$base_file" ] && [ -f "$base_file" ] && cat "$base_file" >> "$tmp_list"

  for list_file in "$list_dir"/ubuntu-"$VERSION_ID" "$list_dir"/ubuntu-"$VERSION_ID"-"$arch"; do
    [ -f "$list_file" ] && cat "$list_file" >> "$tmp_list"
  done

  sort -u "$tmp_list" | sudo tee "$output" >/dev/null
  rm -f "$tmp_list"
}

optimize_package() {
  remove_excluded_package_files
  remove_optional_extension_debug_symbols
  remove_dev_artifacts
}

cache_fpm_socket_placeholder() {
  fpm_socket=/run/php/php"${PHP_VERSION:?}"-fpm.sock
  sudo service php"$PHP_VERSION"-fpm stop >/dev/null 2>&1 || true
  sudo rm -f "$fpm_socket"
  sudo touch "$fpm_socket"
}

cache_fpm_socket_placeholder
source=packages
[ -s /tmp/php-ubuntu-source ] && source="$(cat /tmp/php-ubuntu-source)"
sudo apt-get clean || true
sudo rm -rf /var/cache/apt/archives/*.deb /var/cache/apt/archives/*.ddeb
sudo rm -f /tmp/php_"$PHP_VERSION$PHP_PKG_SUFFIX"+*.tar.zst
write_package_patterns required /tmp/required
write_package_patterns excluded /tmp/excluded "$GITHUB_WORKSPACE"/scripts/excluded
copy_changed_files
sudo mkdir -p /tmp/php/etc/apt/sources.list.d /tmp/php/etc/apt/trusted.gpg.d /tmp/php/var/lib/apt/lists /tmp/php/usr/share/keyrings
sudo touch /var/lib/dpkg/status-diff
copy_required_package_files
sudo LC_ALL=C.UTF-8 python3 "$GITHUB_WORKSPACE"/scripts/create_status.py
sudo mkdir -p /tmp/php/usr/sbin /tmp/php/var/lib/dpkg/
sudo cp /var/lib/dpkg/status-diff /tmp/php/var/lib/dpkg/
sudo cp "$GITHUB_WORKSPACE"/scripts/merge_status.py /tmp/php/usr/sbin/merge_status
cat /tmp/php/var/lib/dpkg/status-diff
if [ "$source" = "packages" ]; then
  sudo cp /etc/apt/sources.list.d/ondrej* /tmp/php/etc/apt/sources.list.d/
  sudo cp /etc/apt/trusted.gpg.d/ondrej* /tmp/php/etc/apt/trusted.gpg.d/
  sudo cp /var/lib/apt/lists/*ondrej* /tmp/php/var/lib/apt/lists/
  sudo cp -a /usr/share/keyrings/ondrej-php-keyring.gpg /tmp/php/usr/share/keyrings/ondrej-php-keyring.gpg
fi
sudo rm -rf /tmp/php/var/lib/dpkg/alternatives/* /tmp/php/var/lib/dpkg/status-old /tmp/php/var/lib/dpkg/status-orig
optimize_package
# shellcheck disable=SC1091
. /etc/os-release
SEMVER="$("php-config${PHP_VERSION:?}" --version)" || exit 1
SEMVER="${SEMVER%%-*}"
if [[ "$SEMVER" != "$PHP_VERSION".* || ! "$SEMVER" =~ ^[0-9]+\.[0-9]+\.[0-9]+([[:alpha:]]+[0-9]+)?$ ]]; then
  echo "Invalid PHP version for $PHP_VERSION: $SEMVER" >&2
  exit 1
fi
arch="$(arch)"
[[ "$arch" = "aarch64" || "$arch" = "arm64" ]] && ARCH_SUFFIX='_arm64' || ARCH_SUFFIX=''
build_path=/tmp/php_"$PHP_VERSION-$TS$PHP_PKG_SUFFIX"+ubuntu"$VERSION_ID$ARCH_SUFFIX".tar.zst
semver_build_path=/tmp/php_"$SEMVER-$TS$PHP_PKG_SUFFIX"+ubuntu"$VERSION_ID$ARCH_SUFFIX".tar.zst
(
  cd /tmp/php || exit 1
  sudo tar cf - ./* | zstd -22 -T0 --ultra > "$build_path"
  ln "$build_path" "$semver_build_path" || cp "$build_path" "$semver_build_path"
)
cd "$GITHUB_WORKSPACE" || exit 1
mkdir builds
sudo mv "$build_path" "$semver_build_path" ./builds
ls -laR ./builds
