# NIV2FA Cordova / Ionic Cordova plugin

`cordova-plugin-niv2fa` — verify inside Cordova / Ionic Cordova apps.

Repo: https://github.com/kreatedeviq/niv2fa-sdk  
Package path: `packages/cordova`

## Install

```bash
git clone https://github.com/kreatedeviq/niv2fa-sdk.git
cordova plugin add /absolute/path/to/niv2fa-sdk/packages/cordova
# or
ionic cordova plugin add /absolute/path/to/niv2fa-sdk/packages/cordova
```

From Git (after push):

```bash
cordova plugin add https://github.com/kreatedeviq/niv2fa-sdk.git#main:packages/cordova
```

Also include the Android library module `niv2fa-sdk/android` in your Cordova Android platform project (Gradle `include` / copy sources as documented in ANDROID.md).

## Permissions

Declared in `plugin.xml` for Android. iOS camera usage string is injected into Info.plist.

## Methods (JS)

```js
Niv2fa.requestPermissions(
  function (r) { console.log(r); },
  function (e) { console.error(e); }
);

Niv2fa.getSimPhones(
  function (r) { console.log(r.sims); },
  console.error
);

Niv2fa.openVerify(
  { url: verifyUrl },
  function (r) {
    if (r.matched) {
      console.log(r.matchedSlot, r.sessionId);
    }
  },
  console.error
);
```

Also available as `cordova.plugins.Niv2fa`.

| Method | Args | Success payload |
|--------|------|-----------------|
| `requestPermissions` | — | `{ requested }` |
| `getSimPhones` | — | `{ sims, platform }` |
| `openVerify` | `{ url \| sessionUrl }` | `{ matched, matchedSlot, sessionId, … }` |

## Ionic Angular (Cordova)

```ts
declare const Niv2fa: any;

async verify(url: string) {
  await new Promise((resolve, reject) => Niv2fa.requestPermissions(resolve, reject));
  const r = await new Promise<any>((resolve, reject) => Niv2fa.openVerify({ url }, resolve, reject));
  return r;
}
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Niv2fa is not defined` | Ensure device ready; plugin installed; rebuild native |
| ClassNotFound `Niv2faSdk` | Link `niv2fa-sdk/android` library into Cordova Android |
| iOS empty SIMs | Expected |
