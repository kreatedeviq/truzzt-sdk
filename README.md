# Truzzt SDK & plugins

**GitHub:** https://github.com/kreatedeviq/truzzt-sdk  
**Website docs:** https://truzzt.site/docs/sdk  
**Live demo (Login / Register / Forgot):** https://truzzt.site/agent/app  
**Standalone Agent APK (optional):** https://truzzt.site/agent  

Embed **Network Identity** verification inside your mobile apps: the SDK reads device phone lines (Android SIM + Contacts; iOS Contacts Me / owner lines), opens a themed verify WebView, and matches the session phone. Your **project webhook** receives `identity.verified`.

## Product flow (no QR in UX)

1. Host app shows **Login / Register / Forgot** (password optional).
2. Your backend: `POST https://truzzt.site/secure-api/v1/verifications` with Bearer API key, body includes `projectId`, `phone`, `countryCode`, `purpose` (`login` | `register` | `forgot_password`), `returnUrl`, `cancelUrl`, optional **`theme`**.
3. Response: **`verifyUrl`** — open this URL; no QR step required.
4. App calls **`openVerify(verifyUrl)`** — themed verify WebView.
5. SDK reads lines and the verify page POSTs to `/secure-api/identity/verify`.
6. Result: `matched: true` + webhook **`identity.verified`**.

Plain browsers show an agent-style shell with **Try again** — they cannot read SIM/Contacts lines.

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
| **Permissions (Play / App Store)** | — | **[docs/PERMISSIONS.md](./docs/PERMISSIONS.md)** |

## Install (clone)

```bash
git clone https://github.com/kreatedeviq/truzzt-sdk.git
```

Then follow the platform guide (Gradle module / SPM / npm / pub / Cordova plugin add / Expo plugin).

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

**Theme** can be set via `configure(…, theme)`, optional **`theme`** on create verification, and/or query params on `verifyUrl`. Keys: `accent`, `background`, `text`, `muted`, `primary`, `appName`, `logoUrl` (aliases like `primaryColor` also work on native).

Backend `POST /secure-api/v1/verifications` requires `projectId` + valid Bearer key. Fails with `PLAN_REQUIRED` (402) if the free first year ended and there is no subscription.

## Important

- **Configure first** or SDK methods / API return errors.
- **Android:** Phone + Contacts → SIM1/SIM2 and saved owner contacts. **No Camera / Call Phone.**
- **iOS:** Contacts **My Card (Me)** + saved **"My number"** / **"رقمي"** lines (not SIM chip).
- Open **`verifyUrl` inside the SDK** (or Agent app) — not Chrome alone.
- Treat the **webhook** as source of truth for your backend.
- **Store review:** copy permission reasons from **[docs/PERMISSIONS.md](./docs/PERMISSIONS.md)**.

## License

Proprietary — Kreate Technologies LLC / Truzzt.
