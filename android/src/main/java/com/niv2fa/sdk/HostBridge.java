package com.niv2fa.sdk;

import android.webkit.JavascriptInterface;

/**
 * Called from verify page: window.Niv2faHost.onResult(json)
 */
public final class HostBridge {
    public interface Listener {
        void onResult(String json);
    }

    private final Listener listener;

    public HostBridge(Listener listener) {
        this.listener = listener;
    }

    @JavascriptInterface
    public void onResult(String json) {
        if (listener != null) listener.onResult(json);
    }

    @JavascriptInterface
    public void postMessage(String json) {
        onResult(json);
    }
}
