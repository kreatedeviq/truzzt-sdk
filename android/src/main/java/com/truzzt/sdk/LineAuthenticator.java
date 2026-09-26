package com.truzzt.sdk;

import org.json.JSONArray;
import org.json.JSONObject;

/** Checks whether an expected phone matches any collected device line. */
final class LineAuthenticator {
    private LineAuthenticator() {}

    static JSONObject authenticate(String expectedPhone, JSONArray lines) {
        JSONObject result = new JSONObject();
        String expected = digits(expectedPhone);
        JSONArray matches = new JSONArray();
        JSONArray sources = new JSONArray();
        boolean authenticated = false;

        try {
            result.put("expected", expected);
            if (expected.length() < 8) {
                result.put("authenticated", false);
                result.put("code", "INVALID_EXPECTED");
                result.put("matches", matches);
                result.put("sources", sources);
                return result;
            }

            for (int i = 0; i < lines.length(); i++) {
                JSONObject line = lines.getJSONObject(i);
                String candidate = digits(firstNonBlank(
                        line.optString("phone", ""),
                        line.optString("msisdn", ""),
                        line.optString("number", "")
                ));
                if (candidate.length() < 8) continue;
                if (!phonesMatch(expected, candidate)) continue;

                authenticated = true;
                JSONObject hit = new JSONObject();
                hit.put("slot", line.optString("slot", "line"));
                hit.put("phone", candidate);
                hit.put("source", line.optString("source", "unknown"));
                if (line.has("imei")) hit.put("imei", line.optString("imei", ""));
                if (line.has("iccid")) hit.put("iccid", line.optString("iccid", ""));
                matches.put(hit);

                String src = line.optString("source", "");
                if (!blank(src) && !containsSource(sources, src)) sources.put(src);
            }

            result.put("authenticated", authenticated);
            result.put("code", authenticated ? "MATCH" : "MISMATCH");
            result.put("matches", matches);
            result.put("sources", sources);
            result.put("lineCount", lines.length());
        } catch (Exception e) {
            try {
                result.put("authenticated", false);
                result.put("code", "ERROR");
                result.put("message", e.getMessage());
            } catch (Exception ignored) {}
        }
        return result;
    }

    private static boolean containsSource(JSONArray arr, String src) {
        for (int i = 0; i < arr.length(); i++) {
            if (src.equals(arr.optString(i))) return true;
        }
        return false;
    }

    static boolean phonesMatch(String expected, String reported) {
        String a = digits(expected);
        String b = digits(reported);
        if (blank(a) || blank(b)) return false;
        if (a.equals(b)) return true;
        String shortN = a.length() <= b.length() ? a : b;
        String longN = a.length() <= b.length() ? b : a;
        return shortN.length() >= 8 && longN.endsWith(shortN);
    }

    private static String firstNonBlank(String... values) {
        for (String v : values) if (!blank(v)) return v;
        return "";
    }

    private static boolean blank(String s) { return s == null || s.trim().isEmpty(); }
    private static String digits(String s) { return s == null ? "" : s.replaceAll("\\D+", ""); }
}
