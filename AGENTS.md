# Repository Guidelines

## Project Structure & Module Organization
- `Prey/`: iOS app sources (Swift), including `Classes/`, `CoreData/`, `Fonts/`, `Images.xcassets/`, `Plist/`, `Base.lproj/`, and a vendored `Swifter/` HTTP helper.
- `PreyTests/`: XCTest targets (e.g., `PreyRestTests.swift`).
- `LocationPushService/`: Location Push extension (Info.plist, entitlements, Swift sources).
- `PreyNotify/`: Notification resources.
- `scripts/apns/`: Utilities to send APNs test pushes; see `README.md`.

## Build, Test, and Development Commands
- Open in Xcode: `open Prey.xcworkspace` (or `open Prey.xcodeproj` if no workspace setup).
- Build (Debug, simulator):
  `xcodebuild -project Prey.xcodeproj -scheme Prey -sdk iphonesimulator -configuration Debug build`
- Run tests (no code signing, CI-friendly):
  `xcodebuild -project Prey.xcodeproj -scheme Prey -destination 'platform=iOS Simulator,name=iPhone 15' CODE_SIGNING_ALLOWED=NO clean test | xcpretty`
- APNs test push (Location/Background): see `scripts/apns/README.md`; example:
  `scripts/apns/apns_location_push.sh --team-id <TEAM> --key-id <KEY> --p8 /path/AuthKey_<KEY>.p8 --bundle-id com.prey --device-token <TOKEN> --env sandbox --push-type location`

## Coding Style & Naming Conventions
- Language: Swift 5; indent 4 spaces; UTF-8; avoid trailing whitespace.
- Types `UpperCamelCase`; methods/vars/enum-cases `lowerCamelCase`.
- Files should match the primary type name (e.g., `DeviceManager.swift`).
- Localized strings and InfoPlist values live under `Base.lproj/`, `Localizable.strings`, `InfoPlist.strings`.
- SwiftLint markers are present; if installed, run `swiftlint` before pushing.

## Testing Guidelines
- Framework: XCTest under `PreyTests/`.
- Name tests `test<Feature>_<Behavior>()` (e.g., `testSession_refreshToken()`).
- Keep tests deterministic; prefer fakes over network. New/changed code should include tests covering main paths.
- Run locally via Xcode’s Test action or the `xcodebuild ... test` command above.

## Commit & Pull Request Guidelines
- Commits: concise, imperative subject (≤72 chars), body for rationale; reference issues/PRs (e.g., `#123`). Avoid `wip` in shared branches.
- PRs: include summary, linked issue, screenshots for UI-affecting changes, and a brief test plan. Ensure builds/tests pass and no secrets are committed.

## Security & Configuration Tips
- Never commit credentials. Use `.apns.env` (see `.apns.env.example`) for local APNs variables.
- For CI or unsigned simulator runs, prefer `CODE_SIGNING_ALLOWED=NO` and simulator destinations.

