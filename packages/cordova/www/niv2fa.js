var exec = require('cordova/exec');

exports.requestPermissions = function (success, error) {
  exec(success, error, 'Niv2fa', 'requestPermissions', []);
};

exports.getSimPhones = function (success, error) {
  exec(success, error, 'Niv2fa', 'getSimPhones', []);
};

exports.openVerify = function (opts, success, error) {
  exec(success, error, 'Niv2fa', 'openVerify', [opts || {}]);
};
