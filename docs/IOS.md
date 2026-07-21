# NIV2FA iOS SDK (Swift)

Opens the verify session in-app. **Users never type SIM numbers** — the SDK bridge is responsible for line identity (same product rule as Android).

> Apple does not expose SIM MSISDN to third-party apps the way Android `READ_PHONE_NUMBERS` does. For automatic dual-SIM chip match, use the **Android SDK / Agent**. iOS still runs the same verify WebView + `Allow` permission + success/fail callback when a match can be confirmed.

Website: https://jeebly.kreateiq.com/niv2fa/docs/sdk  
Repo: https://github.com/kreatedeviq/niv2fa-sdk

## Install (SPM)

```swift
.package(url: "https://github.com/kreatedeviq/niv2fa-sdk.git", from: "1.0.0")
```

Product: **Niv2faSdk** (`ios/`).

## Methods

| Method | Description |
|--------|-------------|
| `requestPermissions(from:completion:)` | Allow / Don’t Allow phone identity (no typing) |
| `getSimPhones()` | Lines from native bridge (often `[]` on iOS) |
| `openVerify(from:sessionUrl:completion:)` | Permission → WebView → `{ matched, … }` |

## Example

```swift
Niv2faSdk.openVerify(from: self, sessionUrl: verifyUrl) { result in
  if result.matched {
    // Success — also trust your project webhook
  }
}
```

## Flow

1. Backend creates session → `verifyUrl`
2. SDK asks **Allow** (not manual SIM entry)
3. Verify page uses the SDK bridge only
4. Match → `matched: true` + webhook `identity.verified`
