#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script must run on macOS with Xcode installed." >&2
  exit 2
fi

command -v xcodegen >/dev/null || {
  echo "XcodeGen is required." >&2
  exit 2
}

destinations=("$@")
if (( ${#destinations[@]} == 0 )); then
  destinations=(
    "platform=iOS Simulator,name=iPhone 17 Pro"
    "platform=iOS Simulator,name=iPad Pro 11-inch (M5)"
  )
fi

for destination in "${destinations[@]}"; do
  if [[ "$destination" == platform=iOS\ Simulator* ]]; then
    continue
  fi

  if [[ "$destination" == id=* ]]; then
    udid=${destination#id=}
    if xcrun simctl list devices | grep -Fq "$udid"; then
      continue
    fi
  fi

  echo "Validation is simulator-only; reject destination: $destination" >&2
  exit 2
done

run_live="${RUN_LIVE_TESTS:-false}"
upstream_host="${TYPETYPE_LIVE_UPSTREAM_HOST:-watch.typetype.video}"
artifact_root="${REGRESSION_OUTPUT:-build/regression/$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$artifact_root"
manifest="$artifact_root/manifest.json"
printf '[\n' > "$manifest"

append_manifest() {
  local entry=$1
  if [[ -s "$manifest" && $(tail -n 1 "$manifest") != "[" ]]; then
    printf ',\n' >> "$manifest"
  fi
  printf '%s\n' "$entry" >> "$manifest"
}

xcodegen generate 2>&1 | tee "$artifact_root/xcodegen.log"

release_result=0
xcodebuild \
  -project TypeTypeIOS.xcodeproj \
  -scheme TypeTypeIOS \
  -configuration Release \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$artifact_root/DerivedData" \
  ARCHS=x86_64 ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | tee "$artifact_root/release-build.log" || release_result=$?

if (( release_result != 0 )); then
  append_manifest '{"name":"Release build","status":"failed"}'
  exit "$release_result"
fi
append_manifest '{"name":"Release build","status":"passed"}'

for destination in "${destinations[@]}"; do
  safe_name="$(printf '%s' "$destination" | tr -C 'A-Za-z0-9._-' '-')"
  result_dir="$artifact_root/$safe_name"
  mkdir -p "$result_dir"

  unit_result=0
  xcodebuild \
    -project TypeTypeIOS.xcodeproj \
    -scheme TypeTypeIOSUnit \
    -configuration Debug \
    -destination "$destination" \
    -derivedDataPath "$artifact_root/DerivedData" \
    ARCHS=x86_64 ONLY_ACTIVE_ARCH=YES \
    -parallel-testing-enabled NO \
    -resultBundlePath "$result_dir/unit.xcresult" \
    test 2>&1 | tee "$result_dir/unit.log" || unit_result=$?

  append_manifest "$(printf \
    '{"destination":"%s","suite":"unit","status":"%s"}' \
    "$destination" \
    "$([ "$unit_result" = 0 ] && echo passed || echo failed)")"

  if (( unit_result != 0 )); then
    exit "$unit_result"
  fi

  if [[ "${RUN_UI_TESTS:-true}" = true ]]; then
    ui_result=0
    xcodebuild \
      -project TypeTypeIOS.xcodeproj \
      -scheme TypeTypeIOS \
      -configuration Debug \
      -destination "$destination" \
      -derivedDataPath "$artifact_root/DerivedData" \
      ARCHS=x86_64 ONLY_ACTIVE_ARCH=YES \
      -parallel-testing-enabled NO \
      -only-testing:TypeTypeIOSUITests \
      -resultBundlePath "$result_dir/ui.xcresult" \
      test 2>&1 | tee "$result_dir/ui.log" || ui_result=$?

    append_manifest "$(printf \
      '{"destination":"%s","suite":"ui","status":"%s"}' \
      "$destination" \
      "$([ "$ui_result" = 0 ] && echo passed || echo failed)")"

    if (( ui_result != 0 )); then
      exit "$ui_result"
    fi

    attachment_dir="$result_dir/screenshots"
    mkdir -p "$attachment_dir"
    xcrun xcresulttool export attachments \
      --path "$result_dir/ui.xcresult" \
      --output-path "$attachment_dir" >/dev/null \
      2>"$result_dir/screenshot-export.log" || true
  fi

  if [[ "$run_live" = true ]]; then
    live_result=0
    TYPETYPE_LIVE_UPSTREAM_HOST="$upstream_host" \
      xcodebuild \
      -project TypeTypeIOS.xcodeproj \
      -scheme TypeTypeIOSLive \
      -configuration Debug \
      -destination "$destination" \
      -derivedDataPath "$artifact_root/DerivedData" \
      ARCHS=x86_64 ONLY_ACTIVE_ARCH=YES \
      -parallel-testing-enabled NO \
      -only-testing:TypeTypeIOSLiveUITests/NetworkInterruptionLiveUITests \
      -only-testing:TypeTypeIOSLiveUITests/PlaybackLifecycleLiveUITests \
      -resultBundlePath "$result_dir/live.xcresult" \
      test 2>&1 | tee "$result_dir/live.log" || live_result=$?

    append_manifest "$(printf \
      '{"destination":"%s","suite":"live-resilience","upstream":"%s","status":"%s"}' \
      "$destination" \
      "$upstream_host" \
      "$([ "$live_result" = 0 ] && echo passed || echo failed)")"

    if (( live_result != 0 )); then
      exit "$live_result"
    fi
  fi
done

printf ']\n' >> "$manifest"

echo "Regression artifacts: $artifact_root"
