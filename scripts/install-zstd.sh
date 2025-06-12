mkdir -p /opt/zstd
curl -o /tmp/zstd.tar.gz -sL "https://github.com/shivammathur/php-ubuntu/releases/download/builds/${ZSTD_DIR:?}-${CONTAINER//[\/:]/-}.tar.gz"
tar -xzf /tmp/zstd.tar.gz -C /opt/zstd || true
if ! [ -e /opt/zstd/bin ]; then
  apt-get install zlib1g-dev liblzma-dev liblz4-dev -y
  curl -o /tmp/zstd-src.tar.gz -sL https://github.com/facebook/zstd/releases/latest/download/"$ZSTD_DIR".tar.gz
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
