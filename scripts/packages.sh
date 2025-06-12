#!/usr/bin/env bash

purge_packages() {
    packages=("$@")
    for package in "${packages[@]}"; do
      DEBIAN_FRONTEND=noninteractive apt-get purge -y "$package" || true
    done
}

add_packages() {
    packages=("$@")
    for package in "${packages[@]}"; do
      DEBIAN_FRONTEND=noninteractive apt-get install -y "$package" || true
    done
}

get() {
  local mode=$1
  local file_path=$2
  shift 2
  links=("$@")
  if [ "$mode" = "-s" ]; then
    curl -sL "${links[0]}"
  else
    for link in "${links[@]}"; do
      status_code=$(curl -w "%{http_code}" -o "$file_path" -sL "$link")
      [ "$status_code" = "200" ] && break
    done
  fi
}

ubuntu_fingerprint() {
  local ppa=$1
  get -s -n "" "${lp_api[@]/%//~${ppa%/*}/+archive/${ppa##*/}}" | jq -r '.signing_key_fingerprint'
}

get_launchpad_key() {
  local pa=$1
  local key_file=$2
  sks=(
    'https://keyserver.ubuntu.com'
    'https://pgp.mit.edu'
    'https://keys.openpgp.org'
  )
  lp_api=(
    'https://api.launchpad.net/1.0'
    'https://api.launchpad.net/devel'
  )  
  fingerprint="$(get -s "" "${lp_api[@]/%//~${ppa%/*}/+archive/${ppa##*/}}" | jq -r '.signing_key_fingerprint')"
  sks_params="op=get&options=mr&exact=on&search=0x$fingerprint"
  key_urls=("${sks[@]/%/\/pks\/lookup\?"$sks_params"}")
  get -q "$key_file" "${key_urls[@]}"
  if [[ "$(file "$key_file")" =~ .*('Public-Key (old)'|'Secret-Key') ]]; then
    gpg --batch --yes --dearmor "$key_file" && mv "$key_file".gpg "$key_file"
  fi
}

add_ppa_helper() {
  local ppa=$1
  local branches=$2
  ppa_url="https://ppa.launchpadcontent.net/$ppa/ubuntu"
  key_file=/usr/share/keyrings/"${ppa/\//-}"-keyring.gpg
  list_dir=/etc/apt/sources.list.d
  get_launchpad_key "$ppa" "$key_file"
  . /etc/os-release
  sudo rm -rf "$list_dir"/"${ppa/\//-}".list || true
  echo "deb [arch="$(dpkg --print-architecture)" signed-by=$key_file] $ppa_url $VERSION_CODENAME $branches" | tee -a "$list_dir"/"${ppa%%/*}"-"$ID"-"${ppa#*/}"-"$VERSION_CODENAME".list
}

add_ppa() {
  . /etc/os-release
  export _APTMGR=apt-get
  apt-get update && apt-get install -y curl sudo file jq gnupg
  add_ppa_helper apt-fast/stable main
  add_ppa_helper git-core/ppa main
  add_ppa_helper ondrej/php main
  add_ppa_helper ondrej/php main/debug
  curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
  curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
  echo "deb https://apt.postgresql.org/pub/repos/apt/ $VERSION_CODENAME-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list
  echo "deb [arch=$arch] https://packages.microsoft.com/ubuntu/$VERSION_ID/prod $VERSION_CODENAME main" | tee /etc/apt/sources.list.d/microsoft-prod.list
  apt-get update
}

arch=$(dpkg --print-architecture)
