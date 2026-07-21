# NIV2FA Flutter plugin

`niv2fa_flutter` — open NIV2FA verify from Flutter.

Repo: https://github.com/kreatedeviq/niv2fa-sdk  
Package path: `packages/flutter`

## Install

`pubspec.yaml`:

```yaml
dependencies:
  niv2fa_flutter:
    git:
      url: https://github.com/kreatedeviq/niv2fa-sdk.git
      path: packages/flutter
```

Or local path:

```yaml
  niv2fa_flutter:
    path: ../niv2fa-sdk/packages/flutter
```

### Android library

`android/settings.gradle`:

```gradle
include ':niv2fa-sdk'
project(':niv2fa-sdk').projectDir = new File(rootProject.projectDir, '../../niv2fa-sdk/android')
```

`android/app/build.gradle` (or the plugin’s android build) must `implementation project(':niv2fa-sdk')`.

### iOS

```bash
cd ios && pod install
```

Add camera usage to `Info.plist` if not present.

## Methods

```dart
import 'package:niv2fa_flutter/niv2fa_flutter.dart';

await Niv2faFlutter.requestPermissions();
final sims = await Niv2faFlutter.getSimPhones();
final r = await Niv2faFlutter.openVerify(verifyUrl);

if (r['matched'] == true) {
  final slot = r['matchedSlot'];
  final sessionId = r['sessionId'];
}
```

| Method | Returns |
|--------|---------|
| `requestPermissions()` | `Map` |
| `getSimPhones()` | `List` of sim maps |
| `openVerify(String url)` | `Map` with `matched`, `matchedSlot`, `sessionId`, … |

## Permissions

Android: merged from SDK.  
iOS: `NSCameraUsageDescription`.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| MissingPluginException | Full restart / rebuild native |
| Unresolved niv2fa-sdk | Fix `settings.gradle` path |
| iOS sims empty | Expected |
