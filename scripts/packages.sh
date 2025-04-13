#!/usr/bin/env bash

purge_packages() {
    packages=("$@")
    for package in "${packages[@]}"; do
      DEBIAN_FRONTEND=noninteractive apt-get purge -y "$package" || true
    done
}

purge_packages() {
    packages=("$@")
    for package in "${packages[@]}"; do
      DEBIAN_FRONTEND=noninteractive apt-get purge -y "$package" || true
    done
}

get() {
  mode=$1
  file_path=$2
  shift 2
  links=("$@")
  if [ "$mode" = "-s" ]; then
    sudo curl -sL "${links[0]}"
  else
    for link in "${links[@]}"; do
      status_code=$(sudo curl -w "%{http_code}" -o "$file_path" -sL "$link")
      [ "$status_code" = "200" ] && break
    done
  fi
}

get_launchpad_key() {
  ppa=$1
  branches=$2
  sks=(
    'https://keyserver.ubuntu.com'
    'https://pgp.mit.edu'
    'https://keys.openpgp.org'
  )
  lp_api=(
    'https://api.launchpad.net/1.0'
    'https://api.launchpad.net/devel'
  )
  key_file=/usr/share/keyrings/"${ppa/\//-}"-keyring.gpg
  fingerprint="$(get -s "" "${lp_api[@]/%//~${ppa%/*}/+archive/${ppa##*/}}" | jq -r '.signing_key_fingerprint')"
  sks_params="op=get&options=mr&exact=on&search=0x$fingerprint"
  key_urls=("${sks[@]/%/\/pks\/lookup\?"$sks_params"}")
  get -q "$key_file" "${key_urls[@]}"
  if [[ "$(file "$key_file")" =~ .*('Public-Key (old)'|'Secret-Key') ]]; then
    sudo gpg --batch --yes --dearmor "$key_file"  && sudo mv "$key_file".gpg "$key_file"
  fi
}

add_ondrej_ppa() {
  get_launchpad_key ondrej/php main
  ondrej_ppa_source="deb [arch=$arch signed-by=/usr/share/keyrings/ondrej-php-keyring.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu $VERSION_CODENAME main"
  echo "$ondrej_ppa_source" | tee /etc/apt/sources.list.d/ondrej-php.list
  [ "${BUILDS:?}" = "debug" ] && echo "$ondrej_ppa_source/debug" | tee -a /etc/apt/sources.list.d/ondrej-php.list
}

add_ppa() {
  . /etc/os-release
  export _APTMGR=apt-get
  apt-get update && apt-get install -y curl sudo file jq software-properties-common
  add-apt-repository ppa:git-core/ppa
  add-apt-repository ppa:apt-fast/stable
  add_ondrej_ppa
  curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
  curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
  echo "deb https://apt.postgresql.org/pub/repos/apt/ $VERSION_CODENAME-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list
  echo "deb [arch=$arch] https://packages.microsoft.com/ubuntu/$VERSION_ID/prod $VERSION_CODENAME main" | tee /etc/apt/sources.list.d/microsoft-prod.list
  apt-get update
}

arch=$(dpkg --print-architecture)
