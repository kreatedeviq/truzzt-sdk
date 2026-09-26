package com.truzzt.sdk

import android.app.Activity
import android.content.Intent
import org.json.JSONObject

/**
 * Kotlin-friendly entry points for [TruzztSdk].
 */
object Truzzt {

    @JvmStatic
    fun configure(
        apiKey: String,
        projectId: String,
        baseUrl: String? = null,
        theme: Map<String, String>? = null,
    ) {
        val themeJson = theme?.let { map ->
            JSONObject().apply { map.forEach { (k, v) -> put(k, v) } }
        }
        TruzztSdk.configure(apiKey, projectId, baseUrl, themeJson)
    }

    @JvmStatic
    fun setTheme(theme: Map<String, String>) {
        TruzztSdk.setTheme(
            JSONObject().apply { theme.forEach { (k, v) -> put(k, v) } },
        )
    }

    @JvmStatic
    fun requestPermissions(activity: Activity) = TruzztSdk.requestPermissions(activity)

    @JvmStatic
    fun getSimPhones(activity: Activity) = TruzztSdk.getSimPhones(activity)

    @JvmStatic
    fun verifyIntent(activity: Activity, sessionUrl: String): Intent =
        TruzztSdk.verifyIntent(activity, sessionUrl)

    @JvmStatic
    fun openVerify(activity: Activity, sessionUrl: String, requestCode: Int) =
        TruzztSdk.openVerify(activity, sessionUrl, requestCode)

    @JvmStatic
    fun parseResult(data: Intent?) = TruzztSdk.parseResult(data)

    @JvmStatic
    fun applyThemeToUrl(sessionUrl: String): String = TruzztSdk.applyThemeToUrl(sessionUrl)
}
