#!/usr/bin/env bash
set -euo pipefail

php_version="${1:?PHP version is required}"
os="${2:?OS is required}"
setup_outcome="${3:-skipped}"
php_test_outcome="${4:-skipped}"

[ -n "$setup_outcome" ] || setup_outcome=skipped
[ -n "$php_test_outcome" ] || php_test_outcome=skipped

report_dir="${REPORT_DIR:-reports}"
report_name="$php_version-$os"
apt_log="$report_dir/$report_name.apt-check.log"
report_file="$report_dir/$report_name.env"

mkdir -p "$report_dir"

set +e
sudo apt-get check 2>&1 | tee "$apt_log"
apt_check_status=${PIPESTATUS[0]}
set -e

if [ "$apt_check_status" -eq 0 ]; then
  apt_check_status=0
  broken=false
else
  broken=true
fi

if [ ! -s "$apt_log" ]; then
  echo 'apt-get check completed with no output.' > "$apt_log"
fi

{
  echo "php_version=$php_version"
  echo "os=$os"
  echo "broken=$broken"
  echo "apt_check_status=$apt_check_status"
  echo "setup_outcome=$setup_outcome"
  echo "php_test_outcome=$php_test_outcome"
  echo "apt_check_log=$(basename "$apt_log")"
} > "$report_file"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "broken=$broken"
    echo "apt_check_status=$apt_check_status"
    echo "report=$report_file"
  } >> "$GITHUB_OUTPUT"
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### PHP $php_version on $os"
    echo
    echo "| Check | Result |"
    echo "| --- | --- |"
    echo "| Install | $setup_outcome |"
    echo "| PHP smoke test | $php_test_outcome |"
    echo "| Packages | $([ "$broken" = true ] && echo broken || echo ok) |"
    echo "| apt-get check status | $apt_check_status |"
    echo
    echo "#### Package check"
    echo
    echo '```text'
    tail -n 80 "$apt_log"
    echo '```'
  } >> "$GITHUB_STEP_SUMMARY"
fi
