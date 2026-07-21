# NIV2FA iOS SDK (Swift)

Opens verify in-app. **No SIM chip read** (Apple restriction). We read your number(s) from **Contacts** — My Card (Me) plus saved contacts named like **"My number"** or **"رقمي"** — then match to the session phone (register / login / forgot password / order confirm). **No match = fail.**

Repo: https://github.com/kreatedeviq/niv2fa-sdk

## Configure (required)

```swift
Niv2faSdk.configure(apiKey: "niv_live_…", projectId: "proj_…")
```

Trial or active subscription required (`GET /secure-api/v1/sdk/access`).

## Info.plist

```xml
<key>NSContactsUsageDescription</key>
<string>NIV2FA reads your saved phone number(s) from Contacts to match the phone used for account verification.</string>
```

Optional if you scan QR:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera is used to scan NIV2FA verify QR codes.</string>
```

## How we find your number (multi-source)

| Source | What it is |
|--------|------------|
| **Contacts → My Card (Me)** | iOS profile card — Apple's built-in place for "your" number |
| **Saved owner contacts** | Contacts you named e.g. `My number`, `My line`, `رقمي`, `رقمي Asia` (common on dual-SIM phones) |

We do **not** place background calls, read the SIM chip, or send OTP codes.

## Flow

1. `configure(apiKey, projectId)`
2. `openVerify(sessionUrl)` → custom **Allow** screen
3. User allows → **Contacts** permission → read all candidate lines above
4. Server compares device line(s) vs registered session number
5. Match → `matched: true` + webhook · else `SIM_MISMATCH`

## User tip

If verify fails with `LINE_REQUIRED` or `SIM_MISMATCH`:

1. Open **Contacts → tap Me (profile card) → add your mobile number**, **or**
2. Create a contact named **"My number"** / **"رقمي"** with your line (same trick many Android dual-SIM users use).

## Example

```swift
Niv2faSdk.configure(apiKey: key, projectId: projectId)
Niv2faSdk.openVerify(from: self, sessionUrl: verifyUrl) { result in
  if result.matched { /* success */ }
}
```
