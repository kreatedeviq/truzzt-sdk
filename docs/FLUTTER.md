# Truzzt Flutter plugin

`truzzt_flutter` — backend **`verifyUrl`** → **`TruzztFlutter.openVerify`**.

Repo: https://github.com/kreatedeviq/truzzt-sdk  
Package path: `packages/flutter`  
Demo: https://truzzt.site/agent/app

## Install

```yaml
dependencies:
  truzzt_flutter:
    git:
      url: https://github.com/kreatedeviq/truzzt-sdk.git
      path: packages/flutter
```

Android: `include ':truzzt-sdk'` — [ANDROID.md](./ANDROID.md).  
iOS: `pod install`, `NSContactsUsageDescription` — [IOS.md](./IOS.md).  
Store review reasons: **[PERMISSIONS.md](./PERMISSIONS.md)**.

## Configure + theme

```dart
import 'package:truzzt_flutter/truzzt_flutter.dart';

await TruzztFlutter.configure(
  apiKey: 'trz_live_…',
  projectId: 'proj_…',
  theme: {
    'primary': '#0B1F3A',
    'accent': '#FFC83D',
    'background': '#071525',
    'text': '#F7F4EE',
    'muted': '#64748B',
    'appName': 'MyApp',
    'logoUrl': 'https://…',
  },
);
```

Theme is passed to native `configure` and appended to URLs in Dart via `TruzztFlutter.applyThemeToUrl`.

## Create verification (backend)

```dart
// Your server POST /secure-api/v1/verifications → verifyUrl
final verifyUrl = session['verifyUrl'] as String;
```

Optional **`theme`** on the verification request body (server applies to hosted verify page).

## openVerify

```dart
await TruzztFlutter.requestPermissions();
final r = await TruzztFlutter.openVerify(verifyUrl);
// Per-call theme:
// await TruzztFlutter.openVerify(verifyUrl, theme: {'accent': '#FFC83D'});

if (r['matched'] == true) {
  final slot = r['matchedSlot'];
  final sessionId = r['sessionId'];
}
```

## Permissions

Android: phone + contacts from SDK manifest.  
iOS: Contacts usage string.

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

## Methods

| Method | Notes |
|--------|--------|
| `configure(..., theme?)` | Required |
| `requestPermissions()` | |
| `getSimPhones()` | |
| `openVerify(url, { theme? })` | Themed WebView |
| `applyThemeToUrl(url, [theme])` | URL helper |

## Troubleshooting

| Issue | Fix |
|-------|-----|
| MissingPluginException | Full rebuild |
| Unresolved truzzt-sdk | Fix Gradle path |
| Safari / external browser | Use `openVerify` |

## License

Proprietary — Kreate Technologies LLC / Truzzt.
