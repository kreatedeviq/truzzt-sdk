import type { TruzztPlugin, TruzztVerifyOptions, TruzztVerifyResult, TruzztSimPhonesResult } from './index';

/** Browser fallback — cannot read SIM; opens verify URL in a new tab. */
export class TruzztWeb implements TruzztPlugin {
  async requestPermissions() {
    return { requested: false };
  }

  async getSimPhones(): Promise<TruzztSimPhonesResult> {
    return { sims: [], platform: 'web' };
  }

  async openVerify(options: TruzztVerifyOptions): Promise<TruzztVerifyResult> {
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
