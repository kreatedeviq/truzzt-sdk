# Truzzt SDK & plugins

**NO OTP · OTP-LESS · OTP IS GONE** — verify the phone on-device (SIM / Contacts), not SMS codes.

**GitHub:** https://github.com/kreatedeviq/truzzt-sdk  
**Website docs:** https://truzzt.site/docs/sdk  
**Live demo:** https://truzzt.site/agent/app  
**Agent APK:** [Release v2.0.0](https://github.com/kreatedeviq/truzzt-sdk/releases/tag/v2.0.0)

Embed **Network Identity** in your app: read device lines (Android SIM + Contacts; iOS Contacts Me / owner lines), open a themed verify WebView, match the session phone. Webhook: `identity.verified`.  
**No OTP. No SMS codes. No QR in the primary UX.**

## Product flow

1. Host app: Login / Register / Forgot (password optional).
2. Backend: `POST https://truzzt.site/secure-api/v1/verifications` (Bearer key + `projectId`, `phone`, `purpose`, `returnUrl`…).
3. Open returned **`verifyUrl`** with **`openVerify`** inside the SDK.
4. SDK reads lines → match → `matched: true` + webhook.

Browsers alone cannot match lines (Try again shell only).

## Platform matrix

| Platform | Path | Guide |
|----------|------|--------|
| Android Java/Kotlin | [`android/`](./android) | [docs/ANDROID.md](./docs/ANDROID.md) |
| iOS Swift (SPM) | [`ios/`](./ios) | [docs/IOS.md](./docs/IOS.md) |
| Capacitor / Ionic | [`packages/capacitor`](./packages/capacitor) | [docs/CAPACITOR.md](./docs/CAPACITOR.md) |
| Cordova | [`packages/cordova`](./packages/cordova) | [docs/CORDOVA.md](./docs/CORDOVA.md) |
| Flutter | [`packages/flutter`](./packages/flutter) | [docs/FLUTTER.md](./docs/FLUTTER.md) |
| React Native | [`packages/react-native`](./packages/react-native) | [docs/REACT_NATIVE.md](./docs/REACT_NATIVE.md) |
| Expo (Dev Client) | [`packages/expo`](./packages/expo) | [docs/EXPO.md](./docs/EXPO.md) |
| Permissions (Play / App Store) | — | **[docs/PERMISSIONS.md](./docs/PERMISSIONS.md)** |

## Install

Clone once (all platforms share this repo):

```bash
git clone https://github.com/kreatedeviq/truzzt-sdk.git
```

### Android (Java / Kotlin)

```gradle
// settings.gradle
include ':truzzt-sdk'
project(':truzzt-sdk').projectDir = new File(settingsDir, '../truzzt-sdk/android')

// app/build.gradle
dependencies { implementation project(':truzzt-sdk') }
```

### iOS (Swift Package Manager)

```swift
.package(url: "https://github.com/kreatedeviq/truzzt-sdk.git", from: "2.0.0")
// product: TruzztSdk
```

### Capacitor / Ionic

```bash
npm install ./truzzt-sdk/packages/capacitor
# or: npm install github:kreatedeviq/truzzt-sdk#main --workspace=@truzzt/capacitor  (path install preferred)
npx cap sync
```

Link native `:truzzt-sdk` Android module + iOS SPM — see [CAPACITOR.md](./docs/CAPACITOR.md).

### Cordova

```bash
cordova plugin add ./truzzt-sdk/packages/cordova
# or from a clone path:
# cordova plugin add /absolute/path/truzzt-sdk/packages/cordova
```

Also include `truzzt-sdk/android` as a library module — see [CORDOVA.md](./docs/CORDOVA.md).

### Flutter

```yaml
# pubspec.yaml
dependencies:
  truzzt_flutter:
    git:
      url: https://github.com/kreatedeviq/truzzt-sdk.git
      path: packages/flutter
```

```bash
flutter pub get
```

### React Native

```bash
npm install ./truzzt-sdk/packages/react-native
# link TruzztPackage (Android) + TruzztSdk SPM (iOS) — see REACT_NATIVE.md
```

### Expo (Dev Client — not Expo Go)

```bash
npm install ./truzzt-sdk/packages/expo ./truzzt-sdk/packages/react-native
```

```json
{ "expo": { "plugins": ["@truzzt/expo"] } }
```

```bash
npx expo prebuild
npx expo run:android
# or: npx expo run:ios
```

## Shared API

```ts
await Truzzt.configure({
  apiKey: 'trz_live_…',
  projectId: 'proj_…',
  theme: {
    primary: '#0B1F3A',
    accent: '#FFC83D',      // preloader / spinner
    background: '#071525',
    text: '#F7F4EE',
    muted: '#94A3B8',
    appName: 'MyApp',
    logoUrl: 'https://…',
  },
});

await Truzzt.requestPermissions();
await Truzzt.getSimPhones();
const r = await Truzzt.openVerify({ url: verifyUrl });
// → { matched, matchedSlot, sessionId, status, … }
```

Theme keys: `accent`, `background`, `text`, `muted`, `primary`, `appName`, `logoUrl`.

## Important

- **OTP-less** — Network Identity match only (no SMS OTP).
- Configure before any SDK call.
- Android: Phone + Contacts. iOS: Contacts Me / owner contacts.
- Open `verifyUrl` **inside the SDK**, not Chrome alone.
- Webhook `identity.verified` is source of truth.
- Store permission copy: [PERMISSIONS.md](./docs/PERMISSIONS.md) (short).

## License

Proprietary — Kreate Technologies LLC / Truzzt.
