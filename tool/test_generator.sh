#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
package_config="$repo_root/.dart_tool/package_config.json"

if [[ ! -f "$package_config" ]]; then
  echo "Missing $package_config; run 'puro flutter pub get' first." >&2
  exit 1
fi

test_root_uri="$(
  jq -er '.packages[] | select(.name == "test") | .rootUri' "$package_config"
)" || {
  echo "The test package is not present in $package_config." >&2
  exit 1
}

case "$test_root_uri" in
  file://*) test_root="${test_root_uri#file://}" ;;
  *)
    echo "Unsupported test package URI: $test_root_uri" >&2
    exit 1
    ;;
esac

test_runner="$test_root/bin/test.dart"
if [[ ! -f "$test_runner" ]]; then
  echo "Test runner not found at $test_runner." >&2
  exit 1
fi

cd "$repo_root/native_sqlite_generator"
if command -v puro >/dev/null 2>&1; then
  exec puro dart --packages="$package_config" "$test_runner" "$@"
fi
exec dart --packages="$package_config" "$test_runner" "$@"
