package com.niv2fa.sdk;

import com.niv2fa.sdk.R;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.webkit.PermissionRequest;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.activity.result.ActivityResultLauncher;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import org.json.JSONObject;

/**
 * In-app verify WebView with SIM bridge. Host apps should start via {@link Niv2faSdk#openVerify}.
 */
public class Niv2faVerifyActivity extends AppCompatActivity {
    public static final String EXTRA_URL = "niv2fa_url";
    public static final String EXTRA_RESULT_JSON = "niv2fa_result";

    private WebView webView;
    private SimBridge simBridge;
    private boolean finished;

    public static Intent intent(Activity from, String url) {
        Intent i = new Intent(from, Niv2faVerifyActivity.class);
        i.putExtra(EXTRA_URL, url);
        return i;
    }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.niv2fa_activity_verify);
        webView = findViewById(R.id.niv2fa_webview);
        simBridge = new SimBridge(this);
        simBridge.ensurePermissions();
        setupWebView();
        String url = getIntent() != null ? getIntent().getStringExtra(EXTRA_URL) : null;
        if (url == null || url.trim().isEmpty()) {
            finishWithError("missing_url", "Verify URL is required");
            return;
        }
        webView.loadUrl(url.trim());
    }

    @SuppressLint({"SetJavaScriptEnabled", "AddJavascriptInterface"})
    private void setupWebView() {
        WebSettings s = webView.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setUserAgentString(s.getUserAgentString() + " NIV2FASdk/1.0");

        webView.addJavascriptInterface(simBridge, "AndroidBridge");
        webView.addJavascriptInterface(simBridge, "Niv2faAgent");
        webView.addJavascriptInterface(simBridge, "NivBridge");
        webView.addJavascriptInterface(new HostBridge(this::handleHostResult), "Niv2faHost");

        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onPermissionRequest(final PermissionRequest request) {
                runOnUiThread(() -> request.grant(request.getResources()));
            }
        });

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                view.evaluateJavascript(
                        "(function(){try{window.__NIV2FA_AGENT__=true;window.__NIV2FA_SDK__=true;"
                                + "window.Niv2faAgent=window.Niv2faAgent||window.AndroidBridge;"
                                + "window.AndroidBridge=window.AndroidBridge||window.Niv2faAgent;"
                                + "}catch(e){}})();",
                        null
                );
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                Uri uri = request.getUrl();
                if (uri == null) return false;
                String host = uri.getHost() == null ? "" : uri.getHost();
                if (host.contains("jeebly.kreateiq.com") || host.contains("localhost") || host.contains("kreateiq.com")) {
                    return false;
                }
                try {
                    startActivity(new Intent(Intent.ACTION_VIEW, uri));
                } catch (Exception ignored) {}
                return true;
            }
        });
    }

    private void handleHostResult(String json) {
        if (finished) return;
        finished = true;
        Intent data = new Intent();
        data.putExtra(EXTRA_RESULT_JSON, json == null ? "{}" : json);
        setResult(Activity.RESULT_OK, data);
        finish();
    }

    private void finishWithError(String code, String message) {
        if (finished) return;
        finished = true;
        try {
            JSONObject o = new JSONObject();
            o.put("matched", false);
            o.put("status", "error");
            o.put("code", code);
            o.put("message", message);
            Intent data = new Intent();
            data.putExtra(EXTRA_RESULT_JSON, o.toString());
            setResult(Activity.RESULT_CANCELED, data);
        } catch (Exception ignored) {
            setResult(Activity.RESULT_CANCELED);
        }
        finish();
    }

    @Override
    public void onBackPressed() {
        if (webView != null && webView.canGoBack()) {
            webView.goBack();
        } else {
            finishWithError("cancelled", "User cancelled verification");
        }
    }
}
