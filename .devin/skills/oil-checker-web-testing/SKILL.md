---
name: oil-checker-web-testing
description: How to run and UI-test the Oil Checker Flutter web app locally — serving, onboarding, geolocation, and expected error states without an Opinet API key
---

# Oil Checker web UI testing

## Serve the app

```bash
export PATH="$HOME/flutter/bin:$PATH"
cd oil_checker                       # repo subdir, not repo root
flutter build web                  # if build/web is stale — check it contains feature markers via grep
dart run tool/opinet_proxy.dart 8899   # persistent shell; serves build/web + proxies /opinet/*
```

Open http://localhost:8899 in Chrome. The proxy injects `OPINET_API_CODE` (env) or falls back to `api-keys.json`. **Without a key, `/opinet/*` returns HTTP 500** — every screen surfaces the designed error view ('주유소 정보를 불러오지 못했어요' + '다시 시도'), not a crash. The first error can take ~60–90s to appear (provider retries); do not conclude it is stuck too early. Check `build/web/main.dart.js` freshness with ASCII markers (e.g. `grep -c openfreemap build/web/main.dart.js`) — Korean strings are unicode-escaped so grep for ASCII identifiers, not Korean text.

## First-run onboarding (fresh Drift DB → CarSetupScreen)

1. Search field: type `K5` (ASCII works; 56 results load fast).
2. Click first result tile → `다음` → STEP 2 pre-fills a tank preset → `시작하기`.
3. Browser shows a **geolocation permission bubble top-left** — click "Allow while visiting the site". It resolves to a real position on these VMs (VM was located in Menlo Park, US — map works worldwide; Opinet data needs Korea but errors out without a key anyway).

## Map / platform notes

- Home map = flutter_map + OSM raster tiles (tile.openstreetmap.org must be reachable).
- DriveScreen = maplibre_gl platform view; needs **WebGL2** (maplibre-gl-js 6 dropped WebGL1). Verify quickly via console: `document.createElement('canvas').getContext('webgl2')`.
- maplibre-gl.js loads from `unpkg.com/maplibre-gl@6.4.1/dist/maplibre-gl.mjs` (`.mjs`, not `.js`) — needs network access.
- Vector tiles/style from `tiles.openfreemap.org` — external; if blocked, the map area stays blank while Flutter overlays still render.
- Known web quirk: `maplibre_gl_web` `easeCamera()` is fire-and-forget (`_map.easeTo` returns immediately), so any Dart code that flags "programmatic camera" via `await easeCamera` has the flag cleared while 'move' events still fire — follow/tracking state can drop mid-animation.

## Entry points

- DriveScreen: home map's right floating column, TOP button (`navigation` icon, tooltip '드라이브 모드' — on web it may render as an 'A'-like glyph if the icon font is partially loaded). The gold circle one row BELOW it is `edit_location` (위치 지정) — don't confuse them. Alternative reliable entry: station card → detail → '길안내 시작' → '드라이브 모드로 보기'.

## Devin Secrets Needed

- `OPINET_API_CODE` (org secret) — approve so the proxy can be started with `env={"OPINET_API_CODE": "secret:org:OPINET_API_CODE"}`; without it only error-state UI is verifiable.

## Korean text input & animation capture

- **한글 입력**: xdotool `type` can't inject Korean into Flutter web's hidden `flt-text-editing-host input`. Drive it by dispatching an `input` event on the ACTIVE host input (the non-offscreen, non-submit one) via browser console/JS, e.g. set `.value = '쏘나타'` then `dispatchEvent(new Event('input', {bubbles: true}))`.
- **Sub-2s animations** (splash intro, count-up): live screenshots always miss them — record 60fps, then extract frames with `ffmpeg -i rec.mkv -vf fps=60 out%04d.png` and diff.
- **Fresh onboarding**: Drift profile persists — clear IndexedDB + localStorage in devtools, then reload to see CarSetupScreen again.
- `browser_console` surfaces maplibre_gl web layer validation errors that the app's `catch (_)` swallows — always check it when markers look missing.
- **Overlay taps dead on web**: the maplibre platform-view DOM swallows pointer events, so taps on Flutter widgets drawn over the map (island pill, control buttons) never reach Flutter. Every overlay on DriveScreen must be wrapped in `PointerInterceptor` (pointer_interceptor pkg); when a tap is dead, check for a missing wrapper before anything else.
- **Window-region caveat**: the dock/panel regions may be unavailable to coordinate probes — verify drive-mode controls by their effect (map rotation, island expansion), not by clicking coordinates blindly.

## Asset bundling gotcha

- Flutter `assets/dir/` declarations in pubspec.yaml are NOT recursive — subdirectory assets (e.g. `assets/cars/real/*.webp`) need their own pubspec line, or they silently fall back to the SPA HTML (200 text/html instead of the file) in `build/web`. Verify bundled assets with `curl -I localhost:8899/assets/assets/<path>` → content_type must not be text/html.
