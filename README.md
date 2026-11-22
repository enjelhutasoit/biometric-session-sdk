<p align="center">
  <img src="https://raw.githubusercontent.com/enjelhutasoit-com/biometric-session-sdk/main/assets/biometric-session-logo.png" alt="Biometric Session logo" height="130">


# BiometricSession

[![CI](https://github.com/enjelhutasoit/biometric-session-sdk/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/enjelhutasoit/biometric-session-sdk/actions/workflows/ci.yml)
[![Docs](https://github.com/enjelhutasoit/biometric-session-sdk/actions/workflows/pages.yml/badge.svg?branch=main)](https://github.com/enjelhutasoit/biometric-session-sdk/actions/workflows/pages.yml)
[![License: MIT](https://img.shields.io/github/license/enjelhutasoit/biometric-session-sdk)](LICENSE)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange)
![iOS 14+](https://img.shields.io/badge/iOS-14%2B-blue)
</p>

Biometric authentication and session lifecycle kit for Swift apps.
Zero third-party dependencies.

## Status

`v1.0.0`: stable public API. See the [compatibility policy](Docs/PublicAPI.md).

Included:

- `SessionController`: lock, unlock, inactivity timeout, background grace,
  failed-attempt limit, step-up re-authentication, state stream.
- `LocalAuthAuthenticator` with optional passcode fallback (off by default).
- Enrollment-change detection with a baseline in the Keychain.
- `BiometricSecretStore`: Keychain secret readable only after biometry.
- `MonotonicSessionClock`, `LifecycleAdapter` (UIKit).
- Test fakes: `ManualClock`, `FakeAuthenticator`, and more.

Many device behaviors are UNKNOWN. See the
[simulator vs device matrix](Docs/SimulatorVsDevice.md).

Not in scope: UI screens, networking, jailbreak detection, Secure Enclave signing.

## Demo

`Examples/BiometricSessionDemo` is a small SwiftUI app that wires everything.
It is not part of the package products. See its README for limits.

## Install

```swift
.package(url: "https://github.com/enjelhutasoit/biometric-session-sdk.git", from: "1.0.0")
```

Add products to your targets:

```swift
.product(name: "BiometricSessionCore", package: "biometric-session-sdk"),
.product(name: "BiometricSessionLocalAuth", package: "biometric-session-sdk"),
.product(name: "BiometricSessionKeychain", package: "biometric-session-sdk"),
.product(name: "BiometricSessionUIKit", package: "biometric-session-sdk"),
// Test targets only:
.product(name: "BiometricSessionTestSupport", package: "biometric-session-sdk"),
```

Do not link `BiometricSessionTestSupport` into an app target.
It contains fakes that can fake a successful login.

## Quick start

```swift
let controller = SessionController(
    authenticator: LocalAuthAuthenticator(),
    clock: MonotonicSessionClock(),
    enrollment: EnrollmentMonitor(
        provider: LocalAuthDomainStateProvider(),
        store: KeychainBaselineStore(service: "app.baseline", account: "enrollment")!
    )
)
let adapter = await LifecycleAdapter(controller: controller)
await adapter.start()

// Call after the app completes its own sign-in.
await controller.signIn()

// Lock before requiring biometric authentication again.
await controller.lock()
try await controller.unlock(reason: "Unlock your account")
```

Use a different Keychain service and account than `BiometricSecretStore`.
Add `NSFaceIDUsageDescription` (see `Docs/InfoPlist.md`).

## Limits

See the [threat model](Docs/ThreatModel.md) for what is and is not covered.
All checks in this library run on the client.
A compromised device or a hooked process can bypass them.
This library is not a security boundary.
Enforce authorization on your server.
Timeouts and attempt limits are configurable policy defaults, not standards.

## Requirements

- Swift 6.0 toolchain (Xcode 16)
- iOS 14 deployment target (see `Package.swift`)

Setup details: [Info.plist guide](Docs/InfoPlist.md).
Tested behavior per environment: [simulator vs device matrix](Docs/SimulatorVsDevice.md).
Many cells are still UNKNOWN. Read them before relying on a behavior.

## Documentation

DocC catalogs live next to each module. Build them with Xcode:

```bash
./Scripts/docbuild.sh
```

The script prints the `.doccarchive` paths. Open one in Xcode.
Warnings fail the build.

The public surface is listed in [Docs/PublicAPI.md](Docs/PublicAPI.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security

See [SECURITY.md](SECURITY.md).

## License

MIT. See [LICENSE](LICENSE).
