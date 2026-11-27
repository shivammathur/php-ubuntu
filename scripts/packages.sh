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
  ppa_uri="~${ppa%/*}/+archive/ubuntu/${ppa##*/}"
  get -s "" "${lp_api[0]}/$ppa_uri" | jq -er '.signing_key_fingerprint' 2>/dev/null \
  || get -s "" "${lp_api[1]}/$ppa_uri" | jq -er '.signing_key_fingerprint' 2>/dev/null \
  || get -s "" "$ppa_sp/keys/$ppa.fingerprint"
}

get_launchpad_key() {
  local ppa=$1
  local key_file=$2
  fingerprint="$("${ID}"_fingerprint "$ppa")"
  sks_params="op=get&options=mr&exact=on&search=0x$fingerprint"
  key_urls=("${sks[@]/%/\/pks\/lookup\?"$sks_params"}")
  key_urls+=("$ppa_sp/keys/$ppa.gpg")
  get -q "$key_file" "${key_urls[@]}"
  if [[ "$(file "$key_file")" =~ .*('Public-Key (old)'|'Secret-Key') ]]; then
    gpg --batch --yes --dearmor "$key_file" && mv "$key_file".gpg "$key_file"
  fi
}

get_sources_format() {
  if [ -n "$sources_format" ]; then
    echo "$sources_format"
    return
  fi
  sources_format=deb
  if [ -e "$list_dir"/ubuntu.sources ] || [ -e "$list_dir"/debian.sources ]; then
    sources_format="deb822"
  elif ! [[ "$ID" =~ ubuntu|debian ]]; then
    find "$list_dir" -type f -name '*.sources' | grep -q . && sources_format="deb822"
  fi
  echo "$sources_format"
}

merge_components() {
  local out=() t
  for t in $1 $2; do [[ $t && " ${out[*]} " != *" $t "* ]] && out+=("$t"); done
  printf '%s\n' "${out[*]}"
}

write_source() {
  local ppa=$1 branches=$2 ppa_url=$3 key_file=$4 list_format
  local list_dir=/etc/apt/sources.list.d
  sudo rm -f "$list_dir"/"${ppa/\//-}".list
  list_format="$(get_sources_format)"
  local list_basename="${ppa%%/*}"-"$ID"-"${ppa#*/}"-"$VERSION_CODENAME"
  local list_path
  local components="$branches"
  if [ "$list_format" = "deb822" ]; then
    list_path="$list_dir"/"$list_basename".sources
    if [ -e "$list_path" ]; then
      local current_components
      current_components="$(grep -E '^Components:' "$list_path" | head -n 1 | cut -d ':' -f 2 | xargs)"
      components="$(merge_components "$current_components" "$branches")"
    fi
    [ -n "$components" ] || components="$branches"
    cat <<EOF | sudo tee "$list_path" >/dev/null
Types: deb
URIs: $ppa_url
Suites: $VERSION_CODENAME
Components: $components
Architectures: $arch
Signed-By: $key_file
EOF
  else
    list_path="$list_dir"/"$list_basename".list
    echo "deb [arch=$arch signed-by=$key_file] $ppa_url $VERSION_CODENAME $components" | sudo tee "$list_path" >/dev/null 2>&1
  fi
}

add_ppa_helper() {
  local ppa=$1 key_file="/usr/share/keyrings/${1/\//-}-keyring.gpg"
  get_launchpad_key "$ppa" "$key_file"
  write_source "$ppa" "$2" "https://ppa.launchpadcontent.net/$ppa/ubuntu" "$key_file"
}

add_sury_source() (
  local mirrors=/etc/apt/setup-php-sury-mirrors.txt
  local key=/usr/share/keyrings/sury-php-keyring.gpg
  local fingerprint=15058500A0235D97F5D10063B188E2B695BD4743
  local tmp url
  tmp=$(mktemp -d) || return 1
  trap 'rm -rf "$tmp"' EXIT
  local query="/pks/lookup?op=get&options=mr&exact=on&search=0x$fingerprint"
  for url in https://packages.sury.org/php/apt.gpg "$ppa_sp/keys/sury/php.gpg" "${sks[@]/%/"$query"}"; do
    if curl -fsSL --connect-timeout 5 --max-time 15 "$url" -o "$tmp/key" &&
       gpg --batch --with-colons --show-keys "$tmp/key" | awk -F: '$1 == "fpr" {print $10; exit}' | grep -Fxq "$fingerprint"; then
      gpg --batch --yes --dearmor -o "$tmp/key.gpg" "$tmp/key" || return 1
      install -m 644 "$tmp/key.gpg" "$key" || return 1
      break
    fi
  done
  [[ -s "$tmp/key.gpg" ]] || return 1
  install -m 644 ./scripts/sury-mirrors "$mirrors" || return 1
  write_source setup-php/sury main "mirror+file:$mirrors" "$key"
)

add_ppa() {  
  apt-get update && apt-get install -y curl sudo file jq gnupg
  add_ppa_helper git-core/ppa main
  add_sury_source || return 1
  curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
  curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
  echo "deb https://apt.postgresql.org/pub/repos/apt/ $VERSION_CODENAME-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list
  echo "deb [arch=$arch] https://packages.microsoft.com/ubuntu/$VERSION_ID/prod $VERSION_CODENAME main" | tee /etc/apt/sources.list.d/microsoft-prod.list
  apt-get update
}

. /etc/os-release
sources_format=
sks=(
  'https://keyserver.ubuntu.com'
  'https://pgp.mit.edu'
  'https://keys.openpgp.org'
)
ppa_sp='https://ppa.setup-php.com'
lp_api=(
  'https://api.launchpad.net/1.0'
  'https://api.launchpad.net/devel'
)
arch=$(dpkg --print-architecture)
