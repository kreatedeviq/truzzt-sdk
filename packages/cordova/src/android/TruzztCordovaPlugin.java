package com.truzzt.cordova;

import android.app.Activity;
import android.content.Intent;

import com.truzzt.sdk.TruzztSdk;
import com.truzzt.sdk.TruzztVerifyActivity;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class TruzztCordovaPlugin extends CordovaPlugin {
    private static final int REQ = 7721;
    private CallbackContext pending;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if ("requestPermissions".equals(action)) {
            TruzztSdk.requestPermissions(cordova.getActivity());
            JSONObject o = new JSONObject();
            o.put("requested", true);
            callbackContext.success(o);
            return true;
        }
        if ("getSimPhones".equals(action)) {
            JSONObject o = new JSONObject();
            o.put("sims", TruzztSdk.getSimPhones(cordova.getActivity()));
            o.put("platform", "android");
            callbackContext.success(o);
            return true;
        }
        if ("openVerify".equals(action)) {
            JSONObject opts = args.optJSONObject(0);
            String url = opts != null ? opts.optString("url", opts.optString("sessionUrl", "")) : "";
            if (url.isEmpty()) {
                callbackContext.error("url is required");
                return true;
            }
            pending = callbackContext;
            cordova.setActivityResultCallback(this);
            cordova.startActivityForResult(this, TruzztSdk.verifyIntent(cordova.getActivity(), url), REQ);
            return true;
        }
        return false;
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent intent) {
        if (requestCode != REQ || pending == null) return;
        JSONObject parsed = TruzztSdk.parseResult(intent);
        if (resultCode == Activity.RESULT_OK && parsed.optBoolean("matched")) {
            pending.success(parsed);
        } else if (parsed.optBoolean("matched")) {
            pending.success(parsed);
        } else {
            pending.success(parsed);
        }
        pending = null;
    }
}
