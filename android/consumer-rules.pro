# Keep SDK classes for WebView JS bridges
-keepclassmembers class com.truzzt.sdk.SimBridge { @android.webkit.JavascriptInterface <methods>; }
-keepclassmembers class com.truzzt.sdk.HostBridge { @android.webkit.JavascriptInterface <methods>; }
-keep class com.truzzt.sdk.** { *; }
