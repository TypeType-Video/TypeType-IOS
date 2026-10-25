# Data layer cheat sheet

Networking, auth, and the data quirks that break clients which trust the
OpenAPI spec (`TypeTypeIOS/Core/`).

## Request path

```
service (protocol) → APIClient → URLSessionAPIClient
                                  ├─ +Request      builds URLRequest
                                  ├─ +Execution    performs + decodes
                                  ├─ +Resilience   retries/backoff
                                  └─ URLSessionAPIClient+Diagnostics
```

`APIEndpoint` describes routes; `HTTPMethod` and `NetworkError` are the shared
vocabulary. `MultipartFormDataBuilder` covers upload endpoints
(portability/imports), `ServerProbeService` detects instance capabilities.

## Auth

- `POST /api/auth/login` → `accessToken`; send `Authorization: Bearer …` on
  **every** request — including playback manifests and media segments (the
  player's HTTP server attaches it to upstream fetches).
- A refresh cookie (HttpOnly) is kept by the shared URLSession;
  `POST /api/auth/refresh` exchanges it. On a 401: refresh once, retry.
- `TokenRefreshGate` (actor) makes refresh single-flight — parallel 401s wait
  on one refresh instead of stampeding.
- `GET /api/instance` is public even with guests disabled — capability probe
  (`apiVersion`, `supportedServices`, `guestAllowed`).

## Data quirks (verified against live instances)

- **`id` fields carry the full URL, not an ID.** Normalize to the bare ID
  (`v=` query, else last path segment for youtu.be/shorts/embed) before it
  reaches any URL — see `LiveVideoItem+Playback.swift`. Channel URLs are
  canonicalized in `LiveChannelURLCanonicalizer.swift`.
- **Search content filters are composite values** (`|0|all`, `|1|videos`,
  …; service-prefixed for other services). Get valid values from
  `GET /api/search/filters?service=0`.
- **Timestamps are epoch milliseconds; `-1` means "no value".** Textual date
  fields can arrive in a random upstream locale — derive display from the
  timestamp in the user's locale, fall back to raw text only without one.
- **Pagination uses opaque `nextpage` cursors** (and `cursor` on the feed).
  History/feed lists are event streams: keep every raw row and advance the
  offset by the raw count, never by the deduplicated count, or older entries
  freeze out.
- **Decode legacy rows tolerantly** — read each field with `try?` and skip
  only entries without a usable key (`Int64OrString` exists for the
  number-or-string fields). One strict field fails a whole page.
- Comments/descriptions carry inline HTML and entities — strip or render.
- All API routes live under `/api`; a bare root path serves the SPA HTML and
  surfaces as parse errors in clients.

## Playback endpoints

- `GET /api/sabr/manifest/{videoId}?format=hls` → full HLS playlist,
  relative segments in the same subtree. `videoItag` pins quality,
  `audioOnly=true` for audio, `startTimeMs=` resumes.
- The first manifest request warms the server-side SABR session; a cold one
  can answer 422 — prewarm once at stream-resolution time
  (`LivePlaybackService.prefetchSABRPlayback`).
- Live streams carry a plain `hlsUrl` instead.

## Storage

`ServerStore` (instances), `SessionStore` (persisted session snapshots),
`LiveAppPreferencesStore` (local preferences) — all `Codable`, all decoded
field-tolerant for imported/legacy rows.
