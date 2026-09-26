# Truzzt Capacitor / Ionic Capacitor plugin

`@truzzt/capacitor` — themed verify WebView, automatic line match, no QR UX.

Repo: https://github.com/kreatedeviq/truzzt-sdk  
Package path: `packages/capacitor`  
Demo: https://truzzt.site/agent/app

## Install

```bash
git clone https://github.com/kreatedeviq/truzzt-sdk.git
cd your-app
npm install ../truzzt-sdk/packages/capacitor
npx cap sync
```

Android: include `:truzzt-sdk` in `android/settings.gradle` — see [ANDROID.md](./ANDROID.md).

## Configure + theme

```ts
import Truzzt from '@truzzt/capacitor';

await Truzzt.configure({
  apiKey: 'trz_live_…',
  projectId: 'proj_…',
  theme: {
    primary: '#0B1F3A',
    accent: '#FFC83D',
    background: '#071525',
    text: '#F7F4EE',
    muted: '#64748B',
    appName: 'MyApp',
    logoUrl: 'https://…',
  },
});
```

## Create verification (backend)

`POST /secure-api/v1/verifications` with Bearer key, `projectId`, `phone`, `countryCode`, `purpose`, `returnUrl`, `cancelUrl`, optional **`theme`**. Use response **`verifyUrl`**.

## openVerify

```ts
await Truzzt.requestPermissions();
const result = await Truzzt.openVerify({ url: verifyUrl });
// { url, theme } — theme overrides configure palette for this session

if (result.matched) {
  // webhook identity.verified
}
```

## Permissions

**Android:** `INTERNET`, `ACCESS_NETWORK_STATE`, `READ_PHONE_STATE`, `READ_PHONE_NUMBERS`, `READ_CONTACTS` (via native SDK — no Camera / Call Phone).

**iOS:** `NSContactsUsageDescription` in `Info.plist` (full string in [PERMISSIONS.md](./PERMISSIONS.md) / [IOS.md](./IOS.md)).

Store review copy: **[PERMISSIONS.md](./PERMISSIONS.md)**

## Result shape

```json
{
  "matched": true,
  "matchedSlot": "sim1",
  "sessionId": "sess_…",
  "status": "completed",
  "platform": "android"
}
```

## Web (browser)

Capacitor web fallback opens a tab — **no line match**. Ship native Android/iOS for production verify.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Plugin not found | `npx cap sync` |
| Unresolved `:truzzt-sdk` | Add Gradle module |
| Chrome / web only | Use native platform |

## License

Proprietary — Kreate Technologies LLC / Truzzt.
