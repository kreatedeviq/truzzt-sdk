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
// Required — dashboard API key + project (active trial or subscription)
await Niv2fa.configure({ apiKey: 'niv_live_…', projectId: 'proj_…' })

await Niv2fa.requestPermissions()
await Niv2fa.getSimPhones()
await Niv2fa.openVerify({ url })   // → { matched, matchedSlot, sessionId }
```

Backend `POST /secure-api/v1/verifications` also requires `projectId` + valid Bearer key.  
Fails with `PLAN_REQUIRED` (402) if trial ended and no subscription.

On success your **project webhook** receives `identity.verified`.

## Important

- **Configure first** or SDK methods / API return errors.
- **Android:** Phone permission → auto-read SIM1/SIM2 → match.
- **iOS:** custom **Activate account** Allow (no system Phone warning) → activation match.
- Chrome cannot verify — open `verifyUrl` inside the SDK.
- Standalone Agent APK is an optional Android helper.

## License

Proprietary — Kreate Technologies LLC / NIV2FA.
