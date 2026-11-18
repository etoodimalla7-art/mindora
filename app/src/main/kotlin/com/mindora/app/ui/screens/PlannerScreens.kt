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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.outlined.CalendarToday
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Event
import androidx.compose.material.icons.outlined.MenuBook
import androidx.compose.material.icons.outlined.RadioButtonUnchecked
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.mindora.app.data.SeedCatalog
import com.mindora.app.data.StudyPlan
import com.mindora.app.data.StudySession
import com.mindora.app.ui.components.AppBadge
import com.mindora.app.ui.components.AppEmptyState
import com.mindora.app.ui.components.AppSurface
import com.mindora.app.ui.components.BadgeTone
import com.mindora.app.ui.components.MindoraTopBar
import com.mindora.app.ui.theme.MindoraPalette
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt

@Composable
fun PlannerScreen(
    plans: List<StudyPlan>,
    onOpenPlan: (String) -> Unit,
    onCreatePlan: () -> Unit
) {
    Scaffold(
        topBar = { MindoraTopBar(showWordmark = true) },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = onCreatePlan,
                icon = { Icon(Icons.Default.Add, contentDescription = null) },
                text = { Text("New plan") }
            )
        }
    ) { padding ->
        if (plans.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentAlignment = Alignment.Center
            ) {
                AppEmptyState(
                    icon = Icons.Outlined.CalendarToday,
                    title = "No study plan yet",
                    message = "Tell us what examination you are preparing for and we will build your personalized roadmap.",
                    actionLabel = "Create study plan",
                    onAction = onCreatePlan
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentPadding = PaddingValues(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(plans, key = { it.id }) { plan ->
                    val isExam = plan.planType == "exam"
                    val completedCount = plan.sessions.count { it.isCompleted }
                    val formattedDate = SimpleDateFormat("MMM d, yyyy", Locale.getDefault())
                        .format(Date(plan.targetDateMillis))
                    AppSurface(onClick = { onOpenPlan(plan.id) }) {
                        Column(modifier = Modifier.padding(18.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .size(40.dp)
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.10f)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        imageVector = if (isExam) Icons.Outlined.Event else Icons.Outlined.MenuBook,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                                Spacer(modifier = Modifier.width(12.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(plan.title, style = MaterialTheme.typography.titleMedium)
                                    Text(
                                        text = if (isExam) "Exam plan · ${plan.subject}" else "Subject plan · ${plan.subject}",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                                AppBadge(
                                    label = if (isExam) "EXAM" else "SUBJECT",
                                    tone = if (isExam) BadgeTone.PRIMARY else BadgeTone.INFO
                                )
                            }
                            Spacer(modifier = Modifier.height(14.dp))
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    imageVector = Icons.Outlined.Schedule,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = "${plan.daysRemaining} days left · $formattedDate · $completedCount/${plan.sessions.size} done",
                                    style = MaterialTheme.typography.bodySmall,
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

@Composable
fun PlanDetailScreen(
    plan: StudyPlan?,
    onCompleteSession: (String) -> Unit,
    onStartSession: (String) -> Unit,
    onBack: () -> Unit
) {
    Scaffold(
        topBar = { MindoraTopBar(title = "Plan", onBack = onBack) }
    ) { padding ->
        if (plan == null) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text("Study plan not found.")
            }
            return@Scaffold
        }
        val formattedDate = SimpleDateFormat("MMM d, yyyy", Locale.getDefault()).format(Date(plan.targetDateMillis))
        val upcoming = plan.sessions.filter { !it.isCompleted }
        val completed = plan.sessions.filter { it.isCompleted }

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                Text(plan.title, style = MaterialTheme.typography.headlineSmall)
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "${plan.daysRemaining} days remaining · $formattedDate · ${plan.dailyMinutes} min/day",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text("Roadmap", style = MaterialTheme.typography.titleMedium)
            }

            if (upcoming.isEmpty()) {
                item {
                    AppEmptyState(
                        icon = Icons.Outlined.CheckCircle,
                        title = "All sessions complete",
                        message = "Great work! Create another study plan to keep progressing."
                    )
                }
            } else {
                items(upcoming, key = { it.id }) { s ->
                    SessionRowCard(
                        session = s,
                        onComplete = { onCompleteSession(s.id) },
                        onOpen = { onStartSession(s.id) }
                    )
                }
            }

            if (completed.isNotEmpty()) {
                item {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("Completed", style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                items(completed, key = { it.id }) { s ->
                    SessionRowCard(
                        session = s,
                        onComplete = {},
                        onOpen = {}
                    )
                }
            }
        }
    }
}

@Composable
private fun SessionRowCard(
    session: StudySession,
    onComplete: () -> Unit,
    onOpen: () -> Unit
) {
    val dateLabel = SimpleDateFormat("MMM d", Locale.getDefault()).format(Date(session.scheduledForMillis))
    val timeLabel = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(session.scheduledForMillis))
    AppSurface(onClick = if (session.isCompleted) null else onOpen) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.width(56.dp)) {
                Text(dateLabel, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(timeLabel, style = MaterialTheme.typography.titleSmall)
            }
            Spacer(modifier = Modifier.width(10.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(session.title, style = MaterialTheme.typography.bodyMedium)
                Text(
                    "${session.subject} · ${session.durationMinutes} min",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            IconButton(onClick = onComplete, enabled = !session.isCompleted) {
                Icon(
                    imageVector = if (session.isCompleted) Icons.Outlined.CheckCircle else Icons.Outlined.RadioButtonUnchecked,
                    contentDescription = "Mark completed",
                    tint = if (session.isCompleted) MindoraPalette.Success else MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreatePlanScreen(
    onCreate: (planType: String, title: String, subject: String, system: String, level: String, targetDays: Int, dailyMinutes: Int) -> Unit,
    onBack: () -> Unit
) {
    var planType by remember { mutableStateOf("exam") }
    var title by remember { mutableStateOf("GCE A-Level Revision") }
    var subject by remember { mutableStateOf("Mathematics") }
    var system by remember { mutableStateOf("GCE") }
    var level by remember { mutableStateOf("Advanced Level") }
    var targetDays by remember { mutableIntStateOf(30) }
    var dailyMinutes by remember { mutableFloatStateOf(45f) }
    var subjectExpanded by remember { mutableStateOf(false) }

    val subjects = SeedCatalog.subjectTopics.keys.toList()

    Scaffold(
        topBar = { MindoraTopBar(title = "Create study plan", onBack = onBack) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                Text("Plan type", style = MaterialTheme.typography.labelLarge)
                Spacer(modifier = Modifier.height(6.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    FilterChip(
                        selected = planType == "exam",
                        onClick = { planType = "exam" },
                        label = { Text("Exam Plan") }
                    )
                    FilterChip(
                        selected = planType == "subject",
                        onClick = { planType = "subject" },
                        label = { Text("Subject Mastery") }
                    )
                }
            }

            item {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Plan title") },
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
                        modifier = Modifier
                            .menuAnchor()
                            .fillMaxWidth()
                    )
                    ExposedDropdownMenu(
                        expanded = subjectExpanded,
                        onDismissRequest = { subjectExpanded = false }
                    ) {
                        subjects.forEach { s ->
                            DropdownMenuItem(
                                text = { Text(s) },
                                onClick = {
                                    subject = s
                                    subjectExpanded = false
                                }
                            )
                        }
                    }
                }
            }

            item {
                Text("System & Level", style = MaterialTheme.typography.labelLarge)
                Spacer(modifier = Modifier.height(6.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    FilterChip(
                        selected = system == "GCE",
                        onClick = { system = "GCE"; level = "Advanced Level" },
                        label = { Text("GCE") }
                    )
                    FilterChip(
                        selected = system == "Francophone",
                        onClick = { system = "Francophone"; level = "Baccalauréat" },
                        label = { Text("Francophone") }
                    )
                }
            }

            item {
                Text("Target horizon: $targetDays days", style = MaterialTheme.typography.labelLarge)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf(14, 30, 45, 60).forEach { d ->
                        FilterChip(
                            selected = targetDays == d,
                            onClick = { targetDays = d },
                            label = { Text("${d}d") }
                        )
                    }
                }
            }

            item {
                Text("Daily study time: ${dailyMinutes.roundToInt()} min", style = MaterialTheme.typography.labelLarge)
                Slider(
                    value = dailyMinutes,
                    onValueChange = { dailyMinutes = it },
                    valueRange = 15f..120f,
                    steps = 6
                )
            }

            item {
                Button(
                    onClick = {
                        onCreate(
                            planType,
                            title.ifBlank { "$subject Study Plan" },
                            subject,
                            system,
                            level,
                            targetDays,
                            dailyMinutes.roundToInt()
                        )
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp)
                ) {
                    Text("Generate personalized roadmap")
                }
            }
        }
    }
}
