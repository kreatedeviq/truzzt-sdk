const {
  withAndroidManifest,
  AndroidConfig,
  withInfoPlist,
} = require('@expo/config-plugins');

/** Play / App Store justifications: docs/PERMISSIONS.md */
const ANDROID_PERMISSIONS = [
  'android.permission.INTERNET',
  'android.permission.ACCESS_NETWORK_STATE',
  'android.permission.READ_PHONE_STATE',
  'android.permission.READ_PHONE_NUMBERS',
  'android.permission.READ_CONTACTS',
];

const IOS_CONTACTS_USAGE =
  'Truzzt needs access to Contacts to read your My Card (Me) number and any contact you saved as your own phone (for example “My number” or “رقمي”), so we can verify that this device owns the phone number used for login or registration. We do not sync your full address book.';

function withTruzztAndroidPermissions(config) {
  return withAndroidManifest(config, (cfg) => {
    const manifest = cfg.modResults;
    AndroidConfig.Permissions.ensurePermissions(manifest, ANDROID_PERMISSIONS);
    return cfg;
  });
}

function withTruzztIosContacts(config) {
  return withInfoPlist(config, (cfg) => {
    cfg.modResults.NSContactsUsageDescription =
      cfg.modResults.NSContactsUsageDescription || IOS_CONTACTS_USAGE;
    return cfg;
  });
}

/** @type {import('@expo/config-plugins').ConfigPlugin} */
module.exports = function withTruzzt(config) {
  config = withTruzztAndroidPermissions(config);
  config = withTruzztIosContacts(config);
  return config;
};
