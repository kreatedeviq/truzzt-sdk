import { NativeModules, Platform } from 'react-native';

const { Niv2fa } = NativeModules;

export async function requestPermissions() {
  return Niv2fa.requestPermissions();
}

export async function getSimPhones() {
  return Niv2fa.getSimPhones();
}

/** Open in-app verify for a NIV2FA session URL. */
export async function openVerify(url) {
  return Niv2fa.openVerify({ url });
}

export default { requestPermissions, getSimPhones, openVerify, Platform };
