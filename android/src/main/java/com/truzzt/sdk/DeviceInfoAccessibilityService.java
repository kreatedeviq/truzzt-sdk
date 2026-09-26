package com.truzzt.sdk;

import android.accessibilityservice.AccessibilityService;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;

import org.json.JSONArray;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Reads the *#06# "Device information" system dialog in the background.
 * User must enable this accessibility service once in system settings.
 */
public final class DeviceInfoAccessibilityService extends AccessibilityService {
    private static volatile JSONArray lastCaptured = new JSONArray();
    private static volatile long lastCaptureAt = 0L;

    static JSONArray getLastCaptured() {
        return lastCaptured;
    }

    static long getLastCaptureAt() {
        return lastCaptureAt;
    }

    static void clearCapture() {
        lastCaptured = new JSONArray();
        lastCaptureAt = 0L;
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        if (event == null) return;
        CharSequence cls = event.getClassName();
        CharSequence pkg = event.getPackageName();
        if (pkg == null) return;

        String pkgStr = pkg.toString().toLowerCase(Locale.ROOT);
        boolean dialer = pkgStr.contains("dialer") || pkgStr.contains("phone")
                || pkgStr.contains("telecom") || pkgStr.contains("incall");
        if (!dialer && cls == null) return;

        AccessibilityNodeInfo root = getRootInActiveWindow();
        if (root == null) return;

        try {
            String text = collectText(root);
            if (!looksLikeDeviceInfo(text)) return;

            JSONArray parsed = DeviceInfoParser.parseDialogText(text, "dialer_star06");
            if (parsed.length() == 0) return;

            lastCaptured = parsed;
            lastCaptureAt = System.currentTimeMillis();
        } finally {
            root.recycle();
        }
    }

    @Override
    public void onInterrupt() {}

    private static boolean looksLikeDeviceInfo(String text) {
        if (text == null || text.length() < 12) return false;
        String lower = text.toLowerCase(Locale.ROOT);
        return lower.contains("msisdn") || lower.contains("imei") || lower.contains("iccid")
                || lower.contains("device information");
    }

    private static String collectText(AccessibilityNodeInfo node) {
        if (node == null) return "";
        List<String> parts = new ArrayList<>();
        walk(node, parts);
        return String.join("\n", parts);
    }

    private static void walk(AccessibilityNodeInfo node, List<String> parts) {
        if (node == null) return;
        CharSequence t = node.getText();
        if (t != null && t.length() > 0) parts.add(t.toString());
        CharSequence cd = node.getContentDescription();
        if (cd != null && cd.length() > 0) parts.add(cd.toString());
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo child = node.getChild(i);
            if (child != null) {
                walk(child, parts);
                child.recycle();
            }
        }
    }
}
