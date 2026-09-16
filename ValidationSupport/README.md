# Regression validation

Validation is simulator-only. `Scripts/run-regression.sh` runs the
deterministic local regression campaign used before an iOS beta:

- Release build.
- Full unit suite on every requested simulator or device.
- Full deterministic UI suite on the first requested destination.
- Screenshot attachment export.
- Optional long-playback, transport-interruption, and process-relaunch tests.

Offline and airplane-mode behavior is covered in the simulator by stopping the
local fixture server or interrupting its transport, then checking the cached
experience and recovery. Physical-device validation is intentionally out of
scope.

Run the default iPhone and iPad simulator matrix:

```sh
Scripts/run-regression.sh
```

Run explicit destinations:

```sh
Scripts/run-regression.sh \
  "id=SIMULATOR_OR_DEVICE_UDID" \
  "id=SECOND_SIMULATOR_OR_DEVICE_UDID"
```

Enable local-resilience/live-style tests and point their HTTP proxy at an
instance:

```sh
RUN_LIVE_TESTS=true \
TYPETYPE_LIVE_UPSTREAM_HOST=beta.typetype.video \
Scripts/run-regression.sh "id=SIMULATOR_UDID"
```

Artifacts, logs, result bundles, and exported screenshots are written under
`build/regression/<timestamp>/`. `build/` is intentionally not committed.
