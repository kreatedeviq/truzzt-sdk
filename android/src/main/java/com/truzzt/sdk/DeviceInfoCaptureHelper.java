package com.truzzt.sdk;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.provider.Settings;

import org.json.JSONArray;

/**
 * Triggers *#06# device-info dialog and relies on {@link DeviceInfoAccessibilityService}
 * to capture MSISDN / IMEI / ICCID text (same fields as SIM settings).
 */
public final class DeviceInfoCaptureHelper {
    public static final String STAR_06_CODE = "*#06#";

    private DeviceInfoCaptureHelper() {}

    static boolean isAccessibilityEnabled(Context ctx) {
        if (ctx == null) return false;
        try {
            String enabled = Settings.Secure.getString(
                    ctx.getContentResolver(),
                    Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            );
            if (enabled == null) return false;
            ComponentName cn = new ComponentName(ctx, DeviceInfoAccessibilityService.class);
            String flat = cn.flattenToString();
            String shortFlat = cn.flattenToShortString();
            return enabled.contains(flat) || enabled.contains(shortFlat);
        } catch (Exception e) {
            return false;
        }
    }

    static Intent accessibilitySettingsIntent(Context ctx) {
        Intent intent = new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        return intent;
    }

    /** Fire *#06# dial intent — may show system device-info on supported OEMs. */
    static void triggerStar06Dial(Activity activity) {
        if (activity == null) return;
        try {
            Intent dial = new Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + Uri.encode(STAR_06_CODE)));
            dial.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            activity.startActivity(dial);
        } catch (Exception ignored) {}
    }

    static JSONArray readCapturedLines() {
        JSONArray captured = DeviceInfoAccessibilityService.getLastCaptured();
        if (captured == null || captured.length() == 0) return new JSONArray();

        // Re-parse if stale capture older than 2 minutes
        long age = System.currentTimeMillis() - DeviceInfoAccessibilityService.getLastCaptureAt();
        if (age > 120_000L) return new JSONArray();
        return captured;
    }

    static JSONArray mergeCaptured(JSONArray base) {
        JSONArray captured = readCapturedLines();
        if (captured.length() == 0) return base;
        return SimBridge.mergeLines(base, captured);
    }
}
