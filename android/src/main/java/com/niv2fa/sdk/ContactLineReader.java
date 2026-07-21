package com.niv2fa.sdk;

import android.content.Context;
import android.database.Cursor;
import android.provider.ContactsContract;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.HashSet;
import java.util.Locale;
import java.util.Set;

/** Reads phone lines the user saved as their own number in Contacts (e.g. "رقمي", "my number"). */
final class ContactLineReader {
    private static final String[] OWNER_NAME_PATTERNS = {
            "رقمي",
            "my number",
            "my line",
            "my phone",
            "own number",
            "my mobile",
            "my sim",
            "self number",
            "رقم الهاتف",
            "my asia",
            "my line 1",
            "my line 2"
    };

    private ContactLineReader() {}

    static JSONArray readOwnerLines(Context ctx) {
        JSONArray out = new JSONArray();
        if (ctx == null) return out;

        Set<String> seen = new HashSet<>();
        int savedIndex = 0;

        String[] projection = {
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                ContactsContract.CommonDataKinds.Phone.NUMBER,
                ContactsContract.CommonDataKinds.Phone.NORMALIZED_NUMBER
        };

        try (Cursor c = ctx.getContentResolver().query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                projection,
                null,
                null,
                null)) {
            if (c == null) return out;
            int nameIdx = c.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME);
            int numIdx = c.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER);
            int normIdx = c.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NORMALIZED_NUMBER);

            while (c.moveToNext()) {
                String name = nameIdx >= 0 ? safe(c.getString(nameIdx)) : "";
                String pattern = matchesOwnerLabel(name);
                if (pattern == null) continue;

                String raw = numIdx >= 0 ? safe(c.getString(numIdx)) : "";
                if (blank(raw) && normIdx >= 0) raw = safe(c.getString(normIdx));
                String dig = digits(raw);
                if (dig.length() < 8 || seen.contains(dig)) continue;
                seen.add(dig);

                savedIndex++;
                JSONObject o = new JSONObject();
                o.put("slot", "contact_" + savedIndex);
                o.put("phone", dig);
                o.put("msisdn", dig);
                o.put("number", dig);
                o.put("raw", raw);
                o.put("source", "contacts_saved:" + pattern);
                o.put("contactName", name);
                out.put(o);
            }
        } catch (Exception ignored) {}

        return out;
    }

    private static String matchesOwnerLabel(String name) {
        if (blank(name)) return null;
        String lower = name.toLowerCase(Locale.ROOT);
        for (String pattern : OWNER_NAME_PATTERNS) {
            if (lower.contains(pattern.toLowerCase(Locale.ROOT))) return pattern;
        }
        return null;
    }

    private static boolean blank(String s) { return s == null || s.trim().isEmpty(); }
    private static String safe(String s) { return s == null ? "" : s.trim(); }
    private static String digits(String s) { return s == null ? "" : s.replaceAll("\\D+", ""); }
}
