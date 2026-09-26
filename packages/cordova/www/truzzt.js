var exec = require('cordova/exec');

var _cfg = null;
var DEFAULT_BASE = 'https://truzzt.site';

function assertAccess(success, error) {
  if (!_cfg || !_cfg.apiKey || !_cfg.projectId) {
    error && error({ code: 'CONFIG_REQUIRED', message: 'Call Truzzt.configure({ apiKey, projectId }) first' });
    return;
  }
  var base = (_cfg.baseUrl || DEFAULT_BASE).replace(/\/$/, '');
  var url = base + '/secure-api/v1/sdk/access?projectId=' + encodeURIComponent(_cfg.projectId);
  fetch(url, { headers: { Authorization: 'Bearer ' + _cfg.apiKey } })
    .then(function (r) {
      return r.json().then(function (j) {
        return { ok: r.ok, j: j };
      });
    })
    .then(function (x) {
      if (!x.ok || !x.j.success) {
        error && error({ code: (x.j && x.j.code) || 'ACCESS_DENIED', message: (x.j && x.j.message) || 'SDK access denied' });
        return;
      }
      success && success(x.j.data || { ok: true });
    })
    .catch(function (e) {
      error && error({ code: 'NETWORK', message: String(e && e.message || e) });
    });
}

exports.configure = function (opts, success, error) {
  opts = opts || {};
  _cfg = {
    apiKey: String(opts.apiKey || '').trim(),
    projectId: String(opts.projectId || '').trim(),
    baseUrl: opts.baseUrl,
    theme: opts.theme || null
  };
  exec(
    function () {
      assertAccess(success, error);
    },
    function () {
      assertAccess(success, error);
    },
    'Truzzt',
    'configure',
    [_cfg]
  );
};

function applyThemeToUrl(url, theme) {
  if (!url || !theme) return url;
  var parts = [];
  Object.keys(theme).forEach(function (k) {
    var v = theme[k];
    if (v == null || String(v).trim() === '') return;
    parts.push(encodeURIComponent(k) + '=' + encodeURIComponent(String(v).trim()));
  });
  if (!parts.length) return url;
  return url + (url.indexOf('?') >= 0 ? '&' : '?') + parts.join('&');
}

exports.requestPermissions = function (success, error) {
  assertAccess(function () {
    exec(success, error, 'Truzzt', 'requestPermissions', []);
  }, error);
};

exports.getSimPhones = function (success, error) {
  assertAccess(function () {
    exec(success, error, 'Truzzt', 'getSimPhones', []);
  }, error);
};

exports.openVerify = function (opts, success, error) {
  assertAccess(function () {
    opts = opts || {};
    var raw = opts.url || opts.sessionUrl || '';
    var themed = applyThemeToUrl(raw, opts.theme || (_cfg && _cfg.theme));
    exec(success, error, 'Truzzt', 'openVerify', [{ url: themed, sessionUrl: themed }]);
  }, error);
};
