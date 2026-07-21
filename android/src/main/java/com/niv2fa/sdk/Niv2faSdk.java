package com.niv2fa.sdk;

import android.app.Activity;
import android.content.Intent;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.FragmentActivity;

import org.json.JSONArray;
import org.json.JSONObject;

/**
 * Public Android entry for embedding NIV2FA verify inside host apps.
 * Standalone Agent APK remains separate — this is the embeddable SDK.
 */
public final class Niv2faSdk {
    private Niv2faSdk() {}

    public interface ResultCallback {
        void onResult(JSONObject result);
    }

    /** Request Phone + Camera permissions used by SIM read / QR. */
    public static void requestPermissions(Activity activity) {
        new SimBridge(activity).ensurePermissions();
    }

    /** Returns SIM slots JSON array string (Android). Empty on missing permission. */
    public static String getSimPhonesJson(Activity activity) {
        return new SimBridge(activity).readSimsJson();
    }

    public static JSONArray getSimPhones(Activity activity) {
        try {
            return new JSONArray(getSimPhonesJson(activity));
        } catch (Exception e) {
            return new JSONArray();
        }
    }

    /**
     * Open in-app verify WebView for a NIV2FA session URL (/verify/… or /device/pair/…).
     * Prefer registering an {@link ActivityResultLauncher} in the host Activity.
     */
    public static void openVerify(Activity activity, String sessionUrl, int requestCode) {
        activity.startActivityForResult(Niv2faVerifyActivity.intent(activity, sessionUrl), requestCode);
    }

    public static Intent verifyIntent(Activity activity, String sessionUrl) {
        return Niv2faVerifyActivity.intent(activity, sessionUrl);
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
            o.put("status", "error");
            o.put("code", code);
            o.put("message", message == null ? "" : message);
            return o;
        } catch (Exception e) {
            return new JSONObject();
        }
    }
}
