# Truzzt Android SDK (Java / Kotlin)

Embed Network Identity in your Android app: **SIM1 / SIM2**, Contacts backup, themed verify WebView, line match, webhook **`identity.verified`**.

Repo: https://github.com/kreatedeviq/truzzt-sdk  
Demo: https://truzzt.site/agent/app · Agent APK: https://truzzt.site/agent

## Install

```bash
git clone https://github.com/kreatedeviq/truzzt-sdk.git
```

```gradle
// settings.gradle
include ':truzzt-sdk'
project(':truzzt-sdk').projectDir = new File(settingsDir, '../path/truzzt-sdk/android')

// app/build.gradle
dependencies {
    implementation project(':truzzt-sdk')
}
```

## Configure + theme

```java
JSONObject theme = new JSONObject()
    .put("primary", "#0B1F3A")
    .put("accent", "#FFC83D")
    .put("background", "#071525")
    .put("text", "#F7F4EE")
    .put("muted", "#94A3B8")
    .put("appName", "MyApp")
    .put("logoUrl", "https://example.com/logo.png");

TruzztSdk.configure("trz_live_…", "proj_…", null, theme);
```

Kotlin helper [`Truzzt.kt`](../android/src/main/java/com/truzzt/sdk/Truzzt.kt):

```kotlin
Truzzt.configure(
    apiKey = "trz_live_…",
    projectId = "proj_…",
    theme = mapOf("accent" to "#FFC83D", "appName" to "MyApp"),
)
```

Theme is appended to `verifyUrl` query params when you use `verifyIntent` / `openVerify`.

## Create verification (backend)

```http
POST https://truzzt.site/secure-api/v1/verifications
Authorization: Bearer trz_live_…

{
  "projectId": "proj_…",
  "phone": "9647721421709",
  "countryCode": "964",
  "purpose": "register",
  "returnUrl": "myapp://auth/done",
  "cancelUrl": "myapp://auth/cancel",
  "theme": { "primary": "#0B1F3A", "accent": "#FFC83D" }
}
```

Use `data.verifyUrl` — **no QR** in the app UX.

## openVerify

```kotlin
companion object { const val REQ_NIV = 9101 }

fun startVerify(verifyUrl: String) {
    TruzztSdk.requestPermissions(this)
    startActivityForResult(TruzztSdk.verifyIntent(this, verifyUrl), REQ_NIV)
}

override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    if (requestCode != REQ_NIV) return
    val r = TruzztSdk.parseResult(data)
    if (r.optBoolean("matched")) {
        // Also trust webhook identity.verified
    }
}
```

## Permissions

Required (merged by the SDK — **no Camera / Call Phone**):

- `INTERNET`, `ACCESS_NETWORK_STATE`
- `READ_PHONE_STATE`, `READ_PHONE_NUMBERS`
- `READ_CONTACTS`

Runtime: `TruzztSdk.requestPermissions(activity)` before verify.

**Play Store justifications** (copy/paste for Console + reviewers): **[PERMISSIONS.md](./PERMISSIONS.md)**  
In-app rationale strings: `R.string.truzzt_perm_phone_rationale`, `R.string.truzzt_perm_contacts_rationale`.

## Line sources

| Source | Description |
|--------|-------------|
| SIM chip | SIM1 / SIM2 MSISDN |
| Device info / *#06# | Optional accessibility capture |
| Contacts | Owner contacts e.g. **My number**, **رقمي** |

## Result JSON

```json
{
  "matched": true,
  "status": "completed",
  "matchedSlot": "sim1",
  "matchedSource": "sim_chip",
  "sessionId": "sess_…",
  "platform": "android"
}
```

## Methods

| Method | Description |
|--------|-------------|
| `configure(apiKey, projectId[, baseUrl[, theme]])` | Required |
| `requestPermissions(Activity)` | Phone + Contacts |
| `getSimPhones(Activity)` | JSONArray of lines |
| `verifyIntent(Activity, url)` | Themed verify WebView intent |
| `openVerify(Activity, url, requestCode)` | Helper |
| `parseResult(Intent)` | Activity result |
| `applyThemeToUrl(url)` | URL theming |

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Empty SIM list | Carrier blank MSISDN; add Contacts **رقمي** |
| Permission denied | Call `requestPermissions` |
| Opened URL in Chrome | Use SDK — browser cannot match lines |

## Min SDK

`minSdk 26` · `compileSdk 35`

## License

Proprietary — Kreate Technologies LLC / Truzzt.
