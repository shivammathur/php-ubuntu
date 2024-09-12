cd / || exit 1
[ "${BUILDS:?}" = "debug" ] && PHP_PKG_SUFFIX=-dbgsym
git add /bin /lib /lib64 /sbin /usr /var /run/php
find /etc -maxdepth 1 -mindepth 1 -type d -exec git add {} \;
git commit -m "installed php"
mkdir -p /tmp/php/etc/apt/sources.list.d /tmp/php/etc/apt/trusted.gpg.d /tmp/php/var/lib/apt/lists
for file in $(git log -p -n 1 --name-only | sed 's/^.*\(\s\).*$/\1/' | xargs -L1 echo); do
  if [ -e "$file" ]; then
    sudo cp -r -p --parents "$file" /tmp/php || true
  fi
done
sudo touch /var/lib/dpkg/status-diff
sudo cp "$GITHUB_WORKSPACE"/scripts/required /tmp/required
sudo LC_ALL=C.UTF-8 python3 "$GITHUB_WORKSPACE"/scripts/create_status.py
sudo cp /var/lib/dpkg/status-diff /tmp/php/var/lib/dpkg/
sudo mkdir -p /tmp/php/usr/sbin
sudo cp "$GITHUB_WORKSPACE"/scripts/merge_status.py /tmp/php/usr/sbin/merge_status
cat /tmp/php/var/lib/dpkg/status-diff
sudo cp /etc/apt/sources.list.d/ondrej* /tmp/php/etc/apt/sources.list.d/
sudo cp /etc/apt/trusted.gpg.d/ondrej* /tmp/php/etc/apt/trusted.gpg.d/
sudo cp /var/lib/apt/lists/*ondrej* /tmp/php/var/lib/apt/lists/
sudo cp -a /usr/lib/x86_64-linux-gnu/libpcre* /tmp/php/usr/lib/x86_64-linux-gnu/
sudo cp -a /lib/x86_64-linux-gnu/libpcre* /tmp/php/usr/lib/x86_64-linux-gnu/
sudo rm -rf /tmp/php/var/lib/dpkg/alternatives/* /tmp/php/var/lib/dpkg/status-old /tmp/php/var/lib/dpkg/status-orig
. /etc/os-release
SEMVER="$(php -v | head -n 1 | cut -f 2 -d ' ' | cut -f 1 -d '-')"
(
  cd /tmp/php || exit 1
  sudo tar cf - ./* | zstd -22 -T0 --ultra > ../php_"$PHP_VERSION-$TS$PHP_PKG_SUFFIX"+ubuntu"$VERSION_ID".tar.zst
  cp ../php_"$PHP_VERSION-$TS$PHP_PKG_SUFFIX"+ubuntu"$VERSION_ID".tar.zst ../php_"$SEMVER-$TS$PHP_PKG_SUFFIX"+ubuntu"$VERSION_ID".tar.zst
)
cd "$GITHUB_WORKSPACE" || exit 1
mkdir builds
sudo mv /tmp/*.zst ./builds
ls -laR ./builds
