package com.niv2fa.sdk;

import android.app.Activity;
import android.content.Intent;
import android.os.Handler;
import android.os.Looper;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Public Android entry for embedding NIV2FA verify inside host apps.
 *
 * Must call {@link #configure(String, String)} (or with baseUrl) before use.
 * API works only with a valid dashboard API key + projectId on an active trial/plan.
 */
public final class Niv2faSdk {
    private Niv2faSdk() {}

    private static final ExecutorService IO = Executors.newSingleThreadExecutor();
    private static final Handler MAIN = new Handler(Looper.getMainLooper());

    private static volatile String apiKey = "";
    private static volatile String projectId = "";
    private static volatile String baseUrl = "https://jeebly.kreateiq.com/niv2fa";

    public interface ResultCallback {
        void onResult(JSONObject result);
    }

    public interface AccessCallback {
        void onAccess(JSONObject result);
    }

    /** Required before openVerify / getSimPhones. Values come from the developer dashboard. */
    public static void configure(String apiKey, String projectId) {
        configure(apiKey, projectId, null);
    }

    public static void configure(String apiKey, String projectId, String baseUrl) {
        Niv2faSdk.apiKey = apiKey == null ? "" : apiKey.trim();
        Niv2faSdk.projectId = projectId == null ? "" : projectId.trim();
        if (baseUrl != null && !baseUrl.trim().isEmpty()) {
            String b = baseUrl.trim();
            while (b.endsWith("/")) b = b.substring(0, b.length() - 1);
            Niv2faSdk.baseUrl = b;
        }
    }

    public static boolean isConfigured() {
        return apiKey.startsWith("niv_live_") && projectId.startsWith("proj_");
    }

    public static String getConfiguredProjectId() { return projectId; }
    public static String getConfiguredApiKey() { return apiKey; }
    public static String getBaseUrl() { return baseUrl; }

    /** Ask server: API key + projectId + trial/subscription OK? */
    public static void validateAccess(AccessCallback cb) {
        if (!isConfigured()) {
            MAIN.post(() -> cb.onAccess(error("CONFIG_REQUIRED",
                    "Call Niv2faSdk.configure(apiKey, projectId) with dashboard credentials first")));
            return;
        }
        IO.execute(() -> {
            try {
                URL url = new URL(baseUrl + "/secure-api/v1/sdk/access?projectId=" +
                        java.net.URLEncoder.encode(projectId, "UTF-8"));
                HttpURLConnection c = (HttpURLConnection) url.openConnection();
                c.setRequestMethod("GET");
                c.setRequestProperty("Authorization", "Bearer " + apiKey);
                c.setConnectTimeout(15000);
                c.setReadTimeout(15000);
                int code = c.getResponseCode();
                BufferedReader br = new BufferedReader(new InputStreamReader(
                        code >= 400 ? c.getErrorStream() : c.getInputStream(), StandardCharsets.UTF_8));
                StringBuilder sb = new StringBuilder();
                String line;
                while ((line = br.readLine()) != null) sb.append(line);
                br.close();
                JSONObject body = new JSONObject(sb.toString());
                if (code >= 400 || !body.optBoolean("success", false)) {
                    MAIN.post(() -> cb.onAccess(error(
                            body.optString("code", "ACCESS_DENIED"),
                            body.optString("message", "SDK access denied")
                    )));
                    return;
                }
                JSONObject data = body.optJSONObject("data");
                JSONObject ok = data != null ? data : new JSONObject();
                ok.put("ok", true);
                MAIN.post(() -> cb.onAccess(ok));
            } catch (Exception e) {
                MAIN.post(() -> cb.onAccess(error("NETWORK", e.getMessage())));
            }
        });
    }

    public static void requestPermissions(Activity activity) {
        if (!isConfigured()) return;
        new SimBridge(activity).ensurePermissions();
    }

    public static String getSimPhonesJson(Activity activity) {
        if (!isConfigured()) return "[]";
        return new SimBridge(activity).readSimsJson();
    }

    public static JSONArray getSimPhones(Activity activity) {
        try {
            return new JSONArray(getSimPhonesJson(activity));
        } catch (Exception e) {
            return new JSONArray();
        }
    }

    /** Validates access then opens verify WebView. */
    public static void openVerify(Activity activity, String sessionUrl, int requestCode) {
        openVerifyChecked(activity, sessionUrl, requestCode, null);
    }

    public static Intent verifyIntent(Activity activity, String sessionUrl) {
        return Niv2faVerifyActivity.intent(activity, sessionUrl);
    }

    /** Open verify only after access check; invokes callback with config/plan errors without opening UI. */
    public static void openVerifyChecked(Activity activity, String sessionUrl, int requestCode, ResultCallback onBlocked) {
        validateAccess(access -> {
            if (!access.optBoolean("ok", false)) {
                if (onBlocked != null) onBlocked.onResult(access);
                return;
            }
            activity.startActivityForResult(Niv2faVerifyActivity.intent(activity, sessionUrl), requestCode);
        });
    }

    public static JSONObject parseResult(Intent data) {
        try {
            if (data == null) return error("no_data", "No result");
            String json = data.getStringExtra(Niv2faVerifyActivity.EXTRA_RESULT_JSON);
            if (json == null || json.trim().isEmpty()) return error("empty", "Empty result");
            return new JSONObject(json);
        } catch (Exception e) {
            return error("parse", e.getMessage());
        }
    }

    private static JSONObject error(String code, String message) {
        try {
            JSONObject o = new JSONObject();
            o.put("matched", false);
            o.put("ok", false);
            o.put("status", "error");
            o.put("code", code);
            o.put("message", message == null ? "" : message);
            return o;
        } catch (Exception e) {
            return new JSONObject();
        }
    }
}
