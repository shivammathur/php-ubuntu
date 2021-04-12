mkdir -p /opt/zstd
zstd_url=$(curl -sL https://api.github.com/repos/"$REPO"/actions/artifacts | jq -r --arg zstd_dir "${ZSTD_DIR:?}-ubuntu${CONTAINER:?}" '.artifacts[] | select(.name=="\($zstd_dir)").archive_download_url' 2>/dev/null | head -n 1)
if [ "x$zstd_url" = "x" ]; then
  apt-get install zlib1g liblzma-dev liblz4-dev -y
  curl -o /tmp/zstd.tar.gz -sL https://github.com/facebook/zstd/releases/latest/download/"$ZSTD_DIR".tar.gz
  tar -xzf /tmp/zstd.tar.gz -C /tmp
  (
    cd /tmp/"$ZSTD_DIR" || exit 1
    make install -j"$(nproc)" PREFIX=/opt/zstd
  )
else
  curl -u "$USER":"$TOKEN" -o /tmp/zstd.zip -sL "$zstd_url"
  ls /tmp
  unzip /tmp/zstd.zip -d /opt/zstd
  chmod -R a+x /opt/zstd/bin
fi
ln -sf /opt/zstd/bin/* /usr/local/bin
rm -rf /tmp/zstd*
zstd -V