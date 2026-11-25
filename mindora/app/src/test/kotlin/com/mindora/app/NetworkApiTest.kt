package com.mindora.app

import com.mindora.app.core.network.ApiClient
import com.mindora.app.core.network.ChatRequestDto
import com.mindora.app.core.network.SseChatClient
import com.mindora.app.core.network.SseChatEvent
import com.mindora.app.core.storage.TokenStorage
import kotlinx.coroutines.test.runTest
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

private class FakeTokenStorage(baseUrl: String) : TokenStorage {
    override var accessToken: String? = "expired-access-token"
    override var refreshToken: String? = "valid-refresh-token"
    override var userId: String? = "user-1"
    override var userEmail: String? = "student@mindora.dev"
    override var apiBaseUrl: String = if (baseUrl.endsWith("/")) baseUrl else "$baseUrl/"

    override fun saveSession(access: String, refresh: String, id: String?, email: String?) {
        accessToken = access
        refreshToken = refresh
        userId = id
        userEmail = email
    }

    override fun clearSession() {
        accessToken = null
        refreshToken = null
        userId = null
        userEmail = null
    }

    override fun hasTokens(): Boolean = !accessToken.isNullOrBlank() && !refreshToken.isNullOrBlank()
}

class NetworkApiTest {

    private lateinit var server: MockWebServer

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
    }

    @After
    fun tearDown() {
        server.shutdown()
    }

    @Test
    fun `token authenticator automatically refreshes 401 and retries with rotated access token`() = runTest {
        val baseUrl = server.url("/api/v1/").toString()
        val storage = FakeTokenStorage(baseUrl)
        var sessionExpiredCalled = false
        val client = ApiClient(storage) { sessionExpiredCalled = true }

        // 1st call -> 401 unauthorized
        server.enqueue(MockResponse().setResponseCode(401).setBody("""{"detail":"Token expired"}"""))
        // 2nd call -> /auth/refresh returns new tokens
        server.enqueue(
            MockResponse().setResponseCode(200).setBody(
                """
                {
                  "user": {
                    "id": "user-1",
                    "email": "student@mindora.dev",
                    "full_name": "Test Student",
                    "preferred_language": "fr",
                    "country_code": "CM",
                    "is_verified": true
                  },
                  "tokens": {
                    "access_token": "fresh-access-token",
                    "refresh_token": "fresh-refresh-token",
                    "token_type": "bearer"
                  }
                }
                """.trimIndent()
            )
        )
        // 3rd call -> retried /credits/balance succeeds
        server.enqueue(MockResponse().setResponseCode(200).setBody("""{"balance": 12}"""))

        val balance = client.api.getCreditsBalance()
        assertEquals(12, balance.balance)
        assertEquals("fresh-access-token", storage.accessToken)
        assertEquals("fresh-refresh-token", storage.refreshToken)
        assertTrue(!sessionExpiredCalled)

        val req1 = server.takeRequest()
        assertEquals("Bearer expired-access-token", req1.getHeader("Authorization"))
        val req2 = server.takeRequest()
        assertTrue(req2.path!!.endsWith("/auth/refresh"))
        val req3 = server.takeRequest()
        assertEquals("Bearer fresh-access-token", req3.getHeader("Authorization"))
    }

    @Test
    fun `sse chat client parses meta token and done events sequentially`() = runTest {
        val baseUrl = server.url("/api/v1/").toString()
        val storage = FakeTokenStorage(baseUrl)
        storage.accessToken = "live-token"
        val client = ApiClient(storage) {}
        val sse = SseChatClient(client.okHttpClient, storage)

        val ssePayload = buildString {
            append("event: meta\n")
            append("data: {\"conversation_id\":\"conv-42\"}\n\n")
            append("event: token\n")
            append("data: {\"text\":\"Hello \"}\n\n")
            append("event: token\n")
            append("data: {\"text\":\"world!\"}\n\n")
            append("event: done\n")
            append("data: {\"message_id\":\"msg-99\",\"conversation_id\":\"conv-42\",\"tools_used\":[{\"name\":\"calculator\",\"result_preview\":\"42\"}]}\n\n")
        }

        server.enqueue(
            MockResponse()
                .setResponseCode(200)
                .setHeader("Content-Type", "text/event-stream")
                .setBody(ssePayload)
        )

        val events = mutableListOf<SseChatEvent>()
        sse.streamChat(ChatRequestDto(message = "Hi")) { events.add(it) }

        assertEquals(4, events.size)
        assertEquals("conv-42", (events[0] as SseChatEvent.Meta).conversationId)
        assertEquals("Hello ", (events[1] as SseChatEvent.Token).text)
        assertEquals("world!", (events[2] as SseChatEvent.Token).text)
        val done = events[3] as SseChatEvent.Done
        assertEquals("msg-99", done.messageId)
        assertEquals(1, done.toolsUsed.size)
        assertEquals("calculator", done.toolsUsed.first().first)
    }
}
