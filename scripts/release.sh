add_assets() {
  ls -laR ./builds
  for asset in ./builds/*/*; do
    assets+=("$asset")
    if [[ ! "$(basename "$asset")" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
      cds_assets+=("$asset")
    fi
  done
}

release_cds() {
  sudo cp ./scripts/cds /usr/local/bin/cds && sudo sed -i "s|REPO|$GITHUB_REPOSITORY|" /usr/local/bin/cds && sudo chmod a+x /usr/local/bin/cds
  if [[ "$GITHUB_MESSAGE" != *skip-cloudsmith* ]]; then
    cp ./scripts/install.sh ./scripts/php-ubuntu.sh
    echo "${cds_assets[@]}" ./scripts/php-ubuntu.sh | xargs -n 1 -P 8 cds
  fi
}

install_awscli() {
  if ! command -v aws >/dev/null 2>&1; then
      pip3 install --upgrade awscli >/dev/null
  fi
}

clear_cf_cache() {
  curl -sS -X POST "https://api.cloudflare.com/client/v4/zones/$CF_CACHE_ZONE/purge_cache" \
      -H "Authorization: Bearer $CF_CACHE_KEY" -H "Content-Type: application/json" \
      --data '{"tags":["php-ubuntu"]}'
}

upload_to_setup_php_s3() {
  export AWS_ACCESS_KEY_ID="$SETUP_PHP_AWS_ACCESS_KEY_ID"
  export AWS_SECRET_ACCESS_KEY="$SETUP_PHP_AWS_SECRET_ACCESS_KEY"
  for asset in "$@"; do      
    aws --endpoint-url "$SETUP_PHP_AWS_S3_ENDPOINT" s3 cp "$asset" "s3://php-ubuntu/$(basename "$asset")" --only-show-errors || return 1
  done
  clear_cf_cache
}

upload_to_cloudflare_r2_s3() {
  export AWS_ACCESS_KEY_ID="$CF_R2_AWS_ACCESS_KEY_ID"
  export AWS_SECRET_ACCESS_KEY="$CF_R2_AWS_SECRET_ACCESS_KEY"
  for asset in "$@"; do
    aws --endpoint-url "$CF_R2_AWS_S3_ENDPOINT" s3 cp "$asset" "s3://php-ubuntu/$(basename "$asset")" --only-show-errors || return 1
  done
}

release_distribute() {
  install_awscli
  release_cds
  upload_to_setup_php_s3 "${cds_assets[@]}" ./scripts/install.sh || return 1
  upload_to_cloudflare_r2_s3 "${cds_assets[@]}" ./scripts/install.sh || return 1
}

release_create() {
  release_distribute
  gh release create "builds" ./scripts/install.sh "${assets[@]}" -n "builds $version" -t "builds"
}

release_upload() {
  gh release download -p "build.log" || true
  gh release upload "builds" ./scripts/install.sh --clobber
  for asset in "${assets[@]}" ./scripts/install.sh; do
    gh release upload "builds" "$asset" --clobber
  done  
  release_distribute
}

log() {
  echo "$version" | sudo tee -a build.log
  gh release upload "builds" build.log --clobber
}

version=$(date '+%Y.%m.%d')
assets=()
cds_assets=()
rm -rf ./builds/zstd*
add_assets
cd "$GITHUB_WORKSPACE" || exit 1
if ! gh release view builds; then
  release_create
else
  release_upload
fi
log
