package com.mindora.app.ui.screens

import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
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
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.FolderCopy
import androidx.compose.material.icons.outlined.PictureAsPdf
import androidx.compose.material.icons.outlined.Quiz
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Style
import androidx.compose.material.icons.outlined.UploadFile
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.mindora.app.data.AppLanguage
import com.mindora.app.data.ContributedDocument
import com.mindora.app.data.PastPaper
import com.mindora.app.ui.components.AppBadge
import com.mindora.app.ui.components.AppEmptyState
import com.mindora.app.ui.components.AppSurface
import com.mindora.app.ui.components.BadgeTone
import com.mindora.app.ui.components.MindoraTopBar
import com.mindora.app.ui.theme.MindoraPalette
import kotlinx.coroutines.launch
import java.io.File

@Composable
fun LearnHubScreen(
    language: AppLanguage,
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
    val isFr = language == AppLanguage.FR
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
                            Text(
                                if (isFr) "Crédits de téléchargement" else "Download credits",
                                style = MaterialTheme.typography.titleMedium
                            )
                            Text(
                                text = if (isFr) "Gagne +5 crédits pour chaque document approuvé."
                                else "Earn 5 credits for each approved document contribution.",
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
                    title = if (isFr) "Annales & Sujets (PDF)" else "Past Papers",
                    subtitle = if (isFr) "$papersCount sujets · GCE, BEPC, Bac (visionneuse PDF)"
                    else "$papersCount exam papers · GCE, BEPC, Bac PDF library",
                    onClick = onOpenPastPapers
                )
            }
            item {
                LearnHubTile(
                    icon = Icons.Outlined.Style,
                    iconTint = MaterialTheme.colorScheme.primary,
                    title = "Flashcards",
                    subtitle = if (isFr) "$decksCount paquets · Répétition espacée SM-2"
                    else "$decksCount decks · SM-2 spaced repetition review",
                    onClick = onOpenFlashcards
                )
            }
            item {
                LearnHubTile(
                    icon = Icons.Outlined.Quiz,
                    iconTint = MindoraPalette.Accent500,
                    title = if (isFr) "Examens Blancs" else "Mock Exams",
                    subtitle = if (isFr) "$examsCount examens · Correction serveur & analyse"
                    else "$examsCount exams · Timed practice & server grading",
                    onClick = onOpenMockExams
                )
            }
            item {
                LearnHubTile(
                    icon = Icons.Outlined.UploadFile,
                    iconTint = MindoraPalette.Success,
                    title = if (isFr) "Partager un document" else "Contribute a document",
                    subtitle = if (isFr) "Partage tes fiches PDF ou notes (+5 crédits)"
                    else "Upload course notes or study guides (+5 credits)",
                    onClick = onOpenContribute
                )
            }
            item {
                LearnHubTile(
                    icon = Icons.Outlined.FolderCopy,
                    iconTint = MaterialTheme.colorScheme.primary,
                    title = if (isFr) "Mes contributions" else "My contributions",
                    subtitle = if (isFr) "$docsCount documents indexés pour le Tuteur IA"
                    else "$docsCount documents indexed for AI Tutor search",
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
    language: AppLanguage,
    papers: List<PastPaper>,
    loading: Boolean,
    onDownloadPaper: suspend (PastPaper) -> Result<File>,
    onBack: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    var search by remember { mutableStateOf("") }
    var selectedSystem by remember { mutableStateOf<String?>(null) }
    var selectedLevel by remember { mutableStateOf<String?>(null) }
    var viewingFile by remember { mutableStateOf<Pair<PastPaper, File>?>(null) }
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    val filtered = papers.filter { p ->
        val matchesQuery = search.isBlank() ||
            p.title.contains(search, ignoreCase = true) ||
            p.subject.contains(search, ignoreCase = true) ||
            p.fileName.contains(search, ignoreCase = true)
        val matchesSys = selectedSystem == null || p.examSystem.contains(selectedSystem!!, ignoreCase = true)
        val matchesLvl = selectedLevel == null || p.examLevel.contains(selectedLevel!!, ignoreCase = true)
        matchesQuery && matchesSys && matchesLvl
    }

    Scaffold(
        topBar = { MindoraTopBar(title = if (isFr) "Annales PDF" else "Past Papers", onBack = onBack) },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp)) {
                OutlinedTextField(
                    value = search,
                    onValueChange = { search = it },
                    leadingIcon = { Icon(Icons.Outlined.Search, contentDescription = null) },
                    placeholder = { Text(if (isFr) "Rechercher matière ou sujet..." else "Search subject or title...") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf(
                        null to (if (isFr) "Tous" else "All"),
                        "GCE" to "GCE",
                        "Francophone" to "Francophone"
                    ).forEach { (v, label) ->
                        FilterChip(
                            selected = selectedSystem == v,
                            onClick = { selectedSystem = v },
                            label = { Text(label) }
                        )
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf(
                        null to (if (isFr) "Tous" else "All"),
                        "O-Level" to "O-Level",
                        "A-Level" to "A-Level",
                        "BEPC" to "BEPC",
                        "Bac" to "Bac"
                    ).forEach { (v, label) ->
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
                        title = if (isFr) "Aucun sujet trouvé" else "No past papers found",
                        message = if (isFr) "Essaie d'ajuster les filtres." else "Try adjusting the search or filters."
                    )
                }
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(filtered, key = { it.id }) { paper ->
                        val openPaper: () -> Unit = {
                            scope.launch {
                                onDownloadPaper(paper)
                                    .onSuccess { file -> viewingFile = paper to file }
                                    .onFailure { err ->
                                        snackbarHostState.showSnackbar(err.message ?: "Download failed")
                                    }
                            }
                        }
                        AppSurface(onClick = openPaper) {
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
                                if (paper.localFilePath != null) {
                                    AppBadge(label = "PDF READY", tone = BadgeTone.SUCCESS)
                                } else {
                                    IconButton(onClick = openPaper, enabled = !loading) {
                                        Icon(Icons.Outlined.Download, contentDescription = "Download & view")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    viewingFile?.let { (paper, file) ->
        PdfViewerDialog(
            title = paper.title,
            file = file,
            isFr = isFr,
            onDismiss = { viewingFile = null }
        )
    }
}

@Composable
private fun PdfViewerDialog(
    title: String,
    file: File,
    isFr: Boolean,
    onDismiss: () -> Unit
) {
    var pageIndex by remember { mutableIntStateOf(0) }
    var pageCount by remember { mutableIntStateOf(0) }
    var renderedBitmap by remember { mutableStateOf<Bitmap?>(null) }
    var renderError by remember { mutableStateOf<String?>(null) }

    val holder = remember(file.absolutePath) {
        runCatching {
            val pfd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
            val renderer = PdfRenderer(pfd)
            pageCount = renderer.pageCount
            pfd to renderer
        }.getOrNull()
    }

    DisposableEffect(file.absolutePath) {
        onDispose {
            holder?.second?.close()
            holder?.first?.close()
        }
    }

    DisposableEffect(holder, pageIndex) {
        if (holder == null) {
            renderError = if (isFr) "Fichier non valide ou aperçu impossible." else "Cannot preview PDF on this device."
        } else if (pageIndex in 0 until holder.second.pageCount) {
            runCatching {
                holder.second.openPage(pageIndex).use { page ->
                    val width = (page.width * 2).coerceAtLeast(720)
                    val height = (page.height * 2).coerceAtLeast(1000)
                    val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    bmp.eraseColor(android.graphics.Color.WHITE)
                    page.render(bmp, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                    renderedBitmap = bmp
                }
            }.onFailure {
                renderError = it.message
            }
        }
        onDispose {}
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(
            modifier = Modifier.fillMaxSize().padding(12.dp),
            shape = RoundedCornerShape(16.dp),
            color = MaterialTheme.colorScheme.surface
        ) {
            Column(modifier = Modifier.fillMaxSize().padding(14.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = title,
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.weight(1f)
                    )
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Outlined.Close, contentDescription = "Close")
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .background(MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(12.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    val bmp = renderedBitmap
                    when {
                        bmp != null -> Image(
                            bitmap = bmp.asImageBitmap(),
                            contentDescription = "PDF page",
                            contentScale = ContentScale.Fit,
                            modifier = Modifier.fillMaxSize().padding(4.dp)
                        )
                        renderError != null -> Text(
                            text = renderError!!,
                            style = MaterialTheme.typography.bodyMedium,
                            modifier = Modifier.padding(16.dp)
                        )
                        else -> CircularProgressIndicator()
                    }
                }
                Spacer(modifier = Modifier.height(10.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedButton(
                        onClick = { if (pageIndex > 0) pageIndex-- },
                        enabled = pageIndex > 0
                    ) {
                        Text(if (isFr) "Précédente" else "Previous")
                    }
                    Text(
                        text = if (pageCount > 0) "${pageIndex + 1} / $pageCount" else "1 / 1",
                        style = MaterialTheme.typography.labelLarge
                    )
                    Button(
                        onClick = { if (pageIndex < pageCount - 1) pageIndex++ },
                        enabled = pageIndex < pageCount - 1
                    ) {
                        Text(if (isFr) "Suivante" else "Next")
                    }
                }
            }
        }
    }
}

@Composable
fun DocumentsScreen(
    language: AppLanguage,
    documents: List<ContributedDocument>,
    onContributeNew: () -> Unit,
    onBack: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    Scaffold(
        topBar = { MindoraTopBar(title = if (isFr) "Mes contributions" else "My contributions", onBack = onBack) }
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
                                label = if (doc.status == "approved") "APPROVED · +${doc.creditsAwarded}" else doc.status.uppercase(),
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
                    Text(if (isFr) "+ Partager un autre document" else "+ Contribute another document")
                }
            }
        }
    }
}

@Composable
fun ContributeDocumentScreen(
    language: AppLanguage,
    loading: Boolean,
    onSubmit: suspend (
        title: String,
        subject: String,
        system: String,
        level: String,
        description: String,
        fileBytes: ByteArray,
        fileName: String,
        mimeType: String
    ) -> Unit,
    onBack: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var title by remember { mutableStateOf("") }
    var subject by remember { mutableStateOf("Mathematics") }
    var system by remember { mutableStateOf("GCE") }
    var level by remember { mutableStateOf("A-Level") }
    var description by remember { mutableStateOf("") }
    var content by remember { mutableStateOf("") }
    var pickedFileName by remember { mutableStateOf("") }
    var pickedBytes by remember { mutableStateOf<ByteArray?>(null) }
    var pickedMime by remember { mutableStateOf("text/plain") }

    val filePicker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri: Uri? ->
        if (uri != null) {
            val resolvedName = runCatching {
                context.contentResolver.query(uri, null, null, null, null)?.use { c ->
                    val idx = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (c.moveToFirst() && idx >= 0) c.getString(idx) else null
                }
            }.getOrNull() ?: uri.lastPathSegment?.substringAfterLast('/') ?: "document.pdf"

            pickedFileName = resolvedName
            pickedMime = context.contentResolver.getType(uri) ?: "application/pdf"
            runCatching {
                context.contentResolver.openInputStream(uri)?.use { stream ->
                    pickedBytes = stream.readBytes()
                }
            }
        }
    }

    val wordCount = description.trim().split(Regex("\\s+")).count { it.isNotEmpty() }

    Scaffold(
        topBar = { MindoraTopBar(title = if (isFr) "Partager un document" else "Contribute document", onBack = onBack) }
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
                    onClick = { filePicker.launch(arrayOf("application/pdf", "text/plain", "image/*")) },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(Icons.Outlined.UploadFile, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        if (pickedFileName.isBlank()) {
                            if (isFr) "Choisir un PDF ou fichier texte (optionnel)" else "Pick PDF or text file (optional)"
                        } else "${if (isFr) "Sélectionné" else "Selected"}: $pickedFileName"
                    )
                }
            }

            item {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text(if (isFr) "Titre du document" else "Document title") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            item {
                Text(if (isFr) "Matière" else "Subject", style = MaterialTheme.typography.labelLarge)
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
                    label = { Text("Description ($wordCount ${if (isFr) "mots" else "words"})") },
                    minLines = 2,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            item {
                OutlinedTextField(
                    value = content,
                    onValueChange = { content = it },
                    label = {
                        Text(
                            if (isFr) "Notes / résumé texte (si pas de PDF joint)"
                            else "Key notes / summary text (if no PDF selected)"
                        )
                    },
                    minLines = 4,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            item {
                Button(
                    onClick = {
                        val finalBytes = pickedBytes ?: buildString {
                            appendLine(title.trim())
                            if (description.isNotBlank()) appendLine(description.trim())
                            if (content.isNotBlank()) appendLine(content.trim())
                        }.toByteArray(Charsets.UTF_8)
                        val finalName = pickedFileName.ifBlank {
                            "${title.trim().lowercase().replace(Regex("[^a-z0-9]+"), "_")}.txt"
                        }
                        val finalMime = if (pickedBytes != null) pickedMime else "text/plain"
                        scope.launch {
                            onSubmit(title, subject, system, level, description, finalBytes, finalName, finalMime)
                        }
                    },
                    enabled = !loading && title.trim().length >= 3 && (pickedBytes != null || description.isNotBlank() || content.isNotBlank()),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp)
                ) {
                    if (loading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            strokeWidth = 2.dp,
                            color = MaterialTheme.colorScheme.onPrimary
                        )
                    } else {
                        Text(if (isFr) "Envoyer et gagner +5 crédits" else "Submit & earn +5 credits")
                    }
                }
            }
        }
    }
}
