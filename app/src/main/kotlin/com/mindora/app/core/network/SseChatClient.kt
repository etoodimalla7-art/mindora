package com.mindora.app.core.network

import com.google.gson.Gson
import com.google.gson.JsonParser
import com.mindora.app.core.storage.TokenStorage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody

sealed class SseChatEvent {
    data class Meta(val conversationId: String) : SseChatEvent()
    data class Token(val text: String) : SseChatEvent()
    data class Done(
        val messageId: String,
        val conversationId: String?,
        val toolsUsed: List<Pair<String, String?>>
    ) : SseChatEvent()

    data class Error(val message: String) : SseChatEvent()
}

class SseChatClient(
    private val client: OkHttpClient,
    private val tokenStore: TokenStorage
) {
    private val gson = Gson()

    suspend fun streamChat(
        request: ChatRequestDto,
        onEvent: (SseChatEvent) -> Unit
    ) = withContext(Dispatchers.IO) {
        val url = "${tokenStore.apiBaseUrl}ai/chat/stream"
        val json = gson.toJson(request)
        val httpReq = Request.Builder()
            .url(url)
            .header("Accept", "text/event-stream")
            .post(json.toRequestBody("application/json; charset=utf-8".toMediaType()))
            .build()

        client.newCall(httpReq).execute().use { response ->
            if (!response.isSuccessful) {
                onEvent(SseChatEvent.Error("HTTP ${response.code}"))
                return@use
            }
            val source = response.body?.source() ?: run {
                onEvent(SseChatEvent.Error("Empty stream body"))
                return@use
            }

            var currentEvent = "message"
            val dataLines = StringBuilder()

            while (!source.exhausted()) {
                val line = source.readUtf8Line() ?: break
                when {
                    line.startsWith("event:") -> {
                        currentEvent = line.removePrefix("event:").trim()
                    }
                    line.startsWith("data:") -> {
                        if (dataLines.isNotEmpty()) dataLines.append('\n')
                        dataLines.append(line.removePrefix("data:").trim())
                    }
                    line.isBlank() -> {
                        if (dataLines.isNotEmpty()) {
                            dispatchEvent(currentEvent, dataLines.toString(), onEvent)
                            dataLines.clear()
                            currentEvent = "message"
                        }
                    }
                }
            }
            if (dataLines.isNotEmpty()) {
                dispatchEvent(currentEvent, dataLines.toString(), onEvent)
            }
        }
    }

    private fun dispatchEvent(event: String, rawData: String, onEvent: (SseChatEvent) -> Unit) {
        try {
            val elem = JsonParser.parseString(rawData)
            if (!elem.isJsonObject) return
            val obj = elem.asJsonObject
            fun optStr(key: String): String {
                val member = obj.get(key) ?: return ""
                return if (member.isJsonNull) "" else member.asString
            }

            when (event) {
                "meta" -> {
                    val convId = optStr("conversation_id")
                    if (convId.isNotBlank()) onEvent(SseChatEvent.Meta(convId))
                }
                "token" -> {
                    val txt = optStr("text")
                    if (txt.isNotEmpty()) onEvent(SseChatEvent.Token(txt))
                }
                "done" -> {
                    val msgId = optStr("message_id")
                    val convId = optStr("conversation_id").takeIf { it.isNotBlank() }
                    val toolsElem = obj.get("tools_used")
                    val tools = if (toolsElem != null && toolsElem.isJsonArray) {
                        toolsElem.asJsonArray.mapNotNull { item ->
                            if (!item.isJsonObject) return@mapNotNull null
                            val t = item.asJsonObject
                            val name = t.get("name")?.takeIf { !it.isJsonNull }?.asString?.takeIf { it.isNotBlank() }
                                ?: return@mapNotNull null
                            val preview = t.get("result_preview")?.takeIf { !it.isJsonNull }?.asString?.takeIf { it.isNotBlank() }
                            name to preview
                        }
                    } else {
                        emptyList()
                    }
                    onEvent(SseChatEvent.Done(msgId, convId, tools))
                }
                "error" -> {
                    val msg = optStr("message").ifBlank { "Stream error" }
                    onEvent(SseChatEvent.Error(msg))
                }
            }
        } catch (_: Exception) {
        }
    }
}
