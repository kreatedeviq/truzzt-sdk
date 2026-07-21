import type { Niv2faPlugin, Niv2faVerifyOptions, Niv2faVerifyResult, Niv2faSimPhonesResult } from './index';

/** Browser fallback — cannot read SIM; opens verify URL in a new tab. */
export class Niv2faWeb implements Niv2faPlugin {
  async requestPermissions() {
    return { requested: false };
  }

  async getSimPhones(): Promise<Niv2faSimPhonesResult> {
    return { sims: [], platform: 'web' };
  }

  async openVerify(options: Niv2faVerifyOptions): Promise<Niv2faVerifyResult> {
    const url = options.url || options.sessionUrl;
    if (!url) {
      return { matched: false, status: 'error', code: 'missing_url', platform: 'web' };
    }
    window.open(url, '_blank', 'noopener,noreferrer');
    return {
      matched: false,
      status: 'opened_browser',
      message: 'Opened in browser. Use Android/iOS native build for in-app SIM verify.',
      platform: 'web',
    };
  }
}
