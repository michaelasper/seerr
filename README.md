# Seerr iOS

A lightweight SwiftUI client for Overseerr that shows recent requests and their media details.

## Getting started
- Open `Seerr.xcodeproj` in Xcode 15 or newer.
- Update the bundle identifier and signing team in the project settings if needed.
- Build and run on an iOS 17+ simulator or device.
- In the app, tap the gear icon and enter your Overseerr base URL (e.g. `https://overseerr.yourdomain.com`) and API key from **Settings → General → API Key**.
- A setup screen blocks the app until you connect to Overseerr. After connecting you can browse requests, discover trending content, search, view details, and submit new requests.
- Optional: create `Seerr/Resources/.env.local` (gitignored) with `OVERSEERR_BASE_URL`, `OVERSEERR_API_KEY`, `OVERSEERR_ACCENT_COLOR` to prefill settings during development. UI tests ignore this file so the setup flow still appears unless you opt into live testing (see below). An example lives at `Seerr/Resources/.env.local.example`.

## Build & test from CLI
- `make build` — build the app for the default simulator (`iPhone 17 Pro`).
- `make test` — run all tests (includes the UI/E2E test). If `Seerr/Resources/.env.local` exists, it is loaded so you can pass live Overseerr settings via `OVERSEERR_BASE_URL`/`OVERSEERR_API_KEY`. Add `USE_REAL_OVERSEERR=1` to hit a real server instead of the mock UI test server; UI tests forward these env vars to the app process.
- `make ui-test` — run only `SeerrUITests`.
- Override the simulator with `DESTINATION='platform=iOS Simulator,name=iPhone 16e' make test` if your Xcode has different devices.

## Notes
- Requests are fetched from `/api/v1/request` and media details from `/api/v1/movie/{id}` or `/api/v1/tv/{id}` using your Overseerr server.
- API credentials are stored on-device in `UserDefaults` only.
- UI tests run against a built-in mock server (`UI_TEST_MODE=1`), so they do not require network access.
