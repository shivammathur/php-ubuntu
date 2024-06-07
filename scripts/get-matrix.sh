#!/usr/bin/env bash

json_array=()

IFS=' ' read -r -a php_version_array <<<"${PHP_VERSIONS:?}"
IFS=' ' read -r -a build_array <<<"${BUILDS:?}"
IFS=' ' read -r -a ts_array <<<"${TS:?}"
IFS=' ' read -r -a container_array <<<"${CONTAINERS:?}"

for php in "${php_version_array[@]}"; do
  for build in "${build_array[@]}"; do
    for ts in "${ts_array[@]}"; do
      for container in "${container_array[@]}"; do
        json_array+=("{\"php-versions\": \"$php\", \"builds\": \"$build\", \"ts\": \"$ts\", \"container\": \"$container\", \"os\": \"ubuntu-${container}\" }")
      done  
    done
  done
done

echo "matrix={\"include\":[$(echo "${json_array[@]}" | sed -e 's|} {|}, {|g')]}" >> "$GITHUB_OUTPUT"
