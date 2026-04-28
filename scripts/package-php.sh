#!/usr/bin/env bash

cd / || exit 1
[ "${BUILDS:?}" = "debug" ] && PHP_PKG_SUFFIX=-dbgsym

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

verify_elf_dependencies() {
  missing_file=$(mktemp)
  library_path="/tmp/php/usr/lib/$lib_subdir:/tmp/php/lib/$lib_subdir:/tmp/php/usr/lib:/tmp/php/usr/lib/$lib_subdir/samba"

  while IFS= read -r -d '' file; do
    if readelf -d "$file" 2>/dev/null | grep -q 'NEEDED'; then
      LD_LIBRARY_PATH="$library_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ldd "$file" 2>/dev/null | awk -v file="$file" '/not found/ { print file ": " $0 }' >> "$missing_file"
    fi
  done < <(find /tmp/php -type f -print0)

  if [ -s "$missing_file" ]; then
    cat "$missing_file"
    rm -f "$missing_file"
    exit 1
  fi
  rm -f "$missing_file"
}

optimize_package() {
  remove_optional_extension_debug_symbols
  remove_dev_artifacts
  verify_elf_dependencies
}

ls -la /
for dir_path in /bin /lib /lib64 /sbin /usr /var /run/php; do
  [ -d "$dir_path" ] && git add "$dir_path"
done
find /etc -maxdepth 1 -mindepth 1 -type d -exec git add {} \;
git commit -m "installed php"
mkdir -p /tmp/php/etc/apt/sources.list.d /tmp/php/etc/apt/trusted.gpg.d /tmp/php/var/lib/apt/lists /tmp/php/usr/share/keyrings
for file in $(git log -p -n 1 --name-only | sed 's/^.*\(\s\).*$/\1/' | xargs -L1 echo); do
  if [ -e "$file" ]; then
    sudo cp -r -p --parents "$file" /tmp/php || true
  fi
done
lib_subdir="$(uname -m)-linux-gnu"
sudo touch /var/lib/dpkg/status-diff
sudo cp "$GITHUB_WORKSPACE"/scripts/required /tmp/required
sudo LC_ALL=C.UTF-8 python3 "$GITHUB_WORKSPACE"/scripts/create_status.py
sudo mkdir -p /tmp/php/usr/sbin /tmp/php/var/lib/dpkg/
sudo cp /var/lib/dpkg/status-diff /tmp/php/var/lib/dpkg/
sudo cp "$GITHUB_WORKSPACE"/scripts/merge_status.py /tmp/php/usr/sbin/merge_status
cat /tmp/php/var/lib/dpkg/status-diff
sudo cp /etc/apt/sources.list.d/ondrej* /tmp/php/etc/apt/sources.list.d/
sudo cp /etc/apt/trusted.gpg.d/ondrej* /tmp/php/etc/apt/trusted.gpg.d/
sudo cp /var/lib/apt/lists/*ondrej* /tmp/php/var/lib/apt/lists/
sudo cp -a /usr/lib/"$lib_subdir"/libpcre* /tmp/php/usr/lib/"$lib_subdir"/
sudo cp -a /lib/"$lib_subdir"/libpcre* /tmp/php/usr/lib/"$lib_subdir"/
sudo cp -a /usr/share/keyrings/ondrej-php-keyring.gpg /tmp/php/usr/share/keyrings/ondrej-php-keyring.gpg
sudo rm -rf /tmp/php/var/lib/dpkg/alternatives/* /tmp/php/var/lib/dpkg/status-old /tmp/php/var/lib/dpkg/status-orig
optimize_package
. /etc/os-release
SEMVER="$(php -v | head -n 1 | cut -f 2 -d ' ' | cut -f 1 -d '-')"
arch="$(arch)"
[[ "$arch" = "aarch64" || "$arch" = "arm64" ]] && ARCH_SUFFIX='_arm64' || ARCH_SUFFIX=''
build_path=/tmp/php_"$PHP_VERSION-$TS$PHP_PKG_SUFFIX"+ubuntu"$VERSION_ID$ARCH_SUFFIX".tar.zst
semver_build_path=/tmp/php_"$SEMVER-$TS$PHP_PKG_SUFFIX"+ubuntu"$VERSION_ID$ARCH_SUFFIX".tar.zst
(
  cd /tmp/php || exit 1
  sudo tar cf - ./* | zstd -22 -T0 --ultra > "$build_path"
  cp "$build_path" "$semver_build_path"
)
cd "$GITHUB_WORKSPACE" || exit 1
mkdir builds
sudo mv "$build_path" "$semver_build_path" ./builds
ls -laR ./builds
