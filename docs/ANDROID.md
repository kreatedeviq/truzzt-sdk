# NIV2FA Android SDK (Java / Kotlin)

Embed Network Identity verification in your Android app. Reads **SIM1 / SIM2**, opens the verify WebView, matches the claimed number, and your **project webhook** receives `identity.verified`.

> Standalone Agent APK is separate and optional: https://jeebly.kreateiq.com/niv2fa/agent

## Install

### Option A — Git dependency (recommended)

```gradle
// settings.gradle
include ':niv2fa-sdk'
project(':niv2fa-sdk').projectDir = new File(settingsDir, '../path-or-clone/niv2fa-sdk/android')
```

Or clone:

```bash
git clone https://github.com/kreatedeviq/niv2fa-sdk.git
```

```gradle
// app/build.gradle
dependencies {
    implementation project(':niv2fa-sdk')
}
```

### Option B — Copy module

Copy the `android/` folder into your project as module `:niv2fa-sdk`.

## Permissions

Merged from the library manifest:

- `READ_PHONE_STATE`
- `READ_PHONE_NUMBERS`
- `CAMERA`
- `INTERNET`
- `ACCESS_NETWORK_STATE`

Runtime: call `Niv2faSdk.requestPermissions(activity)` before verify.

## Methods

| Method | Description |
|--------|-------------|
| `Niv2faSdk.requestPermissions(Activity)` | Request phone + camera |
| `Niv2faSdk.getSimPhones(Activity)` | `JSONArray` of `{ slot, phone, … }` |
| `Niv2faSdk.getSimPhonesJson(Activity)` | Same as JSON string |
| `Niv2faSdk.verifyIntent(Activity, url)` | Intent for in-app verify WebView |
| `Niv2faSdk.openVerify(Activity, url, requestCode)` | `startActivityForResult` helper |
| `Niv2faSdk.parseResult(Intent)` | Parse activity result → `JSONObject` |

## Kotlin example

```kotlin
companion object { const val REQ_NIV = 9101 }

fun startVerify(sessionUrl: String) {
    Niv2faSdk.requestPermissions(this)
    startActivityForResult(Niv2faSdk.verifyIntent(this, sessionUrl), REQ_NIV)
}

override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
    if (requestCode != REQ_NIV) return
    val r = Niv2faSdk.parseResult(data)
    if (r.optBoolean("matched")) {
        // Also trust your project webhook identity.verified
        val slot = r.optString("matchedSlot")
        val sessionId = r.optString("sessionId")
    }
}
```

## Java example

```java
Niv2faSdk.requestPermissions(this);
startActivityForResult(Niv2faSdk.verifyIntent(this, sessionUrl), 9101);
```

## Result JSON

```json
{
  "matched": true,
  "status": "completed",
  "matchedSlot": "sim1",
  "sessionId": "sess_…",
  "platform": "sdk"
}
```

## End-to-end

1. Your backend: `POST /secure-api/v1/verifications` with `phone`, `projectId`, `returnUrl`.
2. Receive `data.verifyUrl`.
3. Call `openVerify` / `verifyIntent` with that URL.
4. User allows Phone permission → SIM1 or SIM2 matched.
5. Webhook `identity.verified` hits your `project.webhook_url`.
6. Activity result returns `matched: true`.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Empty SIM list | Carrier left MSISDN blank; check Settings → About → SIM status |
| `meta is not defined` | Update server (fixed) |
| Permission denied | Call `requestPermissions` and grant Phone |
| Wrong number | Expected — only matching SIM succeeds |

## Min SDK

`minSdk 26` · `compileSdk 35`
