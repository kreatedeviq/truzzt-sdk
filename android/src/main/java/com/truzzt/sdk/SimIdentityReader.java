package com.truzzt.sdk;

import android.content.Context;
import android.os.Build;
import android.telephony.SubscriptionInfo;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.List;

/**
 * Reads SIM identity fields exposed by Android APIs (same data as *#06# / SIM settings):
 * MSISDN, IMEI, ICCID per active subscription slot.
 */
final class SimIdentityReader {
    private SimIdentityReader() {}

    static JSONArray readIdentityLines(Context ctx) {
        JSONArray out = new JSONArray();
        if (ctx == null) return out;

        try {
            SubscriptionManager sm = (SubscriptionManager)
                    ctx.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE);
            TelephonyManager baseTm = (TelephonyManager)
                    ctx.getSystemService(Context.TELEPHONY_SERVICE);
            if (sm == null || baseTm == null) return out;

            List<SubscriptionInfo> subs;
            try {
                subs = sm.getActiveSubscriptionInfoList();
            } catch (SecurityException e) {
                return out;
            }
            if (subs == null || subs.isEmpty()) return out;

            int index = 0;
            for (SubscriptionInfo info : subs) {
                index++;
                String slot = index == 1 ? "sim1" : (index == 2 ? "sim2" : ("sim" + index));
                int subId = info.getSubscriptionId();
                TelephonyManager slotTm = baseTm.createForSubscriptionId(subId);

                String msisdn = readMsisdn(sm, slotTm, info);
                String imei = readImei(baseTm, slotTm, info.getSimSlotIndex());
                String iccid = readIccid(info, slotTm);

                if (blank(msisdn) && blank(imei) && blank(iccid)) continue;

                JSONObject o = new JSONObject();
                o.put("slot", slot);
                o.put("simSlotIndex", info.getSimSlotIndex());
                o.put("subscriptionId", subId);
                o.put("source", "device_info_api");
                o.put("carrier", info.getCarrierName() != null ? info.getCarrierName().toString() : "");

                if (!blank(msisdn)) {
                    String dig = digits(msisdn);
                    o.put("phone", dig);
                    o.put("msisdn", dig);
                    o.put("number", dig);
                    o.put("raw", msisdn);
                }
                if (!blank(imei)) o.put("imei", digits(imei));
                if (!blank(iccid)) o.put("iccid", digits(iccid));

                // Secondary row tagged as sim_settings when number comes from SubscriptionInfo
                if (!blank(msisdn)) {
                    try {
                        String settingsNum = safe(info.getNumber());
                        if (!blank(settingsNum) && !settingsNum.equals(msisdn)) {
                            JSONObject settings = new JSONObject(o.toString());
                            settings.put("source", "sim_settings");
                            settings.put("phone", digits(settingsNum));
                            settings.put("msisdn", digits(settingsNum));
                            settings.put("number", digits(settingsNum));
                            settings.put("raw", settingsNum);
                            out.put(settings);
                        }
                    } catch (Exception ignored) {}
                }

                out.put(o);
            }
        } catch (Exception ignored) {}

        return out;
    }

    private static String readMsisdn(SubscriptionManager sm, TelephonyManager slotTm, SubscriptionInfo info) {
        String number = "";
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                number = safe(sm.getPhoneNumber(info.getSubscriptionId()));
            }
        } catch (Exception ignored) {}
        if (blank(number) && slotTm != null) {
            try { number = safe(slotTm.getLine1Number()); } catch (Exception ignored) {}
        }
        if (blank(number)) {
            try { number = safe(info.getNumber()); } catch (Exception ignored) {}
        }
        return number;
    }

    private static String readImei(TelephonyManager baseTm, TelephonyManager slotTm, int simSlotIndex) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && slotTm != null) {
                String imei = safe(slotTm.getImei());
                if (!blank(imei)) return imei;
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && baseTm != null) {
                return safe(baseTm.getImei(simSlotIndex));
            }
            if (slotTm != null) return safe(slotTm.getDeviceId());
        } catch (SecurityException ignored) {}
        return "";
    }

    private static String readIccid(SubscriptionInfo info, TelephonyManager slotTm) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                String iccid = safe(info.getIccId());
                if (!blank(iccid)) return iccid;
            }
        } catch (Exception ignored) {}
        if (slotTm != null) {
            try { return safe(slotTm.getSimSerialNumber()); } catch (Exception ignored) {}
        }
        return "";
    }

    private static boolean blank(String s) { return s == null || s.trim().isEmpty(); }
    private static String safe(String s) { return s == null ? "" : s.trim(); }
    private static String digits(String s) { return s == null ? "" : s.replaceAll("\\D+", ""); }
}
