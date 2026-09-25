#!/usr/bin/env bash

set -euo pipefail

devices_json="$(puro flutter devices --machine 2>/dev/null)"

jq -r '
  ([.[] | select(.targetPlatform == "ios" and .emulator == true)][0].id // "" | @sh) as $ios |
  ([.[] | select((.targetPlatform | startswith("android")) and .emulator == true)][0].id // "" | @sh) as $android |
  ([.[] | select(.id == "chrome")][0].id // "" | @sh) as $web |
  "IOS_SIM=\($ios) ANDROID_EMU=\($android) WEB_CHROME=\($web)"
' <<<"$devices_json"
