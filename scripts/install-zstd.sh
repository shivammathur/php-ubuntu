mkdir -p /opt/zstd
if [[ -z "${ZSTD_DIR:-}" || "$ZSTD_DIR" = "zstd-" || "$ZSTD_DIR" = "zstd-null" ]]; then
  zstd_version="$(curl -fsSL --retry 5 --retry-all-errors https://api.github.com/repos/facebook/zstd/releases/latest | jq -r '.tag_name // empty | ltrimstr("v")' || true)"
  ZSTD_DIR="zstd-${zstd_version:-1.5.7}"
fi
curl -o /tmp/zstd.tar.gz -sL "https://github.com/shivammathur/php-ubuntu/releases/download/builds/${ZSTD_DIR:?}-${CONTAINER//[\/:]/-}.tar.gz"
tar -xzf /tmp/zstd.tar.gz -C /opt/zstd || true
if ! [ -e /opt/zstd/bin ]; then
  apt-get install zlib1g-dev liblzma-dev liblz4-dev -y
  curl -o /tmp/zstd-src.tar.gz -fsSL --retry 5 --retry-all-errors https://github.com/facebook/zstd/releases/latest/download/"$ZSTD_DIR".tar.gz
  tar -xzf /tmp/zstd-src.tar.gz -C /tmp
  (
    cd /tmp/"$ZSTD_DIR" || exit 1
    make install -j"$(nproc)" PREFIX=/opt/zstd
  )
  apt-get purge zlib1g-dev liblzma-dev liblz4-dev -y
else
  chmod -R a+x /opt/zstd/bin
fi
ln -sf /opt/zstd/bin/* /usr/local/bin
rm -rf /tmp/zstd*
zstd -V
