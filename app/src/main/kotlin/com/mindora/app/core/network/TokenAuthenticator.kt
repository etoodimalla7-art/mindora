package com.mindora.app.core.network

import com.google.gson.Gson
import com.mindora.app.core.storage.TokenStorage
import okhttp3.Authenticator
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import okhttp3.Route

class TokenAuthenticator(
    private val tokenStore: TokenStorage,
    private val refreshClient: OkHttpClient,
    private val onSessionExpired: () -> Unit
) : Authenticator {

    private val gson = Gson()
    private val lock = Any()

    override fun authenticate(route: Route?, response: Response): Request? {
        val path = response.request.url.encodedPath
        if (path.endsWith("/auth/refresh") || path.endsWith("/auth/login")) {
            return null
        }

        // Prevent infinite retry loops
        if (responseCount(response) >= 2) {
            return null
        }

        synchronized(lock) {
            val currentAccess = tokenStore.accessToken
            val reqAuth = response.request.header("Authorization")?.removePrefix("Bearer ")?.trim()

            // Another thread already refreshed the token cleanly
            if (!currentAccess.isNullOrBlank() && currentAccess != reqAuth) {
                return response.request.newBuilder()
                    .header("Authorization", "Bearer $currentAccess")
                    .build()
            }

            val refresh = tokenStore.refreshToken ?: run {
                tokenStore.clearSession()
                onSessionExpired()
                return null
            }

            val refreshUrl = "${tokenStore.apiBaseUrl}auth/refresh"
            val bodyJson = gson.toJson(RefreshRequestDto(refresh))
            val req = Request.Builder()
                .url(refreshUrl)
                .post(bodyJson.toRequestBody("application/json; charset=utf-8".toMediaType()))
                .build()

            return try {
                refreshClient.newCall(req).execute().use { refreshResp ->
                    if (!refreshResp.isSuccessful) {
                        tokenStore.clearSession()
                        onSessionExpired()
                        return null
                    }
                    val rawBody = refreshResp.body?.string().orEmpty()
                    val parsed = gson.fromJson(rawBody, AuthResponseDto::class.java)
                    tokenStore.saveSession(
                        access = parsed.tokens.accessToken,
                        refresh = parsed.tokens.refreshToken,
                        id = parsed.user.id,
                        email = parsed.user.email
                    )
                    response.request.newBuilder()
                        .header("Authorization", "Bearer ${parsed.tokens.accessToken}")
                        .build()
                }
            } catch (_: Exception) {
                null
            }
        }
    }

    private fun responseCount(response: Response): Int {
        var r: Response? = response
        var count = 1
        while (r?.priorResponse != null) {
            count++
            r = r.priorResponse
        }
        return count
    }
}
