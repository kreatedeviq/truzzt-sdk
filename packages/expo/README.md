# @truzzt/expo

Expo wrapper for Truzzt Network Identity verify. Same API as [`@truzzt/react-native`](../react-native).

**Expo Go is not supported** (native SIM / Contacts bridge). Use **Expo Dev Client** or `expo prebuild` + a development build.

Full guide: [docs/EXPO.md](../../docs/EXPO.md) · Permissions (store review): [docs/PERMISSIONS.md](../../docs/PERMISSIONS.md) · Repo: https://github.com/kreatedeviq/truzzt-sdk

## Quick install

```bash
npm install @truzzt/expo @truzzt/react-native
```

`app.json`:

```json
{
  "expo": {
    "plugins": ["@truzzt/expo"]
  }
}
```

Link native modules (see EXPO.md), then:

```js
import { configure, openVerify } from '@truzzt/expo';

await configure({
  apiKey: 'trz_live_…',
  projectId: 'proj_…',
  theme: { primary: '#0B1F3A', accent: '#FFC83D', appName: 'MyApp' },
});

const r = await openVerify({ url: verifyUrl });
```

## License

Proprietary — Kreate Technologies LLC / Truzzt.
