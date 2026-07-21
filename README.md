# NIV2FA SDK & plugins

**GitHub:** https://github.com/kreatedeviq/niv2fa-sdk  
**Website docs:** https://jeebly.kreateiq.com/niv2fa/docs/sdk  
**Standalone Agent APK (optional):** https://jeebly.kreateiq.com/niv2fa/agent  

Embed Network Identity verification inside **your** mobile apps (SIM1/SIM2 match on Android → project webhook).

## Packages

| Platform | Path | Guide |
|----------|------|--------|
| Android Java/Kotlin | [`android/`](./android) | [docs/ANDROID.md](./docs/ANDROID.md) |
| iOS Swift (SPM) | [`ios/`](./ios) | [docs/IOS.md](./docs/IOS.md) |
| Capacitor / Ionic | [`packages/capacitor`](./packages/capacitor) | [docs/CAPACITOR.md](./docs/CAPACITOR.md) |
| Cordova | [`packages/cordova`](./packages/cordova) | [docs/CORDOVA.md](./docs/CORDOVA.md) |
| Flutter | [`packages/flutter`](./packages/flutter) | [docs/FLUTTER.md](./docs/FLUTTER.md) |
| React Native | [`packages/react-native`](./packages/react-native) | [docs/REACT_NATIVE.md](./docs/REACT_NATIVE.md) |

## Install (clone)

```bash
git clone https://github.com/kreatedeviq/niv2fa-sdk.git
```

Then follow the platform guide above (Gradle module / SPM / npm / pub / Cordova plugin add).

## Shared API

```ts
await Niv2fa.requestPermissions()
await Niv2fa.getSimPhones()          // Android SIMs; iOS []
await Niv2fa.openVerify({ url })     // → { matched, matchedSlot, sessionId }
```

On success your **project webhook** receives `identity.verified`.

## Important

- **Android** = full SIM1/SIM2 match.
- **iOS** = in-app WebView only (Apple blocks SIM MSISDN).
- Standalone Agent APK is **not** replaced by this repo.

## License

Proprietary — Kreate Technologies LLC / NIV2FA.
