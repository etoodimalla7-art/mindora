package com.mindora.app.ui.screens

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.OpenableColumns
import android.speech.RecognizerIntent
import android.speech.tts.TextToSpeech
import android.util.Base64
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.AddPhotoAlternate
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.outlined.VolumeUp
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import com.mindora.app.data.AppLanguage
import com.mindora.app.data.ChatMessage
import com.mindora.app.data.Conversation
import com.mindora.app.data.VoicePlaybackEvent
import com.mindora.app.ui.components.AppBadge
import com.mindora.app.ui.components.AppSurface
import com.mindora.app.ui.components.BadgeTone
import com.mindora.app.ui.components.MindoraTopBar
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.util.Locale

private data class PendingVisionPhoto(
    val fileName: String,
    val base64: String,
    val mimeType: String
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AiTutorScreen(
    language: AppLanguage,
    conversations: List<Conversation>,
    activeConversation: Conversation?,
    sending: Boolean,
    voicePlayback: SharedFlow<VoicePlaybackEvent>,
    onSendMessage: suspend (String, String?) -> Unit,
    onSendVision: suspend (prompt: String, imageBase64: String, mimeType: String, fileName: String) -> Unit,
    onSendVoiceTranscript: suspend (String) -> Unit,
    onSelectConversation: suspend (String) -> Unit,
    onNewConversation: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var input by remember { mutableStateOf("") }
    var pendingPhoto by remember { mutableStateOf<PendingVisionPhoto?>(null) }
    var showHistorySheet by remember { mutableStateOf(false) }
    val listState = rememberLazyListState()

    var ttsReady by remember { mutableStateOf(false) }
    val tts = remember {
        var instance: TextToSpeech? = null
        instance = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                ttsReady = true
            }
        }
        instance
    }

    DisposableEffect(Unit) {
        onDispose {
            tts.stop()
            tts.shutdown()
        }
    }

    LaunchedEffect(voicePlayback) {
        voicePlayback.collect { ev ->
            if (ttsReady && ev.text.isNotBlank()) {
                val loc = if (ev.locale.startsWith("fr", ignoreCase = true)) Locale.FRENCH else Locale.US
                tts.language = loc
                tts.speak(ev.text, TextToSpeech.QUEUE_FLUSH, null, "mindora-${System.currentTimeMillis()}")
            }
        }
    }

    val imagePicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri: Uri? ->
        if (uri != null) {
            scope.launch {
                val photo = withContext(Dispatchers.IO) { encodeUriToPhoto(context, uri) }
                if (photo != null) {
                    pendingPhoto = photo
                } else {
                    Toast.makeText(
                        context,
                        if (isFr) "Impossible de lire l'image" else "Could not read selected image",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
        }
    }

    val speechLauncher = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { res ->
        if (res.resultCode == Activity.RESULT_OK) {
            val matches = res.data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
            val transcript = matches?.firstOrNull().orEmpty().trim()
            if (transcript.isNotEmpty()) {
                scope.launch { onSendVoiceTranscript(transcript) }
            }
        }
    }

    val startSpeechRecognition = {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, if (isFr) "fr-FR" else "en-US")
            putExtra(
                RecognizerIntent.EXTRA_PROMPT,
                if (isFr) "Pose ta question à MINDORA..." else "Ask MINDORA your question..."
            )
        }
        try {
            speechLauncher.launch(intent)
        } catch (_: Exception) {
            Toast.makeText(
                context,
                if (isFr) "Reconnaissance vocale indisponible sur cet appareil." else "Speech recognition unavailable on this device.",
                Toast.LENGTH_SHORT
            ).show()
        }
    }

    val micPermissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) {
            startSpeechRecognition()
        } else {
            Toast.makeText(
                context,
                if (isFr) "Permission micro requise" else "Microphone permission required",
                Toast.LENGTH_SHORT
            ).show()
        }
    }

    val messages = activeConversation?.messages.orEmpty()
    val lastContentLen = messages.lastOrNull()?.content?.length ?: 0

    LaunchedEffect(messages.size, lastContentLen, sending) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.lastIndex)
        }
    }

    Scaffold(
        topBar = {
            MindoraTopBar(
                showWordmark = true,
                actions = {
                    IconButton(onClick = { showHistorySheet = true }) {
                        Icon(
                            Icons.Outlined.History,
                            contentDescription = if (isFr) "Historique" else "Conversations"
                        )
                    }
                    IconButton(onClick = onNewConversation) {
                        Icon(
                            Icons.Outlined.Add,
                            contentDescription = if (isFr) "Nouvelle discussion" else "New chat"
                        )
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            Box(modifier = Modifier.weight(1f)) {
                if (messages.isEmpty()) {
                    val examples = if (isFr) {
                        listOf(
                            "Explique la dérivée de x² étape par étape.",
                            "Que dit mon cours sur les équations différentielles ?",
                            "Donne-moi 3 exercices corrigés sur les nombres complexes.",
                            "sqrt(144) + 8*3"
                        )
                    } else {
                        listOf(
                            "Explain the derivative of x² step by step.",
                            "What does my course say about differential equations?",
                            "Give me 3 practice questions on integration by parts.",
                            "sqrt(144) + 8*3"
                        )
                    }
                    LazyColumn(
                        contentPadding = PaddingValues(24.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        item {
                            Spacer(modifier = Modifier.height(16.dp))
                            Icon(
                                imageVector = Icons.Outlined.AutoAwesome,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(48.dp)
                            )
                            Spacer(modifier = Modifier.height(14.dp))
                            Text(
                                text = if (isFr) "Pose-moi n'importe quelle question" else "Ask me anything",
                                style = MaterialTheme.typography.headlineSmall,
                                textAlign = TextAlign.Center
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = if (isFr) {
                                    "Je peux expliquer tes chapitres, analyser une photo d'exercice, répondre à la voix et fouiller tes notes."
                                } else {
                                    "I can explain concepts, analyze an exercise photo, answer by voice, and search your uploaded course notes."
                                },
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                textAlign = TextAlign.Center
                            )
                            Spacer(modifier = Modifier.height(24.dp))
                            Text(
                                text = if (isFr) "Essaie par exemple" else "Try one of these",
                                style = MaterialTheme.typography.labelMedium,
                                modifier = Modifier.fillMaxWidth()
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                        }
                        items(examples) { ex ->
                            AppSurface(
                                containerColor = MaterialTheme.colorScheme.surfaceVariant,
                                onClick = { input = ex }
                            ) {
                                Row(
                                    modifier = Modifier.padding(14.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(16.dp)
                                    )
                                    Spacer(modifier = Modifier.width(10.dp))
                                    Text(text = ex, style = MaterialTheme.typography.bodyMedium)
                                }
                            }
                        }
                    }
                } else {
                    LazyColumn(
                        state = listState,
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(messages, key = { it.id }) { msg ->
                            ChatBubbleItem(
                                msg = msg,
                                onSpeak = { text ->
                                    if (ttsReady) {
                                        tts.language = if (isFr) Locale.FRENCH else Locale.US
                                        tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "msg-${msg.id}")
                                    }
                                }
                            )
                        }
                        if (sending && messages.lastOrNull()?.content.isNullOrBlank()) {
                            item {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    modifier = Modifier.padding(vertical = 4.dp)
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(30.dp)
                                            .clip(CircleShape)
                                            .background(MaterialTheme.colorScheme.primary),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Icon(
                                            Icons.Outlined.AutoAwesome,
                                            contentDescription = null,
                                            tint = MaterialTheme.colorScheme.onPrimary,
                                            modifier = Modifier.size(16.dp)
                                        )
                                    }
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Surface(
                                        shape = RoundedCornerShape(16.dp),
                                        color = MaterialTheme.colorScheme.surfaceVariant
                                    ) {
                                        Row(
                                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            CircularProgressIndicator(
                                                modifier = Modifier.size(14.dp),
                                                strokeWidth = 2.dp
                                            )
                                            Spacer(modifier = Modifier.width(8.dp))
                                            Text(
                                                if (isFr) "Réflexion en cours..." else "Thinking...",
                                                style = MaterialTheme.typography.bodySmall
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            pendingPhoto?.let { photo ->
                Surface(
                    color = MaterialTheme.colorScheme.surfaceVariant,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = if (isFr) "Photo prête : ${photo.fileName}" else "Photo attached: ${photo.fileName}",
                            style = MaterialTheme.typography.labelMedium,
                            modifier = Modifier.weight(1f),
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        IconButton(onClick = { pendingPhoto = null }, modifier = Modifier.size(28.dp)) {
                            Icon(Icons.Outlined.Close, contentDescription = "Remove photo", modifier = Modifier.size(16.dp))
                        }
                    }
                }
            }

            HorizontalDivider()
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.surface)
                    .padding(horizontal = 6.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(
                    onClick = { imagePicker.launch("image/*") },
                    enabled = !sending
                ) {
                    Icon(
                        Icons.Outlined.AddPhotoAlternate,
                        contentDescription = if (isFr) "Photo exercice" else "Photo exercise"
                    )
                }
                IconButton(
                    onClick = {
                        val granted = ContextCompat.checkSelfPermission(
                            context,
                            Manifest.permission.RECORD_AUDIO
                        ) == PackageManager.PERMISSION_GRANTED
                        if (granted) startSpeechRecognition()
                        else micPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                    },
                    enabled = !sending
                ) {
                    Icon(
                        Icons.Outlined.Mic,
                        contentDescription = if (isFr) "Dictée vocale" else "Voice input"
                    )
                }
                OutlinedTextField(
                    value = input,
                    onValueChange = { input = it },
                    placeholder = {
                        Text(
                            if (isFr) "Pose une question ou envoie une photo..."
                            else "Ask anything, or attach an exercise..."
                        )
                    },
                    maxLines = 4,
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.width(6.dp))
                IconButton(
                    onClick = {
                        val text = input
                        val photo = pendingPhoto
                        if (photo != null) {
                            input = ""
                            pendingPhoto = null
                            scope.launch {
                                onSendVision(text, photo.base64, photo.mimeType, photo.fileName)
                            }
                        } else if (text.isNotBlank()) {
                            input = ""
                            scope.launch {
                                onSendMessage(text, null)
                            }
                        }
                    },
                    enabled = !sending && (input.isNotBlank() || pendingPhoto != null),
                    colors = IconButtonDefaults.filledIconButtonColors()
                ) {
                    Icon(Icons.AutoMirrored.Filled.Send, contentDescription = if (isFr) "Envoyer" else "Send")
                }
            }
        }
    }

    if (showHistorySheet) {
        ModalBottomSheet(onDismissRequest = { showHistorySheet = false }) {
            Column(modifier = Modifier.padding(20.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(if (isFr) "Historique" else "Conversations", style = MaterialTheme.typography.titleLarge)
                    TextButton(onClick = {
                        onNewConversation()
                        showHistorySheet = false
                    }) {
                        Text(if (isFr) "+ Nouveau chat" else "+ New chat")
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
                if (conversations.isEmpty()) {
                    Text(
                        if (isFr) "Aucune conversation. Pose une question pour commencer."
                        else "No conversations yet. Ask a question to get started.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                } else {
                    conversations.forEach { conv ->
                        AppSurface(
                            modifier = Modifier.padding(bottom = 8.dp),
                            onClick = {
                                scope.launch { onSelectConversation(conv.id) }
                                showHistorySheet = false
                            }
                        ) {
                            Row(
                                modifier = Modifier.padding(14.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = conv.title,
                                        style = MaterialTheme.typography.titleSmall,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                    Text(
                                        text = "${conv.messages.size} messages",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }
                    }
                }
                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ChatBubbleItem(
    msg: ChatMessage,
    onSpeak: (String) -> Unit
) {
    val isUser = msg.isUser
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isUser) Arrangement.End else Arrangement.Start
    ) {
        if (!isUser) {
            Box(
                modifier = Modifier
                    .size(30.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Outlined.AutoAwesome,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onPrimary,
                    modifier = Modifier.size(15.dp)
                )
            }
            Spacer(modifier = Modifier.width(8.dp))
        }

        Column(
            modifier = Modifier.widthIn(max = 290.dp),
            horizontalAlignment = if (isUser) Alignment.End else Alignment.Start
        ) {
            Surface(
                shape = RoundedCornerShape(
                    topStart = 16.dp,
                    topEnd = 16.dp,
                    bottomStart = if (isUser) 16.dp else 4.dp,
                    bottomEnd = if (isUser) 4.dp else 16.dp
                ),
                color = if (isUser) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant
            ) {
                Column(modifier = Modifier.padding(12.dp)) {
                    if (msg.attachmentLabel != null) {
                        Text(
                            text = "[${msg.attachmentLabel}]",
                            style = MaterialTheme.typography.labelSmall,
                            color = if (isUser) MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.85f)
                            else MaterialTheme.colorScheme.primary
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                    }
                    Text(
                        text = msg.content.ifBlank { "..." },
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (isUser) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurface
                    )
                    if (!isUser && msg.content.isNotBlank()) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.End
                        ) {
                            IconButton(
                                onClick = { onSpeak(msg.content) },
                                modifier = Modifier.size(28.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Outlined.VolumeUp,
                                    contentDescription = "Listen",
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(16.dp)
                                )
                            }
                        }
                    }
                }
            }
            if (!isUser && msg.toolsUsed.isNotEmpty()) {
                Spacer(modifier = Modifier.height(4.dp))
                FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    msg.toolsUsed.forEach { t ->
                        AppBadge(
                            label = if (t.detail != null) "${t.name}: ${t.detail}" else t.name,
                            tone = BadgeTone.INFO
                        )
                    }
                }
            }
        }
    }
}

private fun encodeUriToPhoto(context: android.content.Context, uri: Uri): PendingVisionPhoto? {
    val fileName = runCatching {
        context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (cursor.moveToFirst() && idx >= 0) cursor.getString(idx) else null
        }
    }.getOrNull() ?: uri.lastPathSegment?.substringAfterLast('/') ?: "exercise.jpg"

    val rawBytes = runCatching {
        context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
    }.getOrNull() ?: return null

    val bmp = BitmapFactory.decodeByteArray(rawBytes, 0, rawBytes.size)
    val finalBytes = if (bmp != null) {
        val maxDim = 1280
        val scale = if (bmp.width > maxDim || bmp.height > maxDim) {
            minOf(maxDim.toFloat() / bmp.width, maxDim.toFloat() / bmp.height)
        } else 1f
        val resized = if (scale < 1f) {
            Bitmap.createScaledBitmap(bmp, (bmp.width * scale).toInt(), (bmp.height * scale).toInt(), true)
        } else bmp
        val out = ByteArrayOutputStream()
        var quality = 85
        resized.compress(Bitmap.CompressFormat.JPEG, quality, out)
        while (out.size() > 950_000 && quality > 35) {
            out.reset()
            quality -= 15
            resized.compress(Bitmap.CompressFormat.JPEG, quality, out)
        }
        out.toByteArray()
    } else {
        rawBytes
    }
    return PendingVisionPhoto(
        fileName = fileName,
        base64 = Base64.encodeToString(finalBytes, Base64.NO_WRAP),
        mimeType = "image/jpeg"
    )
}
