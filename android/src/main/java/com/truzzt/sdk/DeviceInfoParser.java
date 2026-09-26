package com.truzzt.sdk;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Parses *#06# "Device information" dialog text (accessibility or OCR). */
final class DeviceInfoParser {
    private static final Pattern MSISDN = Pattern.compile(
            "MSISDN\\s*\\(.*?sim\\s*slot\\s*(\\d+).*?\\)\\s*:?\\s*([+\\d\\s-]+)",
            Pattern.CASE_INSENSITIVE);
    private static final Pattern IMEI = Pattern.compile(
            "IMEI\\s*\\(.*?sim\\s*slot\\s*(\\d+).*?\\)\\s*:?\\s*([\\d\\s/]+)",
            Pattern.CASE_INSENSITIVE);
    private static final Pattern ICCID = Pattern.compile(
            "ICCID\\s*\\(.*?sim\\s*slot\\s*(\\d+).*?\\)\\s*:?\\s*([\\d]+)",
            Pattern.CASE_INSENSITIVE);
    private static final Pattern LOOSE_PHONE = Pattern.compile("(\\+?964\\d{8,12}|\\+?\\d{10,15})");

    private DeviceInfoParser() {}

    static JSONArray parseDialogText(String text, String sourceTag) {
        JSONArray out = new JSONArray();
        if (blank(text)) return out;

        try {
            String normalized = text.replace('\u00a0', ' ').trim();
            java.util.Map<Integer, JSONObject> bySlot = new java.util.HashMap<>();

            applyPattern(bySlot, normalized, MSISDN, "msisdn", sourceTag);
            applyPattern(bySlot, normalized, IMEI, "imei", sourceTag);
            applyPattern(bySlot, normalized, ICCID, "iccid", sourceTag);

            if (bySlot.isEmpty()) {
                Matcher m = LOOSE_PHONE.matcher(normalized);
                int i = 0;
                while (m.find()) {
                    i++;
                    String raw = m.group(1);
                    String dig = digits(raw);
                    if (dig.length() < 10) continue;
                    JSONObject o = slotObject(i == 1 ? 1 : i, sourceTag);
                    o.put("phone", dig);
                    o.put("msisdn", dig);
                    o.put("number", dig);
                    o.put("raw", raw);
                    out.put(o);
                }
                return out;
            }

            for (java.util.Map.Entry<Integer, JSONObject> e : bySlot.entrySet()) {
                out.put(e.getValue());
            }
        } catch (Exception ignored) {}

        return out;
    }

    private static void applyPattern(
            java.util.Map<Integer, JSONObject> bySlot,
            String text,
            Pattern pattern,
            String field,
            String sourceTag
    ) throws org.json.JSONException {
        Matcher m = pattern.matcher(text);
        while (m.find()) {
            int slotNum = parseIntSafe(m.group(1), 1);
            String value = safe(m.group(2));
            if (blank(value)) continue;
            JSONObject o = bySlot.get(slotNum);
            if (o == null) {
                o = slotObject(slotNum, sourceTag);
                bySlot.put(slotNum, o);
            }
            if ("msisdn".equals(field)) {
                String dig = digits(value);
                if (dig.length() >= 8) {
                    o.put("phone", dig);
                    o.put("msisdn", dig);
                    o.put("number", dig);
                    o.put("raw", value.trim());
                }
            } else {
                o.put(field, digits(value));
            }
        }
    }

    private static JSONObject slotObject(int slotNum, String sourceTag) throws org.json.JSONException {
        String slot = slotNum == 1 ? "sim1" : (slotNum == 2 ? "sim2" : ("sim" + slotNum));
        JSONObject o = new JSONObject();
        o.put("slot", slot);
        o.put("simSlotIndex", slotNum - 1);
        o.put("source", sourceTag);
        return o;
    }

    private static int parseIntSafe(String s, int fallback) {
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return fallback; }
    }

    private static boolean blank(String s) { return s == null || s.trim().isEmpty(); }
    private static String safe(String s) { return s == null ? "" : s.trim(); }
    private static String digits(String s) { return s == null ? "" : s.replaceAll("\\D+", ""); }
}
