#!/usr/bin/env bash
set -euo pipefail

reports_dir="${REPORTS_DIR:-reports}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

broken_file="$tmp_dir/broken.tsv"
dispatch_file="$tmp_dir/dispatch.tsv"
grouped_dispatch_file="$tmp_dir/grouped-dispatch.tsv"
: > "$broken_file"
: > "$dispatch_file"

reports=()
while IFS= read -r report; do
  reports+=("$report")
done < <(find "$reports_dir" -type f -name '*.env' 2>/dev/null | sort)
if [ "${#reports[@]}" -eq 0 ]; then
  echo 'No package check reports found.'
  exit 1
fi

append_summary() {
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    cat >> "$GITHUB_STEP_SUMMARY"
  else
    cat
  fi
}

workflow_for_php() {
  if [ "$1" = '8.6' ]; then
    echo 'cache-nightly.yml'
  else
    echo 'cache-stable.yml'
  fi
}

container_for_os() {
  local os=$1
  local version

  case "$os" in
    ubuntu-*-arm)
      version="${os#ubuntu-}"
      version="${version%-arm}"
      echo "arm64v8/ubuntu:$version"
      ;;
    ubuntu-*)
      version="${os#ubuntu-}"
      echo "ubuntu:$version"
      ;;
    *)
      echo "Unsupported OS label: $os" >&2
      return 1
      ;;
  esac
}

{
  echo '### Package test results'
  echo
  echo '| PHP | OS | Install | PHP smoke test | Packages | apt-get check | dpkg metadata |'
  echo '| --- | --- | --- | --- | --- | --- | --- |'
} | append_summary

for report in "${reports[@]}"; do
  php_version=
  os=
  broken=false
  apt_check_status=
  metadata_check_status=
  setup_outcome=
  php_test_outcome=
  apt_check_log=
  # shellcheck disable=SC1090
  source "$report"

  package_result=ok
  if [ "$broken" = true ]; then
    package_result=broken
    printf '%s\t%s\t%s\n' "$php_version" "$os" "$report" >> "$broken_file"
    echo "Broken packages detected for PHP $php_version on $os"
  fi

  {
    echo "| $php_version | $os | $setup_outcome | $php_test_outcome | $package_result | $apt_check_status | $metadata_check_status |"
  } | append_summary
done

if [ ! -s "$broken_file" ]; then
  {
    echo
    echo 'No broken packages detected.'
  } | append_summary
  echo 'No broken packages detected.'
  exit 0
fi

sort -u -k1,2 "$broken_file" > "$tmp_dir/unique-broken.tsv"

{
  echo
  echo '### Cache failures'
  echo
  echo '| PHP | OS | Container |'
  echo '| --- | --- | --- |'
} | append_summary

while IFS=$'\t' read -r php_version os _report; do
  container="$(container_for_os "$os")"
  workflow="$(workflow_for_php "$php_version")"
  printf '%s\t%s\t%s\n' "$php_version" "$workflow" "$container" >> "$dispatch_file"
  echo "| $php_version | $os | $container |" | append_summary
done < "$tmp_dir/unique-broken.tsv"

{
  echo
  echo '### Broken package details'
} | append_summary

while IFS=$'\t' read -r php_version os report; do
  apt_check_status=
  metadata_check_status=
  apt_check_log=
  # shellcheck disable=SC1090
  source "$report"

  {
    echo
    echo "#### PHP $php_version on $os"
    echo
    echo "apt-get check status: $apt_check_status"
    echo "dpkg metadata check status: $metadata_check_status"
    echo
    echo '```text'
    if [ -n "$apt_check_log" ] && [ -f "$(dirname "$report")/$apt_check_log" ]; then
      tail -n 120 "$(dirname "$report")/$apt_check_log"
    else
      echo 'Package check log not found.'
    fi
    echo '```'
  } | append_summary
done < "$tmp_dir/unique-broken.tsv"

awk -F '\t' '
  {
    key = $1 "\t" $2
    container_key = key "\t" $3
    if (!seen[container_key]++) {
      containers[key] = containers[key] ? containers[key] " " $3 : $3
    }
  }
  END {
    for (key in containers) {
      print key "\t" containers[key]
    }
  }
' "$dispatch_file" | sort > "$grouped_dispatch_file"

{
  echo
  echo '### Dispatched cache workflows'
  echo
  echo '| PHP | Workflow | Containers |'
  echo '| --- | --- | --- |'
} | append_summary

while IFS=$'\t' read -r php_version workflow containers; do
  echo "Dispatching $workflow for PHP $php_version on containers: $containers"
  gh workflow run "$workflow" --repo "${REPO:?}" --ref "${REF:?}" -f php-versions="$php_version" -f containers="$containers"
  echo "| $php_version | $workflow | $containers |" | append_summary
done < "$grouped_dispatch_file"

echo "Dispatched cache workflow run(s)."
exit 1
