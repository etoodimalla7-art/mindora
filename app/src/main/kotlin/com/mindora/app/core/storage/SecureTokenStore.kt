package com.mindora.app.core.storage

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.mindora.app.BuildConfig

interface TokenStorage {
    var accessToken: String?
    var refreshToken: String?
    var userId: String?
    var userEmail: String?
    var apiBaseUrl: String
    fun saveSession(access: String, refresh: String, id: String?, email: String?)
    fun clearSession()
    fun hasTokens(): Boolean
}

class SecureTokenStore(context: Context) : TokenStorage {

    private val prefs: SharedPreferences = createPrefs(context.applicationContext)

    private fun createPrefs(ctx: Context): SharedPreferences {
        return try {
            val masterKey = MasterKey.Builder(ctx)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            EncryptedSharedPreferences.create(
                ctx,
                PREFS_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (_: Exception) {
            ctx.getSharedPreferences("${PREFS_NAME}_fallback", Context.MODE_PRIVATE)
        }
    }

    override var accessToken: String?
        get() = prefs.getString(KEY_ACCESS_TOKEN, null)?.takeIf { it.isNotBlank() }
        set(value) {
            prefs.edit().putString(KEY_ACCESS_TOKEN, value).apply()
        }

    override var refreshToken: String?
        get() = prefs.getString(KEY_REFRESH_TOKEN, null)?.takeIf { it.isNotBlank() }
        set(value) {
            prefs.edit().putString(KEY_REFRESH_TOKEN, value).apply()
        }

    override var userId: String?
        get() = prefs.getString(KEY_USER_ID, null)?.takeIf { it.isNotBlank() }
        set(value) {
            prefs.edit().putString(KEY_USER_ID, value).apply()
        }

    override var userEmail: String?
        get() = prefs.getString(KEY_USER_EMAIL, null)?.takeIf { it.isNotBlank() }
        set(value) {
            prefs.edit().putString(KEY_USER_EMAIL, value).apply()
        }

    override var apiBaseUrl: String
        get() {
            val raw = prefs.getString(KEY_API_BASE_URL, null)?.takeIf { it.isNotBlank() }
                ?: BuildConfig.API_BASE_URL
            return if (raw.endsWith("/")) raw else "$raw/"
        }
        set(value) {
            val normalized = if (value.endsWith("/")) value else "$value/"
            prefs.edit().putString(KEY_API_BASE_URL, normalized).apply()
        }

    override fun saveSession(access: String, refresh: String, id: String?, email: String?) {
        prefs.edit()
            .putString(KEY_ACCESS_TOKEN, access)
            .putString(KEY_REFRESH_TOKEN, refresh)
            .putString(KEY_USER_ID, id)
            .putString(KEY_USER_EMAIL, email)
            .apply()
    }

    override fun clearSession() {
        prefs.edit()
            .remove(KEY_ACCESS_TOKEN)
            .remove(KEY_REFRESH_TOKEN)
            .remove(KEY_USER_ID)
            .remove(KEY_USER_EMAIL)
            .apply()
    }

    override fun hasTokens(): Boolean = !accessToken.isNullOrBlank() && !refreshToken.isNullOrBlank()

    companion object {
        private const val PREFS_NAME = "mindora_secure_auth"
        private const val KEY_ACCESS_TOKEN = "access_token"
        private const val KEY_REFRESH_TOKEN = "refresh_token"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_USER_EMAIL = "user_email"
        private const val KEY_API_BASE_URL = "api_base_url"
    }
}
