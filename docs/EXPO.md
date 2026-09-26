# Truzzt Expo plugin

`@truzzt/expo` — Network Identity verify for **Expo Dev Client** and **prebuild** apps.

Repo: https://github.com/kreatedeviq/truzzt-sdk  
Package path: `packages/expo`  
Demo: https://truzzt.site/agent/app

## Expo Go vs Dev Client

| | Expo Go | Dev Client / prebuild |
|---|---------|------------------------|
| Truzzt native module | ❌ | ✅ |
| SIM / Contacts line read | ❌ | ✅ |

**Expo Go is unsupported.** Use `expo prebuild` + a development or production build with native code linked.

## Install

```bash
git clone https://github.com/kreatedeviq/truzzt-sdk.git
cd your-expo-app

npm install ../truzzt-sdk/packages/expo ../truzzt-sdk/packages/react-native
# or from Git after publish
```

### Config plugin

`app.json` / `app.config.js`:

```json
{
  "expo": {
    "plugins": ["@truzzt/expo"]
  }
}
```

The plugin adds Android permissions (`INTERNET`, `ACCESS_NETWORK_STATE`, `READ_PHONE_STATE`, `READ_PHONE_NUMBERS`, `READ_CONTACTS`) and iOS `NSContactsUsageDescription`.  
**No Camera.** Play / App Store justifications: **[PERMISSIONS.md](./PERMISSIONS.md)**.

### Native linking

`@truzzt/expo` re-exports `@truzzt/react-native`. You must include the Truzzt native projects:

- **Android:** `:truzzt-sdk` Gradle module + `TruzztPackage` in `MainApplication` — see [REACT_NATIVE.md](./REACT_NATIVE.md) and [ANDROID.md](./ANDROID.md).
- **iOS:** `TruzztSdk` SPM product + RN bridge under `packages/react-native/ios` — see [REACT_NATIVE.md](./REACT_NATIVE.md) and [IOS.md](./IOS.md).

Then:

```bash
npx expo prebuild
npx expo run:android
# or
npx expo run:ios
```

## Configure + theme

```js
import { configure, requestPermissions, openVerify } from '@truzzt/expo';

await configure({
  apiKey: 'trz_live_…',
  projectId: 'proj_…',
  theme: {
    primary: '#0B1F3A',
    accent: '#FFC83D',
    background: '#071525',
    text: '#F7F4EE',
    muted: '#64748B',
    appName: 'My Shop',
    logoUrl: 'https://example.com/logo.png',
  },
});
```

## Create verification (your backend)

```http
POST https://truzzt.site/secure-api/v1/verifications
Authorization: Bearer trz_live_…
Content-Type: application/json

{
  "projectId": "proj_…",
  "phone": "9647721421709",
  "countryCode": "964",
  "purpose": "login",
  "returnUrl": "myapp://auth/done",
  "cancelUrl": "myapp://auth/cancel",
  "theme": {
    "primary": "#0B1F3A",
    "accent": "#FFC83D",
    "appName": "My Shop"
  }
}
```

Response: `data.verifyUrl` (alias `pairUrl`). **No QR** — pass `verifyUrl` to the SDK.

## openVerify

```js
await requestPermissions();
const { verifyUrl } = await createVerificationOnYourBackend(); // your API
const r = await openVerify({ url: verifyUrl });
// or openVerify({ url: verifyUrl, theme: { accent: '#…' } })

if (r.matched) {
  console.log(r.matchedSlot, r.sessionId);
}
```

## Result shape

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

Also rely on webhook **`identity.verified`**.

## Permissions

| OS | Runtime |
|----|---------|
| Android | `INTERNET`, network state, phone state/numbers, contacts (no Camera) |
| iOS | Contacts (`NSContactsUsageDescription`) |

Full Play / App Store wording: **[PERMISSIONS.md](./PERMISSIONS.md)**

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Native module null | Rebuild Dev Client; link RN + TruzztSdk per REACT_NATIVE.md |
| Used Expo Go | Switch to prebuild / Dev Client |
| `CONFIG_REQUIRED` / `ACCESS_DENIED` | Call `configure` with dashboard key + project |
| Browser-only verify | User sees Try again — must use SDK |

## License

Proprietary — Kreate Technologies LLC / Truzzt.
