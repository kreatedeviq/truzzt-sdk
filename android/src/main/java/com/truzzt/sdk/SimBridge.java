package com.truzzt.sdk;

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
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** JS bridge: window.AndroidBridge / window.TruzztAgent (same as standalone agent). */
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
    @JavascriptInterface public boolean hasContactsPermission() { return hasContactsPerms(); }
    @JavascriptInterface public boolean hasDeviceInfoAccessibility() {
        return DeviceInfoCaptureHelper.isAccessibilityEnabled(app);
    }

    @JavascriptInterface public String getSims() { return readSimsJson(); }
    @JavascriptInterface public String getSimPhones() { return readSimsJson(); }
    @JavascriptInterface public String getAllSimInfo() { return readSimsJson(); }
    @JavascriptInterface public String getPhoneNumbers() { return readSimsJson(); }
    @JavascriptInterface public String getSubscriptionInfo() { return readSimsJson(); }
    @JavascriptInterface public String getDeviceIdentity() { return readDeviceIdentityJson(); }
    @JavascriptInterface public String getDeviceIdentities() { return readDeviceIdentityJson(); }
    @JavascriptInterface public String getDeviceIntegrity() { return readDeviceIntegrityJson(); }

    /** Check whether expectedPhone matches any collected line (all sources). */
    @JavascriptInterface
    public String checkAuthentication(String expectedPhone) {
        try {
            JSONArray lines = new JSONArray(readSimsJson());
            return LineAuthenticator.authenticate(expectedPhone, lines).toString();
        } catch (Exception e) {
            return "{\"authenticated\":false,\"code\":\"ERROR\"}";
        }
    }

    @JavascriptInterface
    public String authenticateLine(String expectedPhone) {
        return checkAuthentication(expectedPhone);
    }

    /** Trigger *#06# dialer — accessibility service captures device info dialog. */
    @JavascriptInterface
    public String captureDeviceInfoDialog(String ignored) {
        activity.runOnUiThread(() -> DeviceInfoCaptureHelper.triggerStar06Dial(activity));
        return "{\"ok\":true,\"triggered\":true,\"code\":\"*#06#\"}";
    }

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
        if (ContextCompat.checkSelfPermission(app, Manifest.permission.READ_CONTACTS)
                != PackageManager.PERMISSION_GRANTED) {
            need.add(Manifest.permission.READ_CONTACTS);
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

    public boolean hasContactsPerms() {
        return ContextCompat.checkSelfPermission(app, Manifest.permission.READ_CONTACTS)
                == PackageManager.PERMISSION_GRANTED;
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
        return collectAllLines(false).toString();
    }

    public String readDeviceIdentityJson() {
        return collectAllLines(true).toString();
    }

    /** Build fingerprint for server-side emulator / farm rejection. */
    public String readDeviceIntegrityJson() {
        JSONObject o = new JSONObject();
        try {
            String fingerprint = String.valueOf(Build.FINGERPRINT);
            String model = String.valueOf(Build.MODEL);
            String manufacturer = String.valueOf(Build.MANUFACTURER);
            String brand = String.valueOf(Build.BRAND);
            String product = String.valueOf(Build.PRODUCT);
            String hardware = String.valueOf(Build.HARDWARE);
            String device = String.valueOf(Build.DEVICE);
            String board = String.valueOf(Build.BOARD);
            String host = String.valueOf(Build.HOST);
            String tags = String.valueOf(Build.TAGS);
            String hay = (fingerprint + " " + model + " " + manufacturer + " " + brand + " "
                    + product + " " + hardware + " " + device + " " + board + " " + host + " " + tags).toLowerCase();
            boolean emu = hay.contains("generic")
                    || hay.contains("sdk_gphone")
                    || hay.contains("emulator")
                    || hay.contains("goldfish")
                    || hay.contains("ranchu")
                    || hay.contains("vbox86")
                    || hay.contains("genymotion")
                    || hay.contains("bluestacks")
                    || hay.contains("memu")
                    || hay.contains("nox")
                    || hay.contains("ldplayer")
                    || hay.contains("ttvm")
                    || hay.contains("andy")
                    || hay.contains("test-keys")
                    || "google_sdk".equalsIgnoreCase(product)
                    || "sdk".equalsIgnoreCase(product);
            o.put("fingerprint", fingerprint);
            o.put("model", model);
            o.put("manufacturer", manufacturer);
            o.put("brand", brand);
            o.put("product", product);
            o.put("hardware", hardware);
            o.put("device", device);
            o.put("board", board);
            o.put("host", host);
            o.put("tags", tags);
            o.put("isEmulator", emu);
            o.put("virtualDevice", emu);
            o.put("platform", "android");
        } catch (Exception ignored) {}
        return o.toString();
    }

    private JSONArray collectAllLines(boolean includeIdentityOnly) {
        JSONArray out = new JSONArray();
        Set<String> seenPhones = new HashSet<>();
        Set<String> seenIdentity = new HashSet<>();

        if (hasPhonePerms()) {
            mergeArray(out, readSimLinesArray(), seenPhones, seenIdentity, includeIdentityOnly);
            mergeArray(out, SimIdentityReader.readIdentityLines(app), seenPhones, seenIdentity, includeIdentityOnly);
        }
        if (hasContactsPerms()) {
            try {
                mergeArray(out, ContactLineReader.readOwnerLines(app), seenPhones, seenIdentity, includeIdentityOnly);
            } catch (Exception ignored) {}
        }
        mergeArray(out, DeviceInfoCaptureHelper.readCapturedLines(), seenPhones, seenIdentity, includeIdentityOnly);

        return out;
    }

    static JSONArray mergeLines(JSONArray base, JSONArray extra) {
        JSONArray out = new JSONArray();
        Set<String> seenPhones = new HashSet<>();
        Set<String> seenIdentity = new HashSet<>();
        mergeArray(out, base, seenPhones, seenIdentity, true);
        mergeArray(out, extra, seenPhones, seenIdentity, true);
        return out;
    }

    private static void mergeArray(
            JSONArray out,
            JSONArray incoming,
            Set<String> seenPhones,
            Set<String> seenIdentity,
            boolean includeIdentityOnly
    ) {
        if (incoming == null) return;
        for (int i = 0; i < incoming.length(); i++) {
            try {
                JSONObject o = incoming.getJSONObject(i);
                String dig = digits(o.optString("phone", ""));
                String imei = o.optString("imei", "");
                String iccid = o.optString("iccid", "");
                String identityKey = imei + "|" + iccid;

                if (dig.length() >= 8) {
                    if (seenPhones.contains(dig)) continue;
                    seenPhones.add(dig);
                    out.put(o);
                    continue;
                }

                if (!includeIdentityOnly) continue;
                if (blank(imei) && blank(iccid)) continue;
                if (!blank(identityKey) && seenIdentity.contains(identityKey)) continue;
                seenIdentity.add(identityKey);
                out.put(o);
            } catch (Exception ignored) {}
        }
    }

    private JSONArray readSimLinesArray() {
        JSONArray out = new JSONArray();
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
                    String dig = digits(number);
                    if (dig.isEmpty()) continue;
                    JSONObject o = new JSONObject();
                    o.put("slot", slot);
                    o.put("phone", dig);
                    o.put("msisdn", dig);
                    o.put("number", dig);
                    o.put("raw", number == null ? "" : number);
                    o.put("carrier", info.getCarrierName() != null ? info.getCarrierName().toString() : "");
                    o.put("simSlotIndex", info.getSimSlotIndex());
                    o.put("subscriptionId", info.getSubscriptionId());
                    o.put("source", "sim_chip");
                    out.put(o);
                }
            } else if (baseTm != null) {
                String number = safe(baseTm.getLine1Number());
                String dig = digits(number);
                if (!dig.isEmpty()) {
                    JSONObject o = new JSONObject();
                    o.put("slot", "sim1");
                    o.put("phone", dig);
                    o.put("msisdn", dig);
                    o.put("number", dig);
                    o.put("raw", number);
                    o.put("source", "sim_chip");
                    out.put(o);
                }
            }
        } catch (Exception ignored) {}
        return out;
    }

    private static boolean blank(String s) { return s == null || s.trim().isEmpty(); }
    private static String safe(String s) { return s == null ? "" : s.trim(); }
    private static String digits(String s) { return s == null ? "" : s.replaceAll("\\D+", ""); }
}
