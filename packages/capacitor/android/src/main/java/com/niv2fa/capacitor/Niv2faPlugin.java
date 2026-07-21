package com.niv2fa.capacitor;

import android.app.Activity;
import android.content.Intent;

import androidx.activity.result.ActivityResult;
import androidx.appcompat.app.AppCompatActivity;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.niv2fa.sdk.Niv2faSdk;
import com.niv2fa.sdk.Niv2faVerifyActivity;

import org.json.JSONArray;
import org.json.JSONObject;

@CapacitorPlugin(name = "Niv2fa")
public class Niv2faPlugin extends Plugin {

    @PluginMethod
    public void requestPermissions(PluginCall call) {
        Activity a = getActivity();
        if (a != null) Niv2faSdk.requestPermissions(a);
        JSObject ret = new JSObject();
        ret.put("requested", true);
        call.resolve(ret);
    }

    @PluginMethod
    public void getSimPhones(PluginCall call) {
        Activity a = getActivity();
        JSObject ret = new JSObject();
        try {
            JSONArray arr = a != null ? Niv2faSdk.getSimPhones(a) : new JSONArray();
            ret.put("sims", new JSArray(arr.toString()));
            ret.put("platform", "android");
            call.resolve(ret);
        } catch (Exception e) {
            call.reject(e.getMessage());
        }
    }

    @PluginMethod
    public void openVerify(PluginCall call) {
        String url = call.getString("url");
        if (url == null || url.trim().isEmpty()) {
            url = call.getString("sessionUrl");
        }
        if (url == null || url.trim().isEmpty()) {
            call.reject("url is required");
            return;
        }
        Intent intent = Niv2faSdk.verifyIntent(getActivity(), url.trim());
        startActivityForResult(call, intent, "verifyResult");
    }

    @ActivityCallback
    private void verifyResult(PluginCall call, ActivityResult result) {
        if (call == null) return;
        JSONObject parsed = Niv2faSdk.parseResult(result.getData());
        JSObject ret = new JSObject();
        ret.put("matched", parsed.optBoolean("matched", false));
        ret.put("status", parsed.optString("status", ""));
        ret.put("matchedSlot", parsed.optString("matchedSlot", null));
        ret.put("sessionId", parsed.optString("sessionId", null));
        ret.put("code", parsed.optString("code", null));
        ret.put("message", parsed.optString("message", null));
        ret.put("platform", "android");
        call.resolve(ret);
    }
}
