# OutageKit iOS

[![CI](https://github.com/Talk2rakesh-1/outage-kit-ios/actions/workflows/ci.yml/badge.svg)](https://github.com/Talk2rakesh-1/outage-kit-ios/actions/workflows/ci.yml)
[![Security](https://github.com/Talk2rakesh-1/outage-kit-ios/actions/workflows/security.yml/badge.svg)](https://github.com/Talk2rakesh-1/outage-kit-ios/actions/workflows/security.yml)

A native SwiftUI household supply checklist that works offline. Track your own stock targets and expiry dates before a power outage. No account, backend, API key, analytics SDK, or third-party runtime dependency.

**Status:** functional portfolio MVP. Native simulator-SDK build and core unit tests are verified; simulator interaction, VoiceOver behavior, and physical-device testing remain unverified. This checklist is not an emergency alert service or a certification of preparedness.

## Use it

1. Open `OutageKit.xcodeproj` in Xcode 16+ with Swift 6.
2. Choose the OutageKit scheme and an iOS 17+ simulator, then Run.
3. Add a supply (for example, a flashlight), set stocked and target quantities, and optionally track an expiry date.
4. Tap a row to edit; swipe to delete with confirmation. Search by supply name.
5. Close and reopen to restore your kit from local storage.

A physical device requires selecting your own signing team. No paid Apple account is needed for simulator use. There is no App Store release or distribution signing in this repository.

## Behavior

- A supply is stocked when quantity reaches its target and its expiry has not passed.
- Expiry dates remain valid through the selected local calendar day. The list refreshes every minute while visible.
- Empty kits show guidance instead of a misleading 100% readiness indicator.
- Quantities are bounded to 0–999, targets 1–999, names 1–80 characters, and kits 500 items.
- Save failures preserve the previous in-memory state and leave the editor open.
- Corrupt/unsupported storage is preserved and mutations are blocked; retry loading is available.
- Text labels accompany icons, system text supports Dynamic Type, and controls use native SwiftUI semantics. Accessibility behavior still needs device validation.

## Architecture

`SwiftUI views → main-actor KitModel → validated Supply / KitStore → versioned atomic JSON`

`Sources/OutageCore` is shared by the app target and a standalone Swift package for fast macOS unit tests. The UI has no networking layer. The store writes into Application Support with iOS complete file protection. Small bounded local writes are synchronous on the main actor; move persistence off the UI actor if expanding the data model or measuring stalls. No backup export, cloud sync, notifications, or multiple-kit support is implemented.

## Verify

```sh
swift test
xcrun swift-format lint --strict -r App Sources Tests Package.swift
xcodebuild -project OutageKit.xcodeproj -scheme OutageKit   -sdk iphonesimulator -configuration Release   -derivedDataPath /tmp/OutageKitBuild CODE_SIGNING_ALLOWED=NO build
python3 scripts/check_policy.py
```

Eight core tests cover validation, day-boundary expiry, excess stock, round-trip saves, corrupt files, unsupported versions, duplicate IDs, and failed writes. CI compiles the native app and runs package tests; these are not simulator UI tests. See the [manual test plan](docs/TEST_PLAN.md) for the remaining UI checks.

## Why this project

[Ready.gov](https://www.ready.gov/business) identifies power outages as a business and household preparedness concern. OutageKit focuses on a small software problem: keeping a personal inventory available without connectivity. Quantities are user-selected; no government guidance is copied into the app or represented as personalized advice. [Research and provenance](docs/RESEARCH.md).

MIT licensed. See [security](SECURITY.md) and [third-party notices](THIRD_PARTY.md).
