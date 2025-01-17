#!/usr/bin/env bash

json_array=()

IFS=' ' read -r -a php_version_array <<<"${PHP_VERSIONS:?}"
IFS=' ' read -r -a build_array <<<"${BUILDS:?}"
IFS=' ' read -r -a ts_array <<<"${TS:?}"
IFS=' ' read -r -a container_array <<<"${CONTAINERS:?}"

get_container_base() {
  [[ $1 = *arm64v8* ]] && echo "${BASE_OS_ARM:?}" || echo "${BASE_OS:?}"
}

get_os_version() {
  [[ $1 = *arm64v8* ]] && echo "${1##*:}-arm" || echo "${1##*:}"
}

for php in "${php_version_array[@]}"; do
  for build in "${build_array[@]}"; do
    for ts in "${ts_array[@]}"; do
      for os in "${container_array[@]}"; do
        os_base="$(get_container_base "$os")"
        os_version="ubuntu-$(get_os_version "$os")"
        json_array+=("{\"php-versions\": \"$php\", \"builds\": \"$build\", \"ts\": \"$ts\", \"container\": \"$os\", \"container-base\": \"$os_base\", \"os\": \"$os_version\" }")
      done  
    done
  done
done

echo "matrix={\"include\":[$(echo "${json_array[@]}" | sed -e 's|} {|}, {|g')]}" >> "$GITHUB_OUTPUT"
