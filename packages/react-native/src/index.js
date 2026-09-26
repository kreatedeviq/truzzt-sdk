import { NativeModules, Platform } from 'react-native';

const { Truzzt } = NativeModules;

let _cfg = null;
const DEFAULT_BASE = 'https://truzzt.site';

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

export async function configure({ apiKey, projectId, baseUrl, theme } = {}) {
  _cfg = {
    apiKey: String(apiKey || '').trim(),
    projectId: String(projectId || '').trim(),
    baseUrl,
    theme: theme || null,
  };
  if (Truzzt && typeof Truzzt.configure === 'function') {
    await Truzzt.configure(_cfg);
  }
  return assertAccess();
}

function applyThemeToUrl(url, theme) {
  if (!url || !theme) return url;
  const parts = Object.entries(theme)
    .filter(([, v]) => v != null && String(v).trim() !== '')
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v).trim())}`);
  if (!parts.length) return url;
  return url + (url.includes('?') ? '&' : '?') + parts.join('&');
}

export async function requestPermissions() {
  await assertAccess();
  return Truzzt.requestPermissions();
}

export async function getSimPhones() {
  await assertAccess();
  return Truzzt.getSimPhones();
}

export async function openVerify(urlOrOpts) {
  await assertAccess();
  const opts = typeof urlOrOpts === 'string' ? { url: urlOrOpts } : (urlOrOpts || {});
  const raw = opts.url || opts.sessionUrl || '';
  const themed = applyThemeToUrl(raw, opts.theme || _cfg?.theme);
  return Truzzt.openVerify({ url: themed, sessionUrl: themed });
}

export default { configure, requestPermissions, getSimPhones, openVerify, Platform };
