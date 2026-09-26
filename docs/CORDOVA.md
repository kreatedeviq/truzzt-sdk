# Truzzt Cordova / Ionic Cordova plugin

`cordova-plugin-truzzt` — open **`verifyUrl`** from your Login / Register / Forgot UI.

Repo: https://github.com/kreatedeviq/truzzt-sdk  
Package path: `packages/cordova`  
Demo: https://truzzt.site/agent/app

## Install

```bash
git clone https://github.com/kreatedeviq/truzzt-sdk.git
cordova plugin add /path/to/truzzt-sdk/packages/cordova
```

Link Android library `truzzt-sdk/android` per [ANDROID.md](./ANDROID.md).

## Configure + theme

```js
Truzzt.configure(
  {
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
  },
  function () {},
  console.error
);
```

## Create verification (backend)

Your server calls `POST /secure-api/v1/verifications` and returns `verifyUrl` to the WebView layer. Optional **`theme`** in the JSON body.

## openVerify

```js
Truzzt.requestPermissions(function () {
  Truzzt.openVerify(
    { url: verifyUrl },
    function (r) {
      if (r.matched) console.log(r.matchedSlot, r.sessionId);
    },
    console.error
  );
}, console.error);
```

Per-call theme: `{ url: verifyUrl, theme: { accent: '#FFC83D' } }` (merged with configure theme on URL).

## Permissions

Android (`plugin.xml`): `INTERNET`, `ACCESS_NETWORK_STATE`, `READ_PHONE_STATE`, `READ_PHONE_NUMBERS`, `READ_CONTACTS` — **no Camera**.  
iOS: plugin injects `NSContactsUsageDescription` (My Card / owner-number match).

Store review copy: **[PERMISSIONS.md](./PERMISSIONS.md)**

## Result shape

```json
{
  "matched": true,
  "matchedSlot": "sim1",
  "sessionId": "sess_…",
  "status": "completed"
}
```

Also available as `cordova.plugins.Truzzt`.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Truzzt is not defined` | Device ready + rebuild |
| ClassNotFound TruzztSdk | Link android module |
| Opened verify in system browser | Use `openVerify` in plugin |

## License

Proprietary — Kreate Technologies LLC / Truzzt.
