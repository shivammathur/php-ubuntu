#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${ZSTD_DIR:-}" || "$ZSTD_DIR" = "zstd-" || "$ZSTD_DIR" = "zstd-null" ]]; then
  if ! zstd_version=$(curl -fsSL --retry 3 -H "${TOKEN:+Authorization: Bearer $TOKEN}" \
    https://api.github.com/repos/meta/zstd/releases/latest | jq -er '.tag_name | ltrimstr("v") | select(length > 0)'); then
    zstd_version=1.6.0
    echo "Could not resolve the latest zstd release. Using v$zstd_version." >&2
  fi
  ZSTD_DIR="zstd-$zstd_version"
fi

artifact="$ZSTD_DIR-${CONTAINER//[\/:]/-}.tar.gz"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p /opt/zstd
if [[ "${USE_CACHE:-true}" = true ]] && curl -fsSL --retry 3 -o "$work_dir/$artifact" \
  "https://github.com/shivammathur/php-ubuntu/releases/download/builds/$artifact"; then
  echo "Installing $artifact from the builds release"
  tar -xzf "$work_dir/$artifact" -C /opt/zstd
  chmod -R a+x /opt/zstd/bin
else
  echo "Building $ZSTD_DIR from source"
  apt-get install zlib1g-dev liblzma-dev liblz4-dev -y
  curl -fsSL --retry 3 -o "$work_dir/src.tar.gz" \
    "https://github.com/meta/zstd/releases/download/v${ZSTD_DIR#zstd-}/$ZSTD_DIR.tar.gz"
  tar -xzf "$work_dir/src.tar.gz" -C "$work_dir"
  make -C "$work_dir/$ZSTD_DIR" install -j"$(nproc)" PREFIX=/opt/zstd
  apt-get purge zlib1g-dev liblzma-dev liblz4-dev -y
fi
ln -sf /opt/zstd/bin/* /usr/local/bin
zstd -V
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "artifact=$artifact" >> "$GITHUB_OUTPUT"
fi
