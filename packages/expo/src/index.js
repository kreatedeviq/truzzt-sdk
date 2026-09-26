/**
 * @truzzt/expo — same API as @truzzt/react-native.
 *
 * Requires Expo Dev Client or `expo prebuild` (Expo Go cannot access SIM / native Truzzt module).
 * Install @truzzt/react-native and link the native android/ios modules per REACT_NATIVE.md.
 */
export {
  configure,
  requestPermissions,
  getSimPhones,
  openVerify,
  default,
} from '@truzzt/react-native';
