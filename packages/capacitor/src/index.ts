import { registerPlugin } from '@capacitor/core';

export interface Niv2faVerifyOptions {
  url?: string;
  sessionUrl?: string;
}

export interface Niv2faVerifyResult {
  matched: boolean;
  status?: string;
  matchedSlot?: string | null;
  sessionId?: string | null;
  code?: string | null;
  message?: string | null;
  platform?: string;
}

export interface Niv2faSimPhonesResult {
  sims: Array<{ slot?: string; phone?: string; msisdn?: string }>;
  platform?: string;
}

export interface Niv2faConfig {
  apiKey: string;
  projectId: string;
  baseUrl?: string;
}

export interface Niv2faPlugin {
  configure?(options: Niv2faConfig): Promise<{ ok: boolean }>;
  requestPermissions(): Promise<{ requested: boolean }>;
  getSimPhones(): Promise<Niv2faSimPhonesResult>;
  openVerify(options: Niv2faVerifyOptions): Promise<Niv2faVerifyResult>;
}

const Native = registerPlugin<Niv2faPlugin>('Niv2fa', {
  web: () => import('./web').then((m) => new m.Niv2faWeb()),
});

let _cfg: Niv2faConfig | null = null;
const DEFAULT_BASE = 'https://jeebly.kreateiq.com/niv2fa';

async function assertAccess() {
  if (!_cfg?.apiKey || !_cfg?.projectId) {
    throw Object.assign(new Error('Call Niv2fa.configure({ apiKey, projectId }) first'), {
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

const Niv2fa = {
  async configure(options: Niv2faConfig) {
    _cfg = {
      apiKey: String(options.apiKey || '').trim(),
      projectId: String(options.projectId || '').trim(),
      baseUrl: options.baseUrl,
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
  async openVerify(options: Niv2faVerifyOptions) {
    await assertAccess();
    return Native.openVerify(options);
  },
};

export default Niv2fa;
