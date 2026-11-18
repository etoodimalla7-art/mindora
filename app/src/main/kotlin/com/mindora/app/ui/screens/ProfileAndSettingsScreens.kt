package com.mindora.app.ui.screens

import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.outlined.BrightnessAuto
import androidx.compose.material.icons.outlined.CardGiftcard
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material.icons.outlined.DarkMode
import androidx.compose.material.icons.outlined.FolderCopy
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.LightMode
import androidx.compose.material.icons.outlined.Public
import androidx.compose.material.icons.outlined.Quiz
import androidx.compose.material.icons.outlined.School
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.Style
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.mindora.app.data.AppLanguage
import com.mindora.app.data.MindoraState
import com.mindora.app.data.StudyGroup
import com.mindora.app.data.ThemeModeSetting
import com.mindora.app.ui.components.AppAvatar
import com.mindora.app.ui.components.AppBadge
import com.mindora.app.ui.components.AppSurface
import com.mindora.app.ui.components.BadgeTone
import com.mindora.app.ui.components.ConfirmDialog
import com.mindora.app.ui.components.MindoraTopBar
import com.mindora.app.ui.theme.MindoraPalette

@Composable
fun ProfileScreen(
    state: MindoraState,
    onOpenContributions: () -> Unit,
    onOpenMockExams: () -> Unit,
    onOpenFlashcards: () -> Unit,
    onOpenStudyGroups: () -> Unit,
    onOpenOnboarding: () -> Unit,
    onOpenSettings: () -> Unit,
    onSignOut: () -> Unit
) {
    val user = state.profile
    var showSignOutDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = { MindoraTopBar(title = "Profile") }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    AppAvatar(name = user.fullName, size = 76.dp)
                    Spacer(modifier = Modifier.height(10.dp))
                    Text(user.fullName, style = MaterialTheme.typography.titleLarge)
                    Text(
                        text = user.email,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    AppBadge(label = "${user.educationSystem} · ${user.level}", tone = BadgeTone.PRIMARY)
                }
            }

            item {
                AppSurface {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .size(46.dp)
                                .clip(RoundedCornerShape(12.dp))
                                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.CardGiftcard,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Column {
                            Text("${state.creditsBalance} credits", style = MaterialTheme.typography.titleMedium)
                            Text(
                                text = "Available for past paper downloads",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }

            item {
                Text("Academic Profile", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(8.dp))
                AppSurface {
                    ProfileRow(
                        icon = Icons.Outlined.School,
                        title = "Track & Subjects",
                        subtitle = user.subjects.joinToString(", "),
                        onClick = onOpenOnboarding
                    )
                    HorizontalDivider()
                    ProfileRow(
                        icon = Icons.Outlined.Language,
                        title = "Language",
                        subtitle = user.preferredLanguage.label,
                        onClick = onOpenSettings
                    )
                    HorizontalDivider()
                    ProfileRow(
                        icon = Icons.Outlined.Public,
                        title = "Country",
                        subtitle = user.countryCode,
                        onClick = onOpenOnboarding
                    )
                }
            }

            item {
                Text("App", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(8.dp))
                AppSurface {
                    ProfileRow(
                        icon = Icons.Outlined.FolderCopy,
                        title = "My contributions",
                        subtitle = "${state.documents.size} documents",
                        onClick = onOpenContributions
                    )
                    HorizontalDivider()
                    ProfileRow(
                        icon = Icons.Outlined.Quiz,
                        title = "Mock exams",
                        subtitle = "Practice tests generated for your subjects",
                        onClick = onOpenMockExams
                    )
                    HorizontalDivider()
                    ProfileRow(
                        icon = Icons.Outlined.Style,
                        title = "Flashcards",
                        subtitle = "Spaced repetition review decks",
                        onClick = onOpenFlashcards
                    )
                    HorizontalDivider()
                    ProfileRow(
                        icon = Icons.Outlined.Groups,
                        title = "Study groups",
                        subtitle = "Collaborate with peers",
                        onClick = onOpenStudyGroups
                    )
                }
            }

            item {
                AppSurface {
                    ProfileRow(
                        icon = Icons.Outlined.Settings,
                        title = "Settings",
                        subtitle = "Theme, language, about",
                        onClick = onOpenSettings
                    )
                }
            }

            item {
                Button(
                    onClick = { showSignOutDialog = true },
                    colors = ButtonDefaults.buttonColors(containerColor = MindoraPalette.Danger),
                    modifier = Modifier.fillMaxWidth().height(50.dp)
                ) {
                    Icon(Icons.AutoMirrored.Filled.Logout, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Sign out")
                }
                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }

    if (showSignOutDialog) {
        ConfirmDialog(
            title = "Sign out?",
            message = "You can sign back in anytime with your email.",
            confirmLabel = "Sign out",
            destructive = true,
            onConfirm = {
                showSignOutDialog = false
                onSignOut()
            },
            onDismiss = { showSignOutDialog = false }
        )
    }
}

@Composable
private fun ProfileRow(
    icon: ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(22.dp))
        Spacer(modifier = Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.titleSmall)
            Text(subtitle, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Icon(Icons.Outlined.ChevronRight, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
fun SettingsScreen(
    themeMode: ThemeModeSetting,
    language: AppLanguage,
    onThemeModeChange: (ThemeModeSetting) -> Unit,
    onLanguageChange: (AppLanguage) -> Unit,
    onBack: () -> Unit
) {
    Scaffold(
        topBar = { MindoraTopBar(title = "Settings", onBack = onBack) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            item {
                Text("Appearance", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(8.dp))
                AppSurface {
                    ThemeOptionRow(
                        icon = Icons.Outlined.BrightnessAuto,
                        title = "Follow system",
                        subtitle = "Match your device settings",
                        selected = themeMode == ThemeModeSetting.SYSTEM,
                        onClick = { onThemeModeChange(ThemeModeSetting.SYSTEM) }
                    )
                    HorizontalDivider()
                    ThemeOptionRow(
                        icon = Icons.Outlined.LightMode,
                        title = "Light",
                        subtitle = "Always use light mode",
                        selected = themeMode == ThemeModeSetting.LIGHT,
                        onClick = { onThemeModeChange(ThemeModeSetting.LIGHT) }
                    )
                    HorizontalDivider()
                    ThemeOptionRow(
                        icon = Icons.Outlined.DarkMode,
                        title = "Dark",
                        subtitle = "Always use dark mode",
                        selected = themeMode == ThemeModeSetting.DARK,
                        onClick = { onThemeModeChange(ThemeModeSetting.DARK) }
                    )
                }
            }

            item {
                Text("Language", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(8.dp))
                AppSurface {
                    AppLanguage.entries.forEachIndexed { idx, lang ->
                        if (idx > 0) HorizontalDivider()
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { onLanguageChange(lang) }
                                .padding(horizontal = 16.dp, vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = if (lang == AppLanguage.EN) "English" else "Français",
                                style = MaterialTheme.typography.titleSmall,
                                modifier = Modifier.weight(1f)
                            )
                            RadioButton(
                                selected = language == lang,
                                onClick = { onLanguageChange(lang) }
                            )
                        }
                    }
                }
            }

            item {
                Text("About", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(8.dp))
                AppSurface {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Outlined.Info, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                        Spacer(modifier = Modifier.width(12.dp))
                        Text("Version", style = MaterialTheme.typography.titleSmall, modifier = Modifier.weight(1f))
                        Text("1.0.0", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
        }
    }
}

@Composable
private fun ThemeOptionRow(
    icon: ImageVector,
    title: String,
    subtitle: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
        Spacer(modifier = Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.titleSmall)
            Text(subtitle, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        RadioButton(selected = selected, onClick = onClick)
    }
}

@Composable
fun StudyGroupsScreen(
    groups: List<StudyGroup>,
    onOpenGroup: (String) -> Unit,
    onBack: () -> Unit
) {
    Scaffold(
        topBar = { MindoraTopBar(title = "Study groups", onBack = onBack) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(groups, key = { it.id }) { g ->
                AppSurface(onClick = { onOpenGroup(g.id) }) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .size(44.dp)
                                .clip(RoundedCornerShape(12.dp))
                                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Outlined.Groups, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(g.name, style = MaterialTheme.typography.titleMedium)
                            Text(
                                text = "${g.subject} · ${g.examLevel} · ${g.memberCount} members",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        Icon(Icons.Outlined.ChevronRight, contentDescription = null)
                    }
                }
            }
        }
    }
}

@Composable
fun StudyGroupChatScreen(
    group: StudyGroup?,
    onSendMessage: (String, String) -> Unit,
    onBack: () -> Unit
) {
    if (group == null) {
        Scaffold(topBar = { MindoraTopBar(title = "Study group", onBack = onBack) }) { padding ->
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text("Study group not found.")
            }
        }
        return
    }
    var draft by remember { mutableStateOf("") }

    Scaffold(
        topBar = { MindoraTopBar(title = group.name, onBack = onBack) }
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            LazyColumn(
                modifier = Modifier.weight(1f),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(group.messages, key = { it.id }) { msg ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = if (msg.isMe) Arrangement.End else Arrangement.Start
                    ) {
                        Surface(
                            shape = RoundedCornerShape(14.dp),
                            color = if (msg.isMe) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant,
                            modifier = Modifier.widthIn(max = 280.dp)
                        ) {
                            Column(modifier = Modifier.padding(12.dp)) {
                                if (!msg.isMe) {
                                    Text(
                                        text = msg.senderName,
                                        style = MaterialTheme.typography.labelSmall,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                    Spacer(modifier = Modifier.height(2.dp))
                                }
                                Text(
                                    text = msg.content,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = if (msg.isMe) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurface
                                )
                            }
                        }
                    }
                }
            }
            HorizontalDivider()
            Row(
                modifier = Modifier.fillMaxWidth().padding(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = draft,
                    onValueChange = { draft = it },
                    placeholder = { Text("Message ${group.name}...") },
                    singleLine = true,
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.width(8.dp))
                IconButton(
                    onClick = {
                        if (draft.isNotBlank()) {
                            onSendMessage(group.id, draft)
                            draft = ""
                        }
                    },
                    colors = IconButtonDefaults.filledIconButtonColors()
                ) {
                    Icon(Icons.AutoMirrored.Filled.Send, contentDescription = "Send")
                }
            }
        }
    }
}
