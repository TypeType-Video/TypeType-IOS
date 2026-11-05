#!/usr/bin/env bash
# Creates an iPhone 17 simulator on the newest installed iOS runtime and exports its id as SIMULATOR_ID.
set -euo pipefail

runtime="$(
  xcrun simctl list runtimes --json |
    jq -r '[.runtimes[] | select(.isAvailable and (.identifier | contains("SimRuntime.iOS")))]
      | sort_by(.version | split(".") | map(tonumber)) | last | .identifier'
)"
device_type="$(
  xcrun simctl list devicetypes --json |
    jq -r '[.devicetypes[] | select(.name == "iPhone 17")] | first | .identifier'
)"
if [ -z "$runtime" ] || [ "$runtime" = "null" ] || [ -z "$device_type" ] || [ "$device_type" = "null" ]; then
  echo "No iOS runtime or iPhone 17 device type on this runner" >&2
  xcrun simctl list runtimes
  exit 1
fi
simulator_id="$(xcrun simctl create "TypeType CI iPhone" "$device_type" "$runtime")"
echo "Created $simulator_id on $runtime"
echo "SIMULATOR_ID=$simulator_id" >> "$GITHUB_ENV"
