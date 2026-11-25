package com.mindora.app.core.network

import com.mindora.app.core.storage.TokenStorage
import okhttp3.Interceptor
import okhttp3.Response

class AuthInterceptor(private val tokenStore: TokenStorage) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val original = chain.request()
        val path = original.url.encodedPath
        val skipAuth = path.endsWith("/auth/login") ||
            path.endsWith("/auth/register") ||
            path.endsWith("/auth/refresh") ||
            path.endsWith("/auth/send-otp") ||
            path.endsWith("/auth/verify-otp") ||
            path.endsWith("/settings/maintenance") ||
            path.endsWith("/settings/public") ||
            path.endsWith("/subscriptions/plans/public")

        if (skipAuth) {
            return chain.proceed(original)
        }

        val token = tokenStore.accessToken
        if (token.isNullOrBlank()) {
            return chain.proceed(original)
        }

        val authed = original.newBuilder()
            .header("Authorization", "Bearer $token")
            .build()
        return chain.proceed(authed)
    }
}
