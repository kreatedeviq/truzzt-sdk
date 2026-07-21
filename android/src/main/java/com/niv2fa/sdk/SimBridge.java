package com.niv2fa.sdk;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.telephony.SubscriptionInfo;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;
import android.webkit.JavascriptInterface;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

/** JS bridge: window.AndroidBridge / window.Niv2faAgent (same as standalone agent). */
public final class SimBridge {
    public static final int REQ_PERMS = 7722;

    private final Activity activity;
    private final Context app;

    public SimBridge(Activity activity) {
        this.activity = activity;
        this.app = activity.getApplicationContext();
    }

    @JavascriptInterface
    public String requestPermissions(String ignored) {
        activity.runOnUiThread(this::ensurePermissions);
        return "{\"ok\":true,\"requested\":true}";
    }

    @JavascriptInterface public String requestPhonePermissions(String i) { return requestPermissions(i); }
    @JavascriptInterface public String requestSimPermissions(String i) { return requestPermissions(i); }
    @JavascriptInterface public String ensurePermissions(String i) { return requestPermissions(i); }
    @JavascriptInterface public String askPermissions(String i) { return requestPermissions(i); }

    @JavascriptInterface public boolean hasPhonePermission() { return hasPhonePerms(); }
    @JavascriptInterface public String getSims() { return readSimsJson(); }
    @JavascriptInterface public String getSimPhones() { return readSimsJson(); }
    @JavascriptInterface public String getAllSimInfo() { return readSimsJson(); }
    @JavascriptInterface public String getPhoneNumbers() { return readSimsJson(); }
    @JavascriptInterface public String getSubscriptionInfo() { return readSimsJson(); }
    @JavascriptInterface public String getSim1() { return slotPhone("sim1"); }
    @JavascriptInterface public String getSim1Phone() { return getSim1(); }
    @JavascriptInterface public String getLine1Number() { return getSim1(); }
    @JavascriptInterface public String getPhoneNumber() { return getSim1(); }
    @JavascriptInterface public String getMsisdn() { return getSim1(); }
    @JavascriptInterface public String getSim2() { return slotPhone("sim2"); }
    @JavascriptInterface public String getSim2Phone() { return getSim2(); }
    @JavascriptInterface public String getLine2Number() { return getSim2(); }

    public void ensurePermissions() {
        List<String> need = new ArrayList<>();
        if (ContextCompat.checkSelfPermission(app, Manifest.permission.READ_PHONE_STATE)
                != PackageManager.PERMISSION_GRANTED) {
            need.add(Manifest.permission.READ_PHONE_STATE);
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                && ContextCompat.checkSelfPermission(app, Manifest.permission.READ_PHONE_NUMBERS)
                != PackageManager.PERMISSION_GRANTED) {
            need.add(Manifest.permission.READ_PHONE_NUMBERS);
        }
        if (ContextCompat.checkSelfPermission(app, Manifest.permission.CAMERA)
                != PackageManager.PERMISSION_GRANTED) {
            need.add(Manifest.permission.CAMERA);
        }
        if (!need.isEmpty()) {
            ActivityCompat.requestPermissions(activity, need.toArray(new String[0]), REQ_PERMS);
        }
    }

    public boolean hasPhonePerms() {
        boolean state = ContextCompat.checkSelfPermission(app, Manifest.permission.READ_PHONE_STATE)
                == PackageManager.PERMISSION_GRANTED;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            return state && ContextCompat.checkSelfPermission(app, Manifest.permission.READ_PHONE_NUMBERS)
                    == PackageManager.PERMISSION_GRANTED;
        }
        return state;
    }

    private String slotPhone(String slot) {
        try {
            JSONArray arr = new JSONArray(readSimsJson());
            for (int i = 0; i < arr.length(); i++) {
                JSONObject o = arr.getJSONObject(i);
                if (slot.equalsIgnoreCase(o.optString("slot"))) return o.optString("phone", "");
            }
            if ("sim1".equals(slot) && arr.length() > 0) return arr.getJSONObject(0).optString("phone", "");
            if ("sim2".equals(slot) && arr.length() > 1) return arr.getJSONObject(1).optString("phone", "");
        } catch (Exception ignored) {}
        return "";
    }

    public String readSimsJson() {
        JSONArray out = new JSONArray();
        if (!hasPhonePerms()) return out.toString();
        try {
            SubscriptionManager sm = (SubscriptionManager) app.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE);
            TelephonyManager baseTm = (TelephonyManager) app.getSystemService(Context.TELEPHONY_SERVICE);
            List<SubscriptionInfo> subs = null;
            if (sm != null) {
                try { subs = sm.getActiveSubscriptionInfoList(); } catch (SecurityException ignored) {}
            }
            if (subs != null && !subs.isEmpty()) {
                int index = 0;
                for (SubscriptionInfo info : subs) {
                    index++;
                    String slot = index == 1 ? "sim1" : (index == 2 ? "sim2" : ("sim" + index));
                    String number = "";
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            number = safe(sm.getPhoneNumber(info.getSubscriptionId()));
                        }
                    } catch (Exception ignored) {}
                    if (blank(number) && baseTm != null) {
                        try {
                            number = safe(baseTm.createForSubscriptionId(info.getSubscriptionId()).getLine1Number());
                        } catch (Exception ignored) {}
                    }
                    if (blank(number)) {
                        try { number = safe(info.getNumber()); } catch (Exception ignored) {}
                    }
                    JSONObject o = new JSONObject();
                    o.put("slot", slot);
                    o.put("phone", digits(number));
                    o.put("msisdn", digits(number));
                    o.put("number", digits(number));
                    o.put("raw", number == null ? "" : number);
                    o.put("carrier", info.getCarrierName() != null ? info.getCarrierName().toString() : "");
                    o.put("simSlotIndex", info.getSimSlotIndex());
                    o.put("subscriptionId", info.getSubscriptionId());
                    out.put(o);
                }
            } else if (baseTm != null) {
                String number = safe(baseTm.getLine1Number());
                JSONObject o = new JSONObject();
                o.put("slot", "sim1");
                o.put("phone", digits(number));
                o.put("msisdn", digits(number));
                o.put("number", digits(number));
                o.put("raw", number);
                out.put(o);
            }
        } catch (Exception ignored) {}
        return out.toString();
    }

    private static boolean blank(String s) { return s == null || s.trim().isEmpty(); }
    private static String safe(String s) { return s == null ? "" : s.trim(); }
    private static String digits(String s) { return s == null ? "" : s.replaceAll("\\D+", ""); }
}
