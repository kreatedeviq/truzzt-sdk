# Truzzt iOS SDK (Swift)

In-app themed verify. **No SIM chip read** (Apple). Lines from **Contacts Me** and saved owner contacts (**My number**, **رقمي**), then server match.

Repo: https://github.com/kreatedeviq/truzzt-sdk  
Demo: https://truzzt.site/agent/app

## Install (SPM)

```swift
.package(url: "https://github.com/kreatedeviq/truzzt-sdk.git", from: "1.0.0")
// product: TruzztSdk
```

## Configure + theme

```swift
TruzztSdk.configure(
    apiKey: "trz_live_…",
    projectId: "proj_…",
    theme: [
        "primary": "#0B1F3A",
        "accent": "#FFC83D",
        "background": "#071525",
        "text": "#F7F4EE",
        "muted": "#94A3B8",
        "appName": "MyApp",
        "logoUrl": "https://example.com/logo.png"
    ]
)
```

Theme merges into `verifyUrl` when opening verify.

## Create verification (backend)

Same as other platforms — `POST /secure-api/v1/verifications` with `projectId`, `phone`, `purpose`, `returnUrl`, `cancelUrl`, optional `theme`. Open returned **`verifyUrl`** with the SDK (not Safari alone).

## openVerify

```swift
TruzztSdk.openVerify(from: self, sessionUrl: verifyUrl) { result in
    if result.matched {
        // webhook identity.verified is authoritative
    }
}
```

## Permissions

`Info.plist` (required for App Review):

```xml
<key>NSContactsUsageDescription</key>
<string>Truzzt needs access to Contacts to read your My Card (Me) number and any contact you saved as your own phone (for example “My number” or “رقمي”), so we can verify that this device owns the phone number used for login or registration. We do not sync your full address book.</string>
```

**App Store / App Privacy questionnaire wording:** **[PERMISSIONS.md](./PERMISSIONS.md)**

## Flow

1. `configure(apiKey, projectId[, theme])`
2. Backend returns `verifyUrl`
3. `openVerify` → Allow → Contacts → POST lines → match
4. `matched: true` or `SIM_MISMATCH` / `LINE_REQUIRED`

## Result

```json
{
  "matched": true,
  "status": "completed",
  "matchedSlot": "line1",
  "matchedSource": "contacts_me",
  "sessionId": "sess_…",
  "platform": "ios"
}
```

## User tips

Add number to **Contacts → Me (My Card)** or save contact **"My number"** / **"رقمي"**.

## License

Proprietary — Kreate Technologies LLC / Truzzt.
