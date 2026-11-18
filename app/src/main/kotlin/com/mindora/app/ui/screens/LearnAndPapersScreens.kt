package com.mindora.app.ui.screens

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.FolderCopy
import androidx.compose.material.icons.outlined.PictureAsPdf
import androidx.compose.material.icons.outlined.Quiz
import androidx.compose.material.icons.outlined.Style
import androidx.compose.material.icons.outlined.UploadFile
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.mindora.app.data.ContributedDocument
import com.mindora.app.data.PastPaper
import com.mindora.app.ui.components.AppBadge
import com.mindora.app.ui.components.AppEmptyState
import com.mindora.app.ui.components.AppSurface
import com.mindora.app.ui.components.BadgeTone
import com.mindora.app.ui.components.MindoraTopBar
import com.mindora.app.ui.theme.MindoraPalette
import kotlinx.coroutines.launch

@Composable
fun LearnHubScreen(
    creditsBalance: Int,
    papersCount: Int,
    decksCount: Int,
    examsCount: Int,
    docsCount: Int,
    onOpenPastPapers: () -> Unit,
    onOpenFlashcards: () -> Unit,
    onOpenMockExams: () -> Unit,
    onOpenContribute: () -> Unit,
    onOpenMyContributions: () -> Unit
) {
    Scaffold(
        topBar = { MindoraTopBar(showWordmark = true) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                AppSurface(
                    containerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.08f)
                ) {
                    Row(
                        modifier = Modifier.padding(18.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .size(52.dp)
                                .clip(RoundedCornerShape(14.dp))
                                .background(MaterialTheme.colorScheme.primary),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "$creditsBalance",
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onPrimary
                            )
                        }
                        Spacer(modifier = Modifier.width(14.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text("Download credits", style = MaterialTheme.typography.titleMedium)
                            Text(
                                text = "Earn 5 credits for each approved document contribution.",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }

            item {
                LearnHubTile(
                    icon = Icons.Outlined.Description,
                    iconTint = MindoraPalette.Danger,
                    title = "Past Papers",
                    subtitle = "$papersCount exam papers · Filter by GCE, BEPC, Bac",
                    onClick = onOpenPastPapers
                )
            }
            item {
                LearnHubTile(
                    icon = Icons.Outlined.Style,
                    iconTint = MaterialTheme.colorScheme.primary,
                    title = "Flashcards",
                    subtitle = "$decksCount decks · SM-2 spaced repetition review",
                    onClick = onOpenFlashcards
                )
            }
            item {
                LearnHubTile(
                    icon = Icons.Outlined.Quiz,
                    iconTint = MindoraPalette.Accent500,
                    title = "Mock Exams",
                    subtitle = "$examsCount exams · Timed practice with detailed corrections",
                    onClick = onOpenMockExams
                )
            }
            item {
                LearnHubTile(
                    icon = Icons.Outlined.UploadFile,
                    iconTint = MindoraPalette.Success,
                    title = "Contribute a document",
                    subtitle = "Upload course notes or study guides (+5 credits)",
                    onClick = onOpenContribute
                )
            }
            item {
                LearnHubTile(
                    icon = Icons.Outlined.FolderCopy,
                    iconTint = MaterialTheme.colorScheme.primary,
                    title = "My contributions",
                    subtitle = "$docsCount documents indexed for AI Tutor search",
                    onClick = onOpenMyContributions
                )
            }
        }
    }
}

@Composable
private fun LearnHubTile(
    icon: ImageVector,
    iconTint: Color,
    title: String,
    subtitle: String,
    onClick: () -> Unit
) {
    AppSurface(onClick = onClick) {
        Row(
            modifier = Modifier.padding(18.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(iconTint.copy(alpha = 0.12f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(imageVector = icon, contentDescription = null, tint = iconTint)
            }
            Spacer(modifier = Modifier.width(14.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Icon(
                imageVector = Icons.Outlined.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
fun PastPapersScreen(
    papers: List<PastPaper>,
    creditsBalance: Int,
    onUnlockPaper: (String) -> Boolean,
    onBack: () -> Unit
) {
    var selectedSystem by remember { mutableStateOf<String?>(null) }
    var selectedLevel by remember { mutableStateOf<String?>(null) }
    var previewPaper by remember { mutableStateOf<PastPaper?>(null) }
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    val filtered = papers.filter { p ->
        (selectedSystem == null || p.examSystem == selectedSystem) &&
            (selectedLevel == null || p.examLevel == selectedLevel)
    }

    Scaffold(
        topBar = { MindoraTopBar(title = "Past Papers", onBack = onBack) },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp)) {
                Text("System", style = MaterialTheme.typography.labelMedium)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf(null to "All", "GCE" to "GCE", "Francophone" to "Francophone").forEach { (v, label) ->
                        FilterChip(
                            selected = selectedSystem == v,
                            onClick = { selectedSystem = v },
                            label = { Text(label) }
                        )
                    }
                }
                Spacer(modifier = Modifier.height(6.dp))
                Text("Level", style = MaterialTheme.typography.labelMedium)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf(null to "All", "O-Level" to "O-Level", "A-Level" to "A-Level", "BEPC" to "BEPC", "Bac" to "Bac")
                        .forEach { (v, label) ->
                            FilterChip(
                                selected = selectedLevel == v,
                                onClick = { selectedLevel = v },
                                label = { Text(label) }
                            )
                        }
                }
            }

            if (filtered.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    AppEmptyState(
                        icon = Icons.Outlined.Description,
                        title = "No past papers found",
                        message = "Try adjusting the system or level filters."
                    )
                }
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(filtered, key = { it.id }) { paper ->
                        AppSurface(onClick = { previewPaper = paper }) {
                            Row(
                                modifier = Modifier.padding(14.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.Outlined.PictureAsPdf,
                                    contentDescription = null,
                                    tint = MindoraPalette.Danger,
                                    modifier = Modifier.size(30.dp)
                                )
                                Spacer(modifier = Modifier.width(12.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(paper.title, style = MaterialTheme.typography.titleSmall)
                                    Text(
                                        text = "${paper.subject} · ${paper.examSystem} ${paper.examLevel} ${paper.examYear} · ${paper.fileSizeLabel}",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                                if (paper.isUnlocked) {
                                    AppBadge(label = "UNLOCKED", tone = BadgeTone.SUCCESS)
                                } else {
                                    IconButton(onClick = {
                                        val ok = onUnlockPaper(paper.id)
                                        scope.launch {
                                            snackbarHostState.showSnackbar(
                                                if (ok) "Unlocked ${paper.title} (-2 credits)"
                                                else "Need 2 credits to unlock (you have $creditsBalance). Contribute a document to earn +5!"
                                            )
                                        }
                                    }) {
                                        Icon(Icons.Outlined.Download, contentDescription = "Unlock & view")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    previewPaper?.let { paper ->
        AlertDialog(
            onDismissRequest = { previewPaper = null },
            title = { Text(paper.title) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        "${paper.examSystem} · ${paper.examLevel} · ${paper.session} ${paper.examYear}",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.primary
                    )
                    if (paper.isUnlocked) {
                        Text("Sample Questions:", style = MaterialTheme.typography.titleSmall)
                        paper.sampleQuestions.forEach { q ->
                            Text(q, style = MaterialTheme.typography.bodySmall)
                        }
                    } else {
                        Text(
                            "Unlock this paper for 2 download credits (Current balance: $creditsBalance credits).",
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }
            },
            confirmButton = {
                if (!paper.isUnlocked) {
                    Button(onClick = {
                        val ok = onUnlockPaper(paper.id)
                        if (ok) {
                            previewPaper = paper.copy(isUnlocked = true)
                        } else {
                            previewPaper = null
                            scope.launch {
                                snackbarHostState.showSnackbar("Insufficient credits ($creditsBalance). Contribute notes to earn +5 credits.")
                            }
                        }
                    }) {
                        Text("Unlock (2 credits)")
                    }
                } else {
                    Button(onClick = { previewPaper = null }) { Text("Close") }
                }
            },
            dismissButton = {
                if (!paper.isUnlocked) {
                    TextButton(onClick = { previewPaper = null }) { Text("Cancel") }
                }
            }
        )
    }
}

@Composable
fun DocumentsScreen(
    documents: List<ContributedDocument>,
    onContributeNew: () -> Unit,
    onBack: () -> Unit
) {
    Scaffold(
        topBar = { MindoraTopBar(title = "My contributions", onBack = onBack) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(documents, key = { it.id }) { doc ->
                AppSurface {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = doc.title,
                                style = MaterialTheme.typography.titleMedium,
                                modifier = Modifier.weight(1f)
                            )
                            AppBadge(
                                label = if (doc.status == "approved") "APPROVED · +${doc.creditsAwarded}" else "REVIEW",
                                tone = if (doc.status == "approved") BadgeTone.SUCCESS else BadgeTone.WARNING
                            )
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "${doc.subject} · ${doc.examSystem} ${doc.examLevel} · ${doc.fileName}",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = doc.description,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
            item {
                OutlinedButton(
                    onClick = onContributeNew,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("+ Contribute another document")
                }
            }
        }
    }
}

@Composable
fun ContributeDocumentScreen(
    onSubmit: (title: String, subject: String, system: String, level: String, description: String, content: String, fileName: String) -> Unit,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    var title by remember { mutableStateOf("") }
    var subject by remember { mutableStateOf("Mathematics") }
    var system by remember { mutableStateOf("GCE") }
    var level by remember { mutableStateOf("A-Level") }
    var description by remember { mutableStateOf("") }
    var content by remember { mutableStateOf("") }
    var pickedFileName by remember { mutableStateOf("") }

    val filePicker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri: Uri? ->
        if (uri != null) {
            pickedFileName = uri.lastPathSegment?.substringAfterLast('/') ?: "selected_document.pdf"
            try {
                context.contentResolver.openInputStream(uri)?.use { stream ->
                    val snippet = stream.bufferedReader().readText().take(2000)
                    if (snippet.isNotBlank() && content.isBlank()) {
                        content = snippet
                    }
                }
            } catch (_: Exception) {
            }
        }
    }

    val wordCount = description.trim().split(Regex("\\s+")).count { it.isNotEmpty() }

    Scaffold(
        topBar = { MindoraTopBar(title = "Contribute document", onBack = onBack) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            item {
                OutlinedButton(
                    onClick = { filePicker.launch(arrayOf("application/pdf", "text/plain", "*/*")) },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(Icons.Outlined.UploadFile, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(if (pickedFileName.isBlank()) "Pick PDF or text file (optional)" else "Selected: $pickedFileName")
                }
            }

            item {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Document title") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            item {
                Text("Subject", style = MaterialTheme.typography.labelLarge)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("Mathematics", "Physics", "Chemistry", "Computer Science").forEach { s ->
                        FilterChip(
                            selected = subject == s,
                            onClick = { subject = s },
                            label = { Text(s) }
                        )
                    }
                }
            }

            item {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("GCE" to "A-Level", "Francophone" to "Bac").forEach { (sys, lvl) ->
                        FilterChip(
                            selected = system == sys,
                            onClick = { system = sys; level = lvl },
                            label = { Text("$sys ($lvl)") }
                        )
                    }
                }
            }

            item {
                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text("Description ($wordCount words)") },
                    minLines = 2,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            item {
                OutlinedTextField(
                    value = content,
                    onValueChange = { content = it },
                    label = { Text("Key notes / summary text (indexed for AI Tutor RAG)") },
                    minLines = 4,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            item {
                Button(
                    onClick = {
                        onSubmit(title, subject, system, level, description, content, pickedFileName)
                    },
                    enabled = title.trim().length >= 3 && (description.isNotBlank() || content.isNotBlank()),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp)
                ) {
                    Text("Submit & earn +5 credits")
                }
            }
        }
    }
}
