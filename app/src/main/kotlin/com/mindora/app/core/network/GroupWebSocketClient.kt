package com.mindora.app.core.network

import com.mindora.app.core.storage.TokenStorage
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import org.json.JSONObject

class GroupWebSocketClient(
    private val client: OkHttpClient,
    private val tokenStore: TokenStorage
) {
    private var webSocket: WebSocket? = null

    fun connectStudyGroup(
        groupId: String,
        onMessage: (GroupMessageOutDto) -> Unit,
        onPresence: (Int) -> Unit = {},
        onClosed: () -> Unit = {}
    ) {
        disconnect()
        val token = tokenStore.accessToken ?: return
        val wsBase = tokenStore.apiBaseUrl
            .replaceFirst("https://", "wss://")
            .replaceFirst("http://", "ws://")
        val url = "${wsBase}study-groups/$groupId/ws?token=$token"
        val req = Request.Builder().url(url).build()

        webSocket = client.newWebSocket(req, object : WebSocketListener() {
            override fun onMessage(ws: WebSocket, text: String) {
                try {
                    val obj = JSONObject(text)
                    when (obj.optString("type")) {
                        "message" -> {
                            val d = obj.optJSONObject("data") ?: return
                            onMessage(
                                GroupMessageOutDto(
                                    id = d.optString("id"),
                                    groupId = d.optString("group_id"),
                                    userId = d.optString("user_id"),
                                    content = d.optString("content"),
                                    createdAt = d.optString("created_at"),
                                    userName = d.optString("user_name").takeIf { it.isNotBlank() }
                                )
                            )
                        }
                        "presence" -> onPresence(obj.optInt("count", 1))
                    }
                } catch (_: Exception) {
                }
            }

            override fun onClosed(ws: WebSocket, code: Int, reason: String) {
                onClosed()
            }

            override fun onFailure(ws: WebSocket, t: Throwable, response: Response?) {
                onClosed()
            }
        })
    }

    fun sendMessage(content: String): Boolean {
        val ws = webSocket ?: return false
        val payload = JSONObject().put("content", content.trim()).toString()
        return ws.send(payload)
    }

    fun disconnect() {
        webSocket?.close(1000, "User left chat")
        webSocket = null
    }
}
