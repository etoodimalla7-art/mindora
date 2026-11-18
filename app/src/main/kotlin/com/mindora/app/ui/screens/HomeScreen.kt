package com.mindora.app.ui.screens

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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.CalendarToday
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.PlayArrow
import androidx.compose.material.icons.outlined.Quiz
import androidx.compose.material.icons.outlined.Style
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material.icons.outlined.TrendingDown
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.mindora.app.data.MindoraState
import com.mindora.app.data.StudySession
import com.mindora.app.ui.components.AppAvatar
import com.mindora.app.ui.components.AppBadge
import com.mindora.app.ui.components.AppProgressRing
import com.mindora.app.ui.components.AppSurface
import com.mindora.app.ui.components.BadgeTone
import com.mindora.app.ui.components.MindoraTopBar
import com.mindora.app.ui.theme.MindoraPalette
import kotlinx.coroutines.delay
import java.util.Calendar
import kotlin.math.roundToInt

@Composable
fun HomeScreen(
    state: MindoraState,
    onStartSession: (String) -> Unit,
    onOpenAi: () -> Unit,
    onOpenMockExams: () -> Unit,
    onOpenFlashcards: () -> Unit,
    onOpenPlanner: () -> Unit,
    onOpenPastPapers: () -> Unit,
    onOpenStudyGroups: () -> Unit
) {
    val dashboard = remember(state.plans, state.streakDays, state.decks, state.mockExams) {
        state.buildDashboard()
    }
    val hour = remember { Calendar.getInstance().get(Calendar.HOUR_OF_DAY) }
    val greeting = when {
        hour < 12 -> "Good morning"
        hour < 18 -> "Good afternoon"
        else -> "Good evening"
    }
    val firstName = state.profile.fullName.split(" ").firstOrNull().orEmpty().ifBlank { "student" }

    Scaffold(
        topBar = { MindoraTopBar(showWordmark = true) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "$greeting \uD83D\uDC4B",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = "Welcome, $firstName",
                            style = MaterialTheme.typography.headlineSmall
                        )
                    }
                    AppAvatar(name = firstName, size = 44.dp)
                }
            }

            dashboard.examCountdown?.let { countdown ->
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
                                    .size(56.dp)
                                    .clip(RoundedCornerShape(16.dp))
                                    .background(MaterialTheme.colorScheme.primary),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = "${countdown.daysRemaining}",
                                    style = MaterialTheme.typography.titleLarge,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onPrimary
                                )
                            }
                            Spacer(modifier = Modifier.width(16.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "Your next examination",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Spacer(modifier = Modifier.height(2.dp))
                                Text(
                                    text = countdown.examName,
                                    style = MaterialTheme.typography.titleMedium,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Spacer(modifier = Modifier.height(2.dp))
                                Text(
                                    text = "${countdown.daysRemaining} days remaining",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.primary,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                        }
                    }
                }
            }

            item {
                AppSurface {
                    Row(
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 14.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(RoundedCornerShape(12.dp))
                                .background(MindoraPalette.Accent500.copy(alpha = 0.14f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.LocalFireDepartment,
                                contentDescription = null,
                                tint = MindoraPalette.Accent500
                            )
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Column {
                            Text(
                                text = "${dashboard.streakDays} ${if (dashboard.streakDays == 1) "day" else "days"}",
                                style = MaterialTheme.typography.titleMedium
                            )
                            Text(
                                text = "Study streak",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }

            dashboard.todayFocus?.let { focus ->
                item {
                    Text("Today's focus", style = MaterialTheme.typography.titleMedium)
                    Spacer(modifier = Modifier.height(10.dp))
                    AppSurface {
                        Column(modifier = Modifier.padding(18.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .size(34.dp)
                                        .clip(RoundedCornerShape(10.dp))
                                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        imageVector = Icons.Outlined.PlayArrow,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                                Spacer(modifier = Modifier.width(10.dp))
                                Text(
                                    text = focus.title,
                                    style = MaterialTheme.typography.titleMedium,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                    modifier = Modifier.weight(1f)
                                )
                                AppBadge(label = "${focus.durationMinutes} min", tone = BadgeTone.PRIMARY)
                            }
                            Spacer(modifier = Modifier.height(10.dp))
                            Text(
                                text = "${focus.subject} · ${focus.topic}",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = focus.objective,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                maxLines = 2,
                                overflow = TextOverflow.Ellipsis
                            )
                            Spacer(modifier = Modifier.height(14.dp))
                            Button(
                                onClick = { onStartSession(focus.sessionId) },
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Icon(Icons.Outlined.PlayArrow, contentDescription = null, modifier = Modifier.size(18.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Start session")
                            }
                        }
                    }
                }
            }

            item {
                AppSurface {
                    Column(modifier = Modifier.padding(18.dp)) {
                        Text("Exam readiness", style = MaterialTheme.typography.titleMedium)
                        Text(
                            text = "An estimate based on sessions, quizzes, and retention",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            AppProgressRing(
                                progress = dashboard.readinessScore / 100f,
                                centerLabel = "${dashboard.readinessScore}%"
                            )
                            Spacer(modifier = Modifier.width(20.dp))
                            Column(
                                modifier = Modifier.weight(1f),
                                verticalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                ReadinessBarRow("Knowledge", dashboard.readinessBreakdown.knowledge)
                                ReadinessBarRow("Practice", dashboard.readinessBreakdown.practice)
                                ReadinessBarRow("Retention", dashboard.readinessBreakdown.retention)
                                ReadinessBarRow("Consistency", dashboard.readinessBreakdown.consistency)
                            }
                        }
                    }
                }
            }

            if (dashboard.weakTopics.isNotEmpty()) {
                item {
                    AppSurface {
                        Column(
                            modifier = Modifier.padding(18.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    imageVector = Icons.Outlined.TrendingDown,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.error,
                                    modifier = Modifier.size(18.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Weak topics", style = MaterialTheme.typography.titleMedium)
                            }
                            dashboard.weakTopics.forEach { t ->
                                Column {
                                    Row(modifier = Modifier.fillMaxWidth()) {
                                        Text(
                                            text = t.topic,
                                            style = MaterialTheme.typography.bodyMedium,
                                            modifier = Modifier.weight(1f)
                                        )
                                        Text(
                                            text = "${(t.mastery * 100).roundToInt()}%",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                    Text(
                                        text = t.subject,
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    Spacer(modifier = Modifier.height(6.dp))
                                    LinearProgressIndicator(
                                        progress = { t.mastery },
                                        color = MaterialTheme.colorScheme.error,
                                        trackColor = MaterialTheme.colorScheme.surfaceVariant,
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .height(4.dp)
                                            .clip(RoundedCornerShape(999.dp))
                                    )
                                }
                            }
                        }
                    }
                }
            }

            if (dashboard.recentActivity.isNotEmpty()) {
                item {
                    AppSurface {
                        Column(
                            modifier = Modifier.padding(18.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Text("Recent activity", style = MaterialTheme.typography.titleMedium)
                            dashboard.recentActivity.forEach { a ->
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Box(
                                        modifier = Modifier
                                            .size(32.dp)
                                            .clip(RoundedCornerShape(8.dp))
                                            .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Icon(
                                            imageVector = Icons.Outlined.Check,
                                            contentDescription = null,
                                            tint = MaterialTheme.colorScheme.primary,
                                            modifier = Modifier.size(16.dp)
                                        )
                                    }
                                    Spacer(modifier = Modifier.width(12.dp))
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(a.title, style = MaterialTheme.typography.bodyMedium)
                                        Text(
                                            a.subject,
                                            style = MaterialTheme.typography.labelSmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                    Text(
                                        "${a.durationMinutes} min",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }
                    }
                }
            }

            item {
                Text("Quick actions", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(10.dp))
                val actions = listOf(
                    Triple(Icons.Outlined.AutoAwesome, "Ask AI", onOpenAi),
                    Triple(Icons.Outlined.Quiz, "Mock exams", onOpenMockExams),
                    Triple(Icons.Outlined.Style, "Flashcards", onOpenFlashcards),
                    Triple(Icons.Outlined.CalendarToday, "Open planner", onOpenPlanner),
                    Triple(Icons.Outlined.Description, "Past papers", onOpenPastPapers),
                    Triple(Icons.Outlined.Groups, "Study groups", onOpenStudyGroups)
                )
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    actions.chunked(2).forEach { pair ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            pair.forEach { (icon, label, onClick) ->
                                QuickActionCard(
                                    icon = icon,
                                    label = label,
                                    onClick = onClick,
                                    modifier = Modifier.weight(1f)
                                )
                            }
                        }
                    }
                }
                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }
}

@Composable
private fun ReadinessBarRow(label: String, value: Float) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = "${(value * 100).roundToInt()}%",
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.primary
        )
    }
}

@Composable
private fun QuickActionCard(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    AppSurface(modifier = modifier, onClick = onClick) {
        Row(
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(10.dp))
            Text(
                text = label,
                style = MaterialTheme.typography.labelLarge,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

@Composable
fun StudySessionFocusScreen(
    session: StudySession?,
    onComplete: (String) -> Unit,
    onBack: () -> Unit
) {
    if (session == null) {
        Scaffold(topBar = { MindoraTopBar(title = "Study session", onBack = onBack) }) { padding ->
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text("Session not found.")
            }
        }
        return
    }

    var remainingSeconds by remember(session.id) { mutableIntStateOf(session.durationMinutes * 60) }
    var running by remember { mutableStateOf(true) }

    LaunchedEffect(running) {
        while (running && remainingSeconds > 0) {
            delay(1000L)
            remainingSeconds--
        }
    }

    val mins = remainingSeconds / 60
    val secs = remainingSeconds % 60
    val totalSecs = (session.durationMinutes * 60).coerceAtLeast(1)
    val progress = 1f - (remainingSeconds.toFloat() / totalSecs.toFloat())

    Scaffold(
        topBar = { MindoraTopBar(title = "Study session", onBack = onBack) }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                AppBadge(label = session.subject, tone = BadgeTone.PRIMARY)
                Spacer(modifier = Modifier.height(10.dp))
                Text(session.title, style = MaterialTheme.typography.headlineSmall)
                Spacer(modifier = Modifier.height(6.dp))
                Text(
                    text = session.objective,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                AppProgressRing(
                    progress = progress,
                    size = 180.dp,
                    strokeWidth = 10.dp,
                    centerLabel = String.format("%02d:%02d", mins, secs)
                )
                Spacer(modifier = Modifier.height(16.dp))
                OutlinedButton(onClick = { running = !running }) {
                    Icon(Icons.Outlined.Timer, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(if (running) "Pause timer" else "Resume timer")
                }
            }

            Button(
                onClick = { onComplete(session.id) },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp)
            ) {
                Icon(Icons.Outlined.Check, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Mark session completed")
            }
        }
    }
}
