# NIV2FA iOS SDK (Swift)

In-app verify WebView for NIV2FA sessions on iOS.

> **Important:** Apple does **not** allow third-party apps to read SIM MSISDN.  
> On iOS this SDK opens the verify session in-app and reports the page result. Full SIM1/SIM2 hardware match is **Android-only** today (carrier Silent Network Auth can be added later for iOS).

Standalone Agent APK (Android): https://jeebly.kreateiq.com/niv2fa/agent

## Install (Swift Package Manager)

```swift
// Package.swift or Xcode → Add Package
.package(url: "https://github.com/kreatedeviq/niv2fa-sdk.git", from: "1.0.0")
```

Product: **Niv2faSdk** (path `ios/`).

Or:

```bash
git clone https://github.com/kreatedeviq/niv2fa-sdk.git
```

Add local package pointing at `niv2fa-sdk/ios`.

## Info.plist

```xml
<key>NSCameraUsageDescription</key>
<string>Camera is used to scan NIV2FA verify QR codes.</string>
```

## Methods

| Method | Description |
|--------|-------------|
| `Niv2faSdk.openVerify(from:sessionUrl:completion:)` | Present full-screen verify WebView |
| `Niv2faSdk.getSimPhones()` | Always `[]` on iOS (API parity) |

## Swift example

```swift
import Niv2faSdk

Niv2faSdk.openVerify(from: self, sessionUrl: verifyUrl) { result in
  if result.matched {
    print("OK", result.sessionId ?? "", result.matchedSlot ?? "")
  } else {
    print("Fail", result.code ?? "", result.message ?? "")
  }
}
```

## Result

```swift
public struct Result {
  public let matched: Bool
  public let status: String?
  public let matchedSlot: String?
  public let sessionId: String?
  public let code: String?
  public let message: String?
  public let platform: String? // "ios"
}
```

## End-to-end

1. Backend creates session → `verifyUrl`.
2. Call `openVerify`.
3. Prefer also listening to your **project webhook** for authoritative `identity.verified`.
4. For dual-SIM MSISDN proof, use Android SDK or the standalone Agent.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Empty SIMs | Expected on iOS |
| Cancelled | User closed the sheet |
| Need real SIM match | Use Android build / Agent APK |
