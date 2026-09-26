package com.truzzt.flutter;

import android.app.Activity;
import android.content.Intent;

import androidx.annotation.NonNull;

import com.truzzt.sdk.TruzztSdk;
import com.truzzt.sdk.TruzztVerifyActivity;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

public class TruzztFlutterPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private static final int REQ = 7723;
    private MethodChannel channel;
    private Activity activity;
    private MethodChannel.Result pending;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "truzzt");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (activity == null) {
            result.error("no_activity", "Activity not ready", null);
            return;
        }
        switch (call.method) {
            case "configure": {
                String key = call.argument("apiKey");
                String proj = call.argument("projectId");
                String base = call.argument("baseUrl");
                JSONObject theme = null;
                Object themeArg = call.argument("theme");
                if (themeArg instanceof Map) {
                    theme = new JSONObject((Map<?, ?>) themeArg);
                }
                TruzztSdk.configure(key, proj, base, theme);
                Map<String, Object> cfg = new HashMap<>();
                cfg.put("ok", TruzztSdk.isConfigured());
                result.success(cfg);
                break;
            }
            case "requestPermissions":
                TruzztSdk.requestPermissions(activity);
                Map<String, Object> ok = new HashMap<>();
                ok.put("requested", true);
                result.success(ok);
                break;
            case "getSimPhones":
                try {
                    Map<String, Object> ret = new HashMap<>();
                    ArrayList<Object> sims = new ArrayList<>();
                    org.json.JSONArray arr = TruzztSdk.getSimPhones(activity);
                    for (int i = 0; i < arr.length(); i++) {
                        JSONObject o = arr.getJSONObject(i);
                        Map<String, Object> m = new HashMap<>();
                        m.put("slot", o.optString("slot"));
                        m.put("phone", o.optString("phone"));
                        sims.add(m);
                    }
                    ret.put("sims", sims);
                    ret.put("platform", "android");
                    result.success(ret);
                } catch (Exception e) {
                    result.error("sims", e.getMessage(), null);
                }
                break;
            case "openVerify":
                String url = call.argument("url");
                if (url == null || url.trim().isEmpty()) {
                    result.error("missing_url", "url is required", null);
                    return;
                }
                pending = result;
                activity.startActivityForResult(TruzztSdk.verifyIntent(activity, url.trim()), REQ);
                break;
            default:
                result.notImplemented();
        }
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode != REQ || pending == null) return false;
        JSONObject parsed = TruzztSdk.parseResult(data);
        Map<String, Object> map = new HashMap<>();
        map.put("matched", parsed.optBoolean("matched", false));
        map.put("status", parsed.optString("status", ""));
        map.put("matchedSlot", parsed.optString("matchedSlot", null));
        map.put("sessionId", parsed.optString("sessionId", null));
        map.put("code", parsed.optString("code", null));
        map.put("message", parsed.optString("message", null));
        map.put("platform", "android");
        pending.success(map);
        pending = null;
        return true;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addActivityResultListener(this);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() { activity = null; }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() { activity = null; }
}
