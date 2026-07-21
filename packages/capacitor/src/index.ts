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

export interface Niv2faPlugin {
  requestPermissions(): Promise<{ requested: boolean }>;
  getSimPhones(): Promise<Niv2faSimPhonesResult>;
  openVerify(options: Niv2faVerifyOptions): Promise<Niv2faVerifyResult>;
}

const Niv2fa = registerPlugin<Niv2faPlugin>('Niv2fa', {
  web: () => import('./web').then((m) => new m.Niv2faWeb()),
});

export default Niv2fa;
