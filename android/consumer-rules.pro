# Keep SDK classes for WebView JS bridges
-keepclassmembers class com.niv2fa.sdk.SimBridge { @android.webkit.JavascriptInterface <methods>; }
-keepclassmembers class com.niv2fa.sdk.HostBridge { @android.webkit.JavascriptInterface <methods>; }
-keep class com.niv2fa.sdk.** { *; }
