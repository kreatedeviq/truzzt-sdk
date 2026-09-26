import { registerPlugin } from '@capacitor/core';

export interface TruzztTheme {
  primary?: string;
  primaryColor?: string;
  accent?: string;
  accentColor?: string;
  background?: string;
  bg?: string;
  backgroundColor?: string;
  text?: string;
  textColor?: string;
  muted?: string;
  appName?: string;
  name?: string;
  logoUrl?: string;
  logo?: string;
}

export interface TruzztVerifyOptions {
  url?: string;
  sessionUrl?: string;
  theme?: TruzztTheme;
}

export interface TruzztVerifyResult {
  matched: boolean;
  status?: string;
  matchedSlot?: string | null;
  sessionId?: string | null;
  code?: string | null;
  message?: string | null;
  platform?: string;
}

export interface TruzztSimPhonesResult {
  sims: Array<{ slot?: string; phone?: string; msisdn?: string }>;
  platform?: string;
}

export interface TruzztConfig {
  apiKey: string;
  projectId: string;
  baseUrl?: string;
  /** Host-app palette applied to the verify WebView */
  theme?: TruzztTheme;
}

export interface TruzztPlugin {
  configure?(options: TruzztConfig): Promise<{ ok: boolean }>;
  requestPermissions(): Promise<{ requested: boolean }>;
  getSimPhones(): Promise<TruzztSimPhonesResult>;
  openVerify(options: TruzztVerifyOptions): Promise<TruzztVerifyResult>;
}

const Native = registerPlugin<TruzztPlugin>('Truzzt', {
  web: () => import('./web').then((m) => new m.TruzztWeb()),
});

let _cfg: TruzztConfig | null = null;
const DEFAULT_BASE = 'https://truzzt.site';

function applyThemeToUrl(url: string, theme?: TruzztTheme | null): string {
  if (!url || !theme) return url;
  const entries = Object.entries(theme).filter(([, v]) => v != null && String(v).trim() !== '');
  if (!entries.length) return url;
  const sep = url.includes('?') ? '&' : '?';
  const qs = entries
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v).trim())}`)
    .join('&');
  return `${url}${sep}${qs}`;
}

async function assertAccess() {
  if (!_cfg?.apiKey || !_cfg?.projectId) {
    throw Object.assign(new Error('Call Truzzt.configure({ apiKey, projectId }) first'), {
      code: 'CONFIG_REQUIRED',
    });
  }
  const base = (_cfg.baseUrl || DEFAULT_BASE).replace(/\/$/, '');
  const url = `${base}/secure-api/v1/sdk/access?projectId=${encodeURIComponent(_cfg.projectId)}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${_cfg.apiKey}` },
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok || !body.success) {
    const err = new Error(body.message || 'SDK access denied');
    (err as any).code = body.code || 'ACCESS_DENIED';
    throw err;
  }
  return body.data;
}

const Truzzt = {
  async configure(options: TruzztConfig) {
    _cfg = {
      apiKey: String(options.apiKey || '').trim(),
      projectId: String(options.projectId || '').trim(),
      baseUrl: options.baseUrl,
      theme: options.theme || undefined,
    };
    if (typeof Native.configure === 'function') {
      await Native.configure(_cfg);
    }
    return assertAccess();
  },
  async requestPermissions() {
    await assertAccess();
    return Native.requestPermissions();
  },
  async getSimPhones() {
    await assertAccess();
    return Native.getSimPhones();
  },
  async openVerify(options: TruzztVerifyOptions) {
    await assertAccess();
    const raw = options.url || options.sessionUrl || '';
    const themed = applyThemeToUrl(raw, options.theme || _cfg?.theme);
    return Native.openVerify({ ...options, url: themed, sessionUrl: themed });
  },
};

export default Truzzt;
