# Repository Guidelines

## Project Structure & Module Organization
- App code: `Prey/` (views in `Classes/`, assets in `Images.xcassets` and `Resources/Colors.xcassets`).
- App configuration: `Prey/Plist/` (`Info.plist`, `Prey.entitlements`, managed app config).
- Notification Extension: `PreyNotify/` (extension UI and `Info.plist`).
- Tests: `PreyTests/` (XCTest cases, e.g., `PreyRestTests.swift`).
- Xcode files: `Prey.xcodeproj` and `Prey.xcworkspace` (open either; CI uses the `.xcodeproj`).

## Build, Test, and Development Commands
- Build (Debug): `xcodebuild -project Prey.xcodeproj -scheme Prey build`
- Run unit tests: `xcodebuild -project Prey.xcodeproj -scheme Prey test -destination "platform=iOS Simulator,name=iPhone 15"`
- Clean: `xcodebuild -project Prey.xcodeproj -scheme Prey clean`
Notes: CI runs tests headless with code signing disabled. Use Xcode 15 and iOS 15.6+ simulators.

## Coding Style & Naming Conventions
- Swift 5, 4‑space indentation, spaces over tabs.
- Types: UpperCamelCase (`PreyHTTPClient`), methods/vars: lowerCamelCase.
- View controllers end with `VC` (e.g., `HomeVC`), feature modules prefixed `Prey`.
- Use `// MARK:` for logical sections; favor optionals over force‑unwraps.

## Testing Guidelines
- Framework: XCTest in `PreyTests/`.
- Naming: `test<Feature><Case>()` (e.g., `testRest03GetToken`).
- Scope: Many tests hit network APIs; run on a simulator with internet access. Prefer running targeted tests from Xcode or specify with `-only-testing` in `xcodebuild`.

## Commit & Pull Request Guidelines
- Commits: Imperative, present tense; concise subject, detailed body when needed.
  Example: `Fix: throttle location updates on background enter`.
- PRs: Link issues, describe changes and risk, include steps to test and screenshots for UI.
- Keep scheme as `Prey`; do not modify bundle identifiers or signing for CI. Update `Info.plist` or entitlements consciously and call out changes.

## Security & Configuration Tips
- Never commit credentials, API keys, or provisioning profiles. Secrets belong in local keychain/CI vars.
- Review `Prey/Plist/Info.plist` and managed app config before shipping.
- Network code lives in `Classes/PreyHTTPClient.swift` and related types; validate endpoints and error handling when touching these files.

