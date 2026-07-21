# NIV2FA Capacitor / Ionic Capacitor plugin

`@niv2fa/capacitor` — open NIV2FA verify inside your Capacitor app.

Repo: https://github.com/kreatedeviq/niv2fa-sdk  
Package path: `packages/capacitor`

## Install

```bash
git clone https://github.com/kreatedeviq/niv2fa-sdk.git
cd your-app
npm install ../niv2fa-sdk/packages/capacitor
# or after publish: npm install @niv2fa/capacitor

npx cap sync
```

### Android module

In your Capacitor app `android/settings.gradle`:

```gradle
include ':niv2fa-sdk'
project(':niv2fa-sdk').projectDir = new File('../../niv2fa-sdk/android')
```

Ensure the Capacitor plugin android module depends on `:niv2fa-sdk` (see package `android/build.gradle`).

## Permissions

Android (merged): `READ_PHONE_STATE`, `READ_PHONE_NUMBERS`, `CAMERA`, `INTERNET`.

iOS `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera is used to scan NIV2FA verify QR codes.</string>
```

## Methods

```ts
import Niv2fa from '@niv2fa/capacitor';

await Niv2fa.requestPermissions();
const sims = await Niv2fa.getSimPhones(); // { sims: [...], platform }
const result = await Niv2fa.openVerify({ url: verifyUrl });
// or openVerify({ sessionUrl: verifyUrl })
```

| Method | Returns |
|--------|---------|
| `requestPermissions()` | `{ requested: boolean }` |
| `getSimPhones()` | `{ sims: Array<{slot,phone}>, platform }` |
| `openVerify({ url })` | `{ matched, matchedSlot, sessionId, status, code?, message?, platform }` |

## Ionic example

```ts
import { Component } from '@angular/core';
import Niv2fa from '@niv2fa/capacitor';

@Component({ /* ... */ })
export class VerifyPage {
  async verify(url: string) {
    await Niv2fa.requestPermissions();
    const r = await Niv2fa.openVerify({ url });
    if (r.matched) {
      // also rely on webhook identity.verified
    }
  }
}
```

## Web (browser)

`openVerify` opens the URL in a new tab. SIM reading is **not** available on web.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Plugin not found | `npx cap sync` after install |
| Unresolved `:niv2fa-sdk` | Add module in `settings.gradle` |
| Empty SIMs on iOS | Expected (Apple restriction) |
