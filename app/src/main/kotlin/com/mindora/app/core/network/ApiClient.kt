package com.mindora.app.core.network

import com.google.gson.GsonBuilder
import com.mindora.app.core.storage.TokenStorage
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

class ApiClient(
    val tokenStore: TokenStorage,
    onSessionExpired: () -> Unit
) {
    private val refreshClient: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(20, TimeUnit.SECONDS)
        .build()

    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BASIC
        redactHeader("Authorization")
        redactHeader("Cookie")
    }

    val okHttpClient: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .addInterceptor(AuthInterceptor(tokenStore))
        .addInterceptor(loggingInterceptor)
        .authenticator(TokenAuthenticator(tokenStore, refreshClient, onSessionExpired))
        .build()

    private val gson = GsonBuilder()
        .setLenient()
        .create()

    fun buildService(baseUrl: String = tokenStore.apiBaseUrl): MindoraApiService {
        val normalized = if (baseUrl.endsWith("/")) baseUrl else "$baseUrl/"
        return Retrofit.Builder()
            .baseUrl(normalized)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()
            .create(MindoraApiService::class.java)
    }

    @Volatile
    var api: MindoraApiService = buildService()
        private set

    fun updateBaseUrl(newBaseUrl: String) {
        tokenStore.apiBaseUrl = newBaseUrl
        api = buildService(tokenStore.apiBaseUrl)
    }
}
