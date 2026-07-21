# NIV2FA React Native plugin

`@niv2fa/react-native` — open NIV2FA verify from React Native.

Repo: https://github.com/kreatedeviq/niv2fa-sdk  
Package path: `packages/react-native`

## Install

```bash
git clone https://github.com/kreatedeviq/niv2fa-sdk.git
cd YourApp
npm install ../niv2fa-sdk/packages/react-native
# or yarn add ../niv2fa-sdk/packages/react-native
```

From Git:

```json
"@niv2fa/react-native": "github:kreatedeviq/niv2fa-sdk#main"
```

(You may need a thin package publish or `npm` git subdirectory tooling; preferred: local path or monorepo.)

### Android

1. Include `:niv2fa-sdk` module (see ANDROID.md).
2. Register package in `MainApplication`:

```java
import com.niv2fa.rn.Niv2faPackage;

@Override
protected List<ReactPackage> getPackages() {
  return Arrays.asList(
    new MainReactPackage(),
    new Niv2faPackage()
  );
}
```

### iOS

Link `Niv2faSdk` Swift package and the RN bridge files under `packages/react-native/ios`.  
Add `NSCameraUsageDescription`.

## Methods

```js
import { requestPermissions, getSimPhones, openVerify } from '@niv2fa/react-native';

await requestPermissions();
const { sims } = await getSimPhones();
const r = await openVerify(verifyUrl);

if (r.matched) {
  console.log(r.matchedSlot, r.sessionId);
}
```

| Method | Returns |
|--------|---------|
| `requestPermissions()` | `{ requested }` |
| `getSimPhones()` | `{ sims, platform }` |
| `openVerify(url)` | `{ matched, matchedSlot, sessionId, status, … }` |

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Native module null | Rebuild app; register `Niv2faPackage` |
| ClassNotFound Niv2faSdk | Add android library module |
| iOS share dialog | User must Allow, then enter SIM1/(SIM2) |
