# NIV2FA iOS SDK (Swift)

Opens verify in-app. **No SIM chip read** (Apple restriction). We read your number(s) from **Contacts → My Card (Me)**, match to the session phone (register / login / forgot password / order confirm). **No match = fail.**

Repo: https://github.com/kreatedeviq/niv2fa-sdk

## Configure (required)

```swift
Niv2faSdk.configure(apiKey: "niv_live_…", projectId: "proj_…")
```

Trial or active subscription required (`GET /secure-api/v1/sdk/access`).

## Info.plist

```xml
<key>NSContactsUsageDescription</key>
<string>NIV2FA reads your number from Contacts (My Card) to match the phone used for account verification.</string>
```

Optional if you scan QR:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera is used to scan NIV2FA verify QR codes.</string>
```

## Flow

1. `configure(apiKey, projectId)`
2. `openVerify(sessionUrl)` → custom **Allow** screen
3. User allows → **Contacts** permission → read **My Card** phone number(s)
4. Server compares device line(s) vs registered session number
5. Match → `matched: true` + webhook · else `SIM_MISMATCH`

## User tip

If verify fails with `LINE_REQUIRED` or `SIM_MISMATCH`, ask the user to open **Contacts → tap Me (profile card) → add their mobile number** (same as register/login).

## Example

```swift
Niv2faSdk.configure(apiKey: key, projectId: projectId)
Niv2faSdk.openVerify(from: self, sessionUrl: verifyUrl) { result in
  if result.matched { /* success */ }
}
```
