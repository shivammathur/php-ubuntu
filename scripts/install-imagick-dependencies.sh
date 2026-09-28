#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
. /etc/os-release

case "$VERSION_ID" in
  24.04|26.04)
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      libheif-plugin-aomdec libheif-plugin-aomenc libheif-plugin-libde265
    ;;
esac
