# NIV2FA iOS SDK (Swift)

Verification works on **iOS** the same product rule as Android: registered line must match **SIM1 or SIM2**.

> **How sharing works on iPhone**  
> Apple does **not** allow App Store apps to silently read the phone number from the SIM chip.  
> NIV2FA therefore asks the user: **“Share SIM details?”** → **Allow** / **Don’t Allow**.  
> If they Allow, they enter SIM1 (required) and optional SIM2 (from Settings → Cellular).  
> Those values are injected into the verify WebView and matched like Android.

Standalone Agent APK (Android-only helper): https://jeebly.kreateiq.com/niv2fa/agent  
Website docs: https://jeebly.kreateiq.com/niv2fa/docs/sdk

## Install (Swift Package Manager)

```swift
.package(url: "https://github.com/kreatedeviq/niv2fa-sdk.git", from: "1.0.0")
```

Product: **Niv2faSdk** (`ios/`).

```bash
git clone https://github.com/kreatedeviq/niv2fa-sdk.git
```

## Info.plist

```xml
<key>NSCameraUsageDescription</key>
<string>Camera is used to scan NIV2FA verify QR codes.</string>
```

## Methods

| Method | Description |
|--------|-------------|
| `requestPermissions(from:completion:)` | Allow / Don’t Allow → share SIM1/(SIM2) form |
| `getSimPhones()` | Lines the user chose to share |
| `openVerify(from:sessionUrl:completion:)` | Prompts share if needed, then verify WebView |
| `clearSharedSims()` | Clear cached shared lines |

## Swift example

```swift
import Niv2faSdk

Niv2faSdk.requestPermissions(from: self) { granted, sims in
  guard granted else { return } // user tapped Don’t Allow
  print("Shared", sims.map { $0.phone })

  Niv2faSdk.openVerify(from: self, sessionUrl: verifyUrl) { result in
    if result.matched {
      print("OK", result.sessionId ?? "", result.matchedSlot ?? "")
    } else {
      print("Fail", result.code ?? "", result.message ?? "")
    }
  }
}

// Or one call — openVerify asks for share permission first:
Niv2faSdk.openVerify(from: self, sessionUrl: verifyUrl) { result in
  // …
}
```

## End-to-end

1. Backend creates session → `verifyUrl`.
2. User **Allows** sharing SIM details and enters line number(s).
3. Match SIM1 or SIM2 to registered phone → webhook `identity.verified`.
4. Prefer webhook as source of truth in your backend.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `permission_denied` | User chose Don’t Allow — explain and ask again |
| Wrong number | User must share the SIM that matches the registered line |
| Cancelled | User closed the sheet |
