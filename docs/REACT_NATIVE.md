# Truzzt React Native plugin

`@truzzt/react-native` — Login / Register / Forgot flows: backend returns **`verifyUrl`**, app calls **`openVerify`**.

Repo: https://github.com/kreatedeviq/truzzt-sdk  
Package path: `packages/react-native`  
Demo: https://truzzt.site/agent/app

## Install

```bash
git clone https://github.com/kreatedeviq/truzzt-sdk.git
cd YourApp
npm install ../truzzt-sdk/packages/react-native
```

### Android

1. Include `:truzzt-sdk` module — see [ANDROID.md](./ANDROID.md).
2. Register in `MainApplication`:

```java
import com.truzzt.rn.TruzztPackage;

@Override
protected List<ReactPackage> getPackages() {
  return Arrays.asList(new MainReactPackage(), new TruzztPackage());
}
```

### iOS

Link `TruzztSdk` (SPM) + `packages/react-native/ios`. Add `NSContactsUsageDescription` — see [IOS.md](./IOS.md).  
Store review reasons (Play + App Store): **[PERMISSIONS.md](./PERMISSIONS.md)**.

## Configure + theme

```js
import { configure, requestPermissions, openVerify } from '@truzzt/react-native';

await configure({
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

```js
const res = await fetch('https://truzzt.site/secure-api/v1/verifications', {
  method: 'POST',
  headers: {
    Authorization: `Bearer ${API_KEY}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    projectId: 'proj_…',
    phone: '9647721421709',
    countryCode: '964',
    purpose: 'login',
    returnUrl: 'myapp://auth/done',
    cancelUrl: 'myapp://auth/cancel',
    theme: { accent: '#FFC83D', appName: 'MyApp' },
  }),
});
const { data } = await res.json();
const verifyUrl = data.verifyUrl || data.pairUrl;
```

## openVerify

```js
await requestPermissions();
const r = await openVerify({ url: verifyUrl });
// or openVerify(verifyUrl)
// Per-call theme: openVerify({ url: verifyUrl, theme: { accent: '#…' } })

if (r.matched) {
  console.log(r.matchedSlot, r.sessionId);
}
```

## Permissions

| OS | |
|----|---|
| Android | `READ_PHONE_STATE`, `READ_PHONE_NUMBERS`, `READ_CONTACTS` |
| iOS | Contacts |

## Result shape

```json
{
  "matched": true,
  "status": "completed",
  "matchedSlot": "sim1",
  "sessionId": "sess_…",
  "platform": "android"
}
```

## Expo

Use [`@truzzt/expo`](../packages/expo) + Dev Client — see [EXPO.md](./EXPO.md).

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Native module null | Rebuild; register `TruzztPackage` |
| ClassNotFound TruzztSdk | Add android library module |
| Browser verify | Cannot match — use SDK |

## License

Proprietary — Kreate Technologies LLC / Truzzt.
