#!/usr/bin/env bash
set -euo pipefail

reports_dir="${REPORTS_DIR:-reports}"
broken_versions_file='broken-versions.txt'
: > "$broken_versions_file"

shopt -s nullglob
reports=("$reports_dir"/*.env)
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

{
  echo '### Package test results'
  echo
  echo '| PHP | OS | Install | PHP smoke test | Packages | apt-get check |'
  echo '| --- | --- | --- | --- | --- | --- |'
} | append_summary

while IFS= read -r report; do
  php_version=
  os=
  broken=false
  apt_check_status=
  setup_outcome=
  php_test_outcome=
  apt_check_log=
  # shellcheck disable=SC1090
  source "$report"

  package_result=ok
  if [ "$broken" = true ]; then
    package_result=broken
    echo "$php_version" >> "$broken_versions_file"
    echo "Broken packages detected for PHP $php_version on $os"
  fi

  {
    echo "| $php_version | $os | $setup_outcome | $php_test_outcome | $package_result | $apt_check_status |"
  } | append_summary
done < <(printf '%s\n' "${reports[@]}" | sort)

sort -u "$broken_versions_file" -o "$broken_versions_file"

if [ ! -s "$broken_versions_file" ]; then
  {
    echo
    echo 'No broken packages detected.'
  } | append_summary
  echo 'No broken packages detected.'
  exit 0
fi

{
  echo
  echo '### Broken package details'
} | append_summary

while IFS= read -r report; do
  php_version=
  os=
  broken=false
  apt_check_status=
  apt_check_log=
  # shellcheck disable=SC1090
  source "$report"

  if [ "$broken" != true ]; then
    continue
  fi

  {
    echo
    echo "#### PHP $php_version on $os"
    echo
    echo "apt-get check status: $apt_check_status"
    echo
    echo '```text'
    if [ -n "$apt_check_log" ] && [ -f "$reports_dir/$apt_check_log" ]; then
      tail -n 120 "$reports_dir/$apt_check_log"
    else
      echo 'Package check log not found.'
    fi
    echo '```'
  } | append_summary
done < <(printf '%s\n' "${reports[@]}" | sort)

{
  echo
  echo '### Dispatched cache workflows'
  echo
  echo '| PHP | Workflow |'
  echo '| --- | --- |'
} | append_summary

while IFS= read -r php_version; do
  if [ "$php_version" = '8.6' ]; then
    workflow=cache-nightly.yml
  else
    workflow=cache-stable.yml
  fi

  echo "Dispatching $workflow for PHP $php_version"
  gh workflow run "$workflow" --repo "${REPO:?}" --ref "${REF:?}" -f php-versions="$php_version"
  echo "| $php_version | $workflow |" | append_summary
done < "$broken_versions_file"

echo "Dispatched cache workflow run(s) for: $(tr '\n' ' ' < "$broken_versions_file")"
exit 1
