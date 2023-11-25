add_assets() {
  ls -laR ./builds
  for asset in ./builds/*/*; do
    assets+=("$asset")
  done
}

release_cds() {
  sudo cp ./scripts/cds /usr/local/bin/cds && sudo sed -i "s|REPO|$GITHUB_REPOSITORY|" /usr/local/bin/cds && sudo chmod a+x /usr/local/bin/cds
  if [[ "$GITHUB_MESSAGE" != *skip-cloudsmith* ]]; then
    cp ./scripts/install.sh ./scripts/php-ubuntu.sh
    echo "${assets[@]}" ./scripts/php-ubuntu.sh | xargs -n 1 -P 8 cds
  fi
}

release_create() {
  release_cds
  gh release create "builds" ./scripts/install.sh "${assets[@]}" -n "builds $version" -t "builds"
}

release_upload() {
  gh release download -p "build.log" || true
  gh release upload "builds" ./scripts/install.sh --clobber
  for asset in "${assets[@]}" ./scripts/install.sh; do
    gh release upload "builds" "$asset" --clobber
  done  
  release_cds
}

log() {
  echo "$version" | sudo tee -a build.log
  gh release upload "builds" build.log --clobber
}

version=$(date '+%Y.%m.%d')
assets=()
rm -rf ./builds/zstd*
add_assets
cd "$GITHUB_WORKSPACE" || exit 1
if ! gh release view builds; then
  release_create
else
  release_upload
fi
log
