#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v puro >/dev/null 2>&1; then
  flutter=(puro flutter)
else
  flutter=(flutter)
fi

cd "$repo_root"
"${flutter[@]}" pub get

cd "$repo_root/example"
"${flutter[@]}" pub run build_runner build
"${flutter[@]}" analyze
"${flutter[@]}" test

if [[ "${NATIVE_SQLITE_CHECK_GENERATED_DIFF:-0}" == "1" ]]; then
  cd "$repo_root"
  git diff --exit-code -- \
    example/lib \
    example/android/app/src/main/kotlin/com/example/native_sqlite_example/generated \
    example/ios/Runner/Generated
fi

cd "$repo_root/example/android"
./gradlew :app:compileDebugKotlin

if [[ "$(uname -s)" == "Darwin" ]]; then
  cd "$repo_root/example"
  "${flutter[@]}" build ios --simulator --no-codesign
fi
