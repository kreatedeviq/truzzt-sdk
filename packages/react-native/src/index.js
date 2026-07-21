import { NativeModules, Platform } from 'react-native';

const { Niv2fa } = NativeModules;

let _cfg = null;
const DEFAULT_BASE = 'https://jeebly.kreateiq.com/niv2fa';

async function assertAccess() {
  if (!_cfg?.apiKey || !_cfg?.projectId) {
    const e = new Error('Call configure({ apiKey, projectId }) first');
    e.code = 'CONFIG_REQUIRED';
    throw e;
  }
  const base = (_cfg.baseUrl || DEFAULT_BASE).replace(/\/$/, '');
  const url = `${base}/secure-api/v1/sdk/access?projectId=${encodeURIComponent(_cfg.projectId)}`;
  const res = await fetch(url, { headers: { Authorization: `Bearer ${_cfg.apiKey}` } });
  const body = await res.json().catch(() => ({}));
  if (!res.ok || !body.success) {
    const e = new Error(body.message || 'SDK access denied');
    e.code = body.code || 'ACCESS_DENIED';
    throw e;
  }
  return body.data;
}

export async function configure({ apiKey, projectId, baseUrl } = {}) {
  _cfg = {
    apiKey: String(apiKey || '').trim(),
    projectId: String(projectId || '').trim(),
    baseUrl,
  };
  if (Niv2fa && typeof Niv2fa.configure === 'function') {
    await Niv2fa.configure(_cfg);
  }
  return assertAccess();
}

export async function requestPermissions() {
  await assertAccess();
  return Niv2fa.requestPermissions();
}

export async function getSimPhones() {
  await assertAccess();
  return Niv2fa.getSimPhones();
}

export async function openVerify(url) {
  await assertAccess();
  return Niv2fa.openVerify({ url });
}

export default { configure, requestPermissions, getSimPhones, openVerify, Platform };
