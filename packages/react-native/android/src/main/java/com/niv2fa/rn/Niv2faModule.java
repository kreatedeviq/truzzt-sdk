package com.niv2fa.rn;

import android.app.Activity;
import android.content.Intent;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.niv2fa.sdk.Niv2faSdk;
import com.niv2fa.sdk.Niv2faVerifyActivity;

import org.json.JSONArray;
import org.json.JSONObject;

public class Niv2faModule extends ReactContextBaseJavaModule {
    private static final int REQ = 7724;
    private Promise pending;

    private final ActivityEventListener listener = new BaseActivityEventListener() {
        @Override
        public void onActivityResult(Activity activity, int requestCode, int resultCode, @Nullable Intent data) {
            if (requestCode != REQ || pending == null) return;
            JSONObject parsed = Niv2faSdk.parseResult(data);
            pending.resolve(jsonToMap(parsed));
            pending = null;
        }
    };

    public Niv2faModule(ReactApplicationContext ctx) {
        super(ctx);
        ctx.addActivityEventListener(listener);
    }

    @NonNull
    @Override
    public String getName() {
        return "Niv2fa";
    }

    @ReactMethod
    public void requestPermissions(Promise promise) {
        Activity a = getCurrentActivity();
        if (a != null) Niv2faSdk.requestPermissions(a);
        WritableMap m = Arguments.createMap();
        m.putBoolean("requested", true);
        promise.resolve(m);
    }

    @ReactMethod
    public void getSimPhones(Promise promise) {
        try {
            Activity a = getCurrentActivity();
            JSONArray arr = a != null ? Niv2faSdk.getSimPhones(a) : new JSONArray();
            WritableMap ret = Arguments.createMap();
            WritableArray sims = Arguments.createArray();
            for (int i = 0; i < arr.length(); i++) {
                JSONObject o = arr.getJSONObject(i);
                WritableMap m = Arguments.createMap();
                m.putString("slot", o.optString("slot"));
                m.putString("phone", o.optString("phone"));
                sims.pushMap(m);
            }
            ret.putArray("sims", sims);
            ret.putString("platform", "android");
            promise.resolve(ret);
        } catch (Exception e) {
            promise.reject("sims", e);
        }
    }

    @ReactMethod
    public void openVerify(ReadableMap opts, Promise promise) {
        String url = opts.hasKey("url") ? opts.getString("url") : opts.getString("sessionUrl");
        Activity a = getCurrentActivity();
        if (a == null || url == null || url.trim().isEmpty()) {
            promise.reject("missing_url", "url/activity required");
            return;
        }
        pending = promise;
        a.startActivityForResult(Niv2faSdk.verifyIntent(a, url.trim()), REQ);
    }

    private WritableMap jsonToMap(JSONObject o) {
        WritableMap m = Arguments.createMap();
        m.putBoolean("matched", o.optBoolean("matched", false));
        m.putString("status", o.optString("status", ""));
        if (o.has("matchedSlot")) m.putString("matchedSlot", o.optString("matchedSlot"));
        if (o.has("sessionId")) m.putString("sessionId", o.optString("sessionId"));
        if (o.has("code")) m.putString("code", o.optString("code"));
        if (o.has("message")) m.putString("message", o.optString("message"));
        m.putString("platform", "android");
        return m;
    }
}
