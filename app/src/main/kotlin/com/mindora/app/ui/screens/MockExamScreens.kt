package com.mindora.app.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
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
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.Cancel
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Grade
import androidx.compose.material.icons.outlined.Quiz
import androidx.compose.material.icons.outlined.RemoveCircleOutline
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.mindora.app.data.MockExam
import com.mindora.app.ui.components.AppBadge
import com.mindora.app.ui.components.AppEmptyState
import com.mindora.app.ui.components.AppProgressRing
import com.mindora.app.ui.components.AppSurface
import com.mindora.app.ui.components.BadgeTone
import com.mindora.app.ui.components.ConfirmDialog
import com.mindora.app.ui.components.MindoraTopBar
import com.mindora.app.ui.theme.MindoraPalette
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt

@Composable
fun MockExamsListScreen(
    exams: List<MockExam>,
    onCreateExam: () -> Unit,
    onTakeExam: (String) -> Unit,
    onViewResults: (String) -> Unit,
    onBack: () -> Unit
) {
    Scaffold(
        topBar = { MindoraTopBar(title = "Mock exams", onBack = onBack) },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = onCreateExam,
                icon = { Icon(Icons.Default.Add, contentDescription = null) },
                text = { Text("New exam") }
            )
        }
    ) { padding ->
        if (exams.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                AppEmptyState(
                    icon = Icons.Outlined.Quiz,
                    title = "No mock exams yet",
                    message = "Generate a personalized timed exam graded on the server.",
                    actionLabel = "Create your first exam",
                    onAction = onCreateExam
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentPadding = PaddingValues(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(exams, key = { it.id }) { exam ->
                    val (badgeText, badgeTone) = when (exam.status) {
                        "graded" -> "GRADED" to BadgeTone.SUCCESS
                        "in_progress" -> "IN PROGRESS" to BadgeTone.WARNING
                        else -> "READY" to BadgeTone.PRIMARY
                    }
                    val dateStr = SimpleDateFormat("MMM d, yyyy", Locale.getDefault()).format(Date(exam.createdAtMillis))
                    AppSurface(
                        onClick = {
                            if (exam.isGraded) onViewResults(exam.id) else onTakeExam(exam.id)
                        }
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = exam.title,
                                    style = MaterialTheme.typography.titleMedium,
                                    maxLines = 2,
                                    overflow = TextOverflow.Ellipsis,
                                    modifier = Modifier.weight(1f)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                AppBadge(label = badgeText, tone = badgeTone)
                            }
                            Spacer(modifier = Modifier.height(6.dp))
                            Text(
                                text = "${exam.subject} · ${exam.questionCount} questions · ${exam.durationMinutes} min",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                if (exam.isGraded && exam.score != null) {
                                    Icon(
                                        imageVector = Icons.Outlined.Grade,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(16.dp)
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(
                                        text = "${exam.score.roundToInt()}%",
                                        style = MaterialTheme.typography.labelMedium,
                                        color = MaterialTheme.colorScheme.primary,
                                        fontWeight = FontWeight.Bold
                                    )
                                    Spacer(modifier = Modifier.width(12.dp))
                                }
                                Text(
                                    text = dateStr,
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }
                item { Spacer(modifier = Modifier.height(72.dp)) }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateMockExamScreen(
    loading: Boolean,
    errorMessage: String?,
    onCreate: suspend (title: String, subject: String, level: String, difficulty: String, count: Int, minutes: Int) -> Unit,
    onBack: () -> Unit
) {
    val scope = rememberCoroutineScope()
    var title by remember { mutableStateOf("Practice exam") }
    var subject by remember { mutableStateOf("Mathematics") }
    var level by remember { mutableStateOf("GCE_AL") }
    var difficulty by remember { mutableStateOf("medium") }
    var questionCount by remember { mutableFloatStateOf(5f) }
    var durationMinutes by remember { mutableFloatStateOf(15f) }
    var subjectExpanded by remember { mutableStateOf(false) }

    val subjects = listOf("Mathematics", "Physics", "Computer Science", "Chemistry", "Biology", "Economics")
    val levels = listOf("GCE_OL", "GCE_AL", "BEPC", "BACCALAUREAT", "HND", "LICENCE")
    val difficulties = listOf("easy", "medium", "hard")

    Scaffold(
        topBar = { MindoraTopBar(title = "Create mock exam", onBack = onBack) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                Text("Configure your exam", style = MaterialTheme.typography.titleMedium)
                Text(
                    text = "Questions are generated on the server from approved course materials and graded server-side.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            item {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Exam title") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            item {
                ExposedDropdownMenuBox(
                    expanded = subjectExpanded,
                    onExpandedChange = { subjectExpanded = it }
                ) {
                    OutlinedTextField(
                        value = subject,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Subject") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = subjectExpanded) },
                        modifier = Modifier.menuAnchor().fillMaxWidth()
                    )
                    ExposedDropdownMenu(
                        expanded = subjectExpanded,
                        onDismissRequest = { subjectExpanded = false }
                    ) {
                        subjects.forEach { s ->
                            DropdownMenuItem(
                                text = { Text(s) },
                                onClick = { subject = s; subjectExpanded = false }
                            )
                        }
                    }
                }
            }

            item {
                Text("Academic level", style = MaterialTheme.typography.labelLarge)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    levels.take(4).forEach { lvl ->
                        FilterChip(
                            selected = level == lvl,
                            onClick = { level = lvl },
                            label = { Text(lvl.replace('_', ' ')) }
                        )
                    }
                }
            }

            item {
                Text("Difficulty", style = MaterialTheme.typography.labelLarge)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    difficulties.forEach { diff ->
                        FilterChip(
                            selected = difficulty == diff,
                            onClick = { difficulty = diff },
                            label = { Text(diff.replaceFirstChar { it.uppercase() }) }
                        )
                    }
                }
            }

            item {
                Text("Number of questions: ${questionCount.roundToInt()}", style = MaterialTheme.typography.labelLarge)
                Slider(
                    value = questionCount,
                    onValueChange = { questionCount = it },
                    valueRange = 3f..10f,
                    steps = 6
                )
                Text("Duration: ${durationMinutes.roundToInt()} min", style = MaterialTheme.typography.labelLarge)
                Slider(
                    value = durationMinutes,
                    onValueChange = { durationMinutes = it },
                    valueRange = 5f..60f,
                    steps = 10
                )
            }

            if (!errorMessage.isNullOrBlank()) {
                item {
                    Text(errorMessage, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                }
            }

            item {
                Button(
                    onClick = {
                        scope.launch {
                            onCreate(
                                title.ifBlank { "$subject Practice Exam" },
                                subject,
                                level,
                                difficulty,
                                questionCount.roundToInt(),
                                durationMinutes.roundToInt()
                            )
                        }
                    },
                    enabled = !loading,
                    modifier = Modifier.fillMaxWidth().height(52.dp)
                ) {
                    if (loading) {
                        CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp, color = MaterialTheme.colorScheme.onPrimary)
                    } else {
                        Icon(Icons.Outlined.AutoAwesome, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Generate exam")
                    }
                }
            }
        }
    }
}

@Composable
fun TakeMockExamScreen(
    examId: String,
    exam: MockExam?,
    loading: Boolean,
    onLoadDetail: suspend (String) -> Unit,
    onStartExam: suspend (String) -> Unit,
    onSelectAnswer: suspend (examId: String, questionId: String, answer: String) -> Unit,
    onSubmitExam: suspend (String) -> Unit,
    onBack: () -> Unit
) {
    val scope = rememberCoroutineScope()

    LaunchedEffect(examId) {
        onLoadDetail(examId)
    }

    if (exam == null || exam.questions.isEmpty()) {
        Scaffold(topBar = { MindoraTopBar(title = "Mock exam", onBack = onBack) }) { padding ->
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                if (loading) CircularProgressIndicator() else Text("Loading exam questions...")
            }
        }
        return
    }

    LaunchedEffect(exam.id, exam.status) {
        if (exam.isReady) onStartExam(exam.id)
    }

    var index by remember(exam.id) { mutableIntStateOf(0) }
    var remainingSeconds by remember(exam.id) { mutableIntStateOf(exam.durationMinutes * 60) }
    var showFinishConfirm by remember { mutableStateOf(false) }

    LaunchedEffect(exam.id) {
        while (remainingSeconds > 0) {
            delay(1000L)
            remainingSeconds--
            if (remainingSeconds == 0) {
                onSubmitExam(exam.id)
            }
        }
    }

    val q = exam.questions[index.coerceIn(0, exam.questions.lastIndex)]
    val total = exam.questions.size
    val isLast = index >= total - 1
    val selected = exam.answers[q.id]
    val mins = remainingSeconds / 60
    val secs = remainingSeconds % 60

    Scaffold(
        topBar = {
            MindoraTopBar(
                title = exam.title,
                onBack = onBack,
                actions = {
                    AppBadge(
                        label = String.format("%02d:%02d", mins, secs),
                        tone = if (remainingSeconds < 60) BadgeTone.DANGER else BadgeTone.PRIMARY
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            LinearProgressIndicator(
                progress = { (index + 1f) / total.toFloat() },
                modifier = Modifier.fillMaxWidth().height(4.dp)
            )
            LazyColumn(
                modifier = Modifier.weight(1f),
                contentPadding = PaddingValues(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                item {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Question ${index + 1} of $total",
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.primary
                        )
                        AppBadge(label = q.topic, tone = BadgeTone.NEUTRAL)
                    }
                    Spacer(modifier = Modifier.height(10.dp))
                    Text(text = q.prompt, style = MaterialTheme.typography.titleLarge)
                    Spacer(modifier = Modifier.height(8.dp))
                }

                if (q.options.isEmpty()) {
                    item {
                        OutlinedTextField(
                            value = selected.orEmpty(),
                            onValueChange = { ans ->
                                scope.launch { onSelectAnswer(exam.id, q.id, ans) }
                            },
                            label = { Text("Your answer") },
                            minLines = 2,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                } else {
                    items(q.options) { opt ->
                        val isChosen = selected.equals(opt.label, ignoreCase = true)
                        Surface(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    scope.launch { onSelectAnswer(exam.id, q.id, opt.label) }
                                },
                            shape = RoundedCornerShape(12.dp),
                            color = if (isChosen) MaterialTheme.colorScheme.primary.copy(alpha = 0.08f)
                            else MaterialTheme.colorScheme.surface,
                            border = BorderStroke(
                                width = if (isChosen) 1.5.dp else 1.dp,
                                color = if (isChosen) MaterialTheme.colorScheme.primary
                                else MaterialTheme.colorScheme.outline.copy(alpha = 0.6f)
                            )
                        ) {
                            Row(
                                modifier = Modifier.padding(14.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                RadioButton(
                                    selected = isChosen,
                                    onClick = { scope.launch { onSelectAnswer(exam.id, q.id, opt.label) } }
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = if (q.questionType == "mcq") "${opt.label}. ${opt.text}" else opt.text,
                                    style = MaterialTheme.typography.bodyLarge
                                )
                            }
                        }
                    }
                }
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedButton(
                    onClick = { if (index > 0) index-- },
                    enabled = index > 0 && !loading,
                    modifier = Modifier.weight(1f).height(50.dp)
                ) {
                    Text("Previous")
                }
                Button(
                    onClick = {
                        if (isLast) showFinishConfirm = true else index++
                    },
                    enabled = !loading,
                    modifier = Modifier.weight(1f).height(50.dp)
                ) {
                    if (isLast) {
                        Icon(Icons.Outlined.Check, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Submit & Grade")
                    } else {
                        Text("Next")
                        Spacer(modifier = Modifier.width(6.dp))
                        Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null, modifier = Modifier.size(18.dp))
                    }
                }
            }
        }
    }

    if (showFinishConfirm) {
        ConfirmDialog(
            title = "Submit exam?",
            message = "Your answers will be graded securely on the server.",
            confirmLabel = "Submit",
            onConfirm = {
                showFinishConfirm = false
                scope.launch { onSubmitExam(exam.id) }
            },
            onDismiss = { showFinishConfirm = false }
        )
    }
}

@Composable
fun MockExamResultsScreen(
    examId: String,
    exam: MockExam?,
    onLoadDetail: suspend (String) -> Unit,
    onBackToList: () -> Unit,
    onCreateNew: () -> Unit
) {
    LaunchedEffect(examId) {
        onLoadDetail(examId)
    }

    Scaffold(
        topBar = { MindoraTopBar(title = "Results", onBack = onBackToList) }
    ) { padding ->
        if (exam == null) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
            return@Scaffold
        }

        val score = exam.score ?: 0.0
        val isGood = score >= 60.0
        val ringColor = if (isGood) MindoraPalette.Success else MaterialTheme.colorScheme.primary
        val answersByQ = exam.answerResults.associateBy { it.questionId }

        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                AppSurface(containerColor = ringColor.copy(alpha = 0.08f)) {
                    Column(modifier = Modifier.padding(18.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            AppProgressRing(
                                progress = (score / 100.0).toFloat(),
                                size = 86.dp,
                                color = ringColor,
                                centerLabel = "${score.roundToInt()}%"
                            )
                            Spacer(modifier = Modifier.width(16.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(exam.title, style = MaterialTheme.typography.titleMedium)
                                Text(
                                    text = "${exam.subject} · ${exam.difficulty}",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                        Spacer(modifier = Modifier.height(14.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            AppBadge(label = "✓ ${exam.correctCount ?: 0} correct", tone = BadgeTone.SUCCESS)
                            AppBadge(label = "✗ ${exam.wrongCount ?: 0} wrong", tone = BadgeTone.DANGER)
                            if ((exam.skippedCount ?: 0) > 0) {
                                AppBadge(label = "— ${exam.skippedCount} skipped", tone = BadgeTone.NEUTRAL)
                            }
                        }
                    }
                }
            }

            if (!exam.feedbackSummary.isNullOrBlank()) {
                item {
                    AppSurface {
                        Text(
                            text = exam.feedbackSummary,
                            style = MaterialTheme.typography.bodyMedium,
                            modifier = Modifier.padding(16.dp)
                        )
                    }
                }
            }

            if (exam.topicBreakdown.isNotEmpty()) {
                item {
                    Text("Performance by topic", style = MaterialTheme.typography.titleMedium)
                    Spacer(modifier = Modifier.height(8.dp))
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        exam.topicBreakdown.forEach { (topic, stat) ->
                            val pct = stat.correct.toFloat() / stat.total.coerceAtLeast(1).toFloat()
                            Column {
                                Row(modifier = Modifier.fillMaxWidth()) {
                                    Text(topic, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
                                    Text("${stat.correct} / ${stat.total}", style = MaterialTheme.typography.labelSmall)
                                }
                                Spacer(modifier = Modifier.height(4.dp))
                                LinearProgressIndicator(
                                    progress = { pct },
                                    color = when {
                                        pct >= 0.6f -> MindoraPalette.Success
                                        pct >= 0.3f -> MindoraPalette.Warning
                                        else -> MindoraPalette.Danger
                                    },
                                    trackColor = MaterialTheme.colorScheme.surfaceVariant,
                                    modifier = Modifier.fillMaxWidth().height(5.dp).clip(RoundedCornerShape(999.dp))
                                )
                            }
                        }
                    }
                }
            }

            item {
                Text("Server-graded corrections", style = MaterialTheme.typography.titleMedium)
            }

            items(exam.questions, key = { it.id }) { q ->
                val res = answersByQ[q.id]
                val userAns = res?.userAnswer ?: exam.answers[q.id]
                val skipped = userAns.isNullOrBlank()
                val correct = res?.isCorrect == true
                val icon = when {
                    skipped -> Icons.Outlined.RemoveCircleOutline
                    correct -> Icons.Outlined.CheckCircle
                    else -> Icons.Outlined.Cancel
                }
                val color = when {
                    skipped -> MaterialTheme.colorScheme.onSurfaceVariant
                    correct -> MindoraPalette.Success
                    else -> MindoraPalette.Danger
                }
                AppSurface {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(verticalAlignment = Alignment.Top) {
                            Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(20.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Q${q.position}. ${q.prompt}",
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Your answer: ${userAns ?: "(skipped)"}",
                            style = MaterialTheme.typography.bodySmall,
                            color = color
                        )
                        val correctAns = res?.correctAnswer ?: q.correctAnswer
                        if (!correct && !correctAns.isNullOrBlank()) {
                            Text(
                                text = "Correct: $correctAns",
                                style = MaterialTheme.typography.bodySmall,
                                color = MindoraPalette.Success,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        val expl = res?.explanation ?: q.explanation
                        if (!expl.isNullOrBlank()) {
                            Spacer(modifier = Modifier.height(8.dp))
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = MaterialTheme.colorScheme.surfaceVariant
                            ) {
                                Text(
                                    text = expl,
                                    style = MaterialTheme.typography.bodySmall,
                                    modifier = Modifier.padding(10.dp)
                                )
                            }
                        }
                    }
                }
            }

            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    OutlinedButton(
                        onClick = onBackToList,
                        modifier = Modifier.weight(1f).height(50.dp)
                    ) { Text("Back to exams") }
                    Button(
                        onClick = onCreateNew,
                        modifier = Modifier.weight(1f).height(50.dp)
                    ) { Text("New exam") }
                }
                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }
}
