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
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.outlined.BrightnessAuto
import androidx.compose.material.icons.outlined.CardGiftcard
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material.icons.outlined.CloudSync
import androidx.compose.material.icons.outlined.DarkMode
import androidx.compose.material.icons.outlined.Dns
import androidx.compose.material.icons.outlined.FolderCopy
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.LightMode
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Public
import androidx.compose.material.icons.outlined.Quiz
import androidx.compose.material.icons.outlined.School
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.Style
import androidx.compose.material.icons.outlined.SupportAgent
import androidx.compose.material.icons.outlined.VerifiedUser
import androidx.compose.material.icons.outlined.WorkspacePremium
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.mindora.app.BuildConfig
import com.mindora.app.data.AppLanguage
import com.mindora.app.data.MindoraState
import com.mindora.app.data.StudyGroup
import com.mindora.app.data.ThemeModeSetting
import com.mindora.app.ui.components.AppAvatar
import com.mindora.app.ui.components.AppBadge
import com.mindora.app.ui.components.AppEmptyState
import com.mindora.app.ui.components.AppSurface
import com.mindora.app.ui.components.BadgeTone
import com.mindora.app.ui.components.ConfirmDialog
import com.mindora.app.ui.components.MindoraTopBar
import com.mindora.app.ui.theme.MindoraPalette
import kotlinx.coroutines.launch

@Composable
fun ProfileScreen(
    state: MindoraState,
    onVerifyEmail: () -> Unit,
    onOpenSubscriptions: () -> Unit,
    onOpenNotifications: () -> Unit,
    onOpenSupport: () -> Unit,
    onOpenContributions: () -> Unit,
    onOpenMockExams: () -> Unit,
    onOpenFlashcards: () -> Unit,
    onOpenStudyGroups: () -> Unit,
    onOpenOnboarding: () -> Unit,
    onOpenSettings: () -> Unit,
    onSignOut: suspend () -> Unit
) {
    val isFr = state.language == AppLanguage.FR
    val user = state.profile
    val scope = rememberCoroutineScope()
    var showSignOutDialog by remember { mutableStateOf(false) }
    val unreadCount = state.notifications.count { !it.isRead }

    Scaffold(
        topBar = { MindoraTopBar(title = if (isFr) "Profil" else "Profile") }
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
                    Text(user.fullName.ifBlank { user.email }, style = MaterialTheme.typography.titleLarge)
                    Text(
                        text = user.email,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        AppBadge(label = "${user.educationSystem} · ${user.level}", tone = BadgeTone.PRIMARY)
                        if (user.isVerified) {
                            AppBadge(label = if (isFr) "Vérifié" else "Verified", tone = BadgeTone.SUCCESS)
                        } else {
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = MindoraPalette.Warning.copy(alpha = 0.14f),
                                onClick = onVerifyEmail
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        Icons.Outlined.VerifiedUser,
                                        contentDescription = null,
                                        tint = MindoraPalette.Warning,
                                        modifier = Modifier.size(13.dp)
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(
                                        if (isFr) "Vérifier email" else "Verify email",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MindoraPalette.Warning
                                    )
                                }
                            }
                        }
                    }
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
                            Text(
                                "${state.creditsBalance} ${if (isFr) "crédits" else "credits"}",
                                style = MaterialTheme.typography.titleMedium
                            )
                            Text(
                                text = if (isFr) "Disponibles pour télécharger et débloquer du contenu"
                                else "Available for past paper downloads & study rewards",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }

            item {
                Text(if (isFr) "Compte & Pro" else "Account & Pro", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(8.dp))
                AppSurface {
                    ProfileRow(
                        icon = Icons.Outlined.WorkspacePremium,
                        title = if (isFr) "Abonnement Pro" else "Subscription & Pro",
                        subtitle = state.activeSubscription?.let { "${it.planName} (${it.status})" }
                            ?: (if (isFr) "Formule Gratuite · Passer à Pro" else "Free tier · Upgrade to Pro"),
                        onClick = onOpenSubscriptions
                    )
                    HorizontalDivider()
                    ProfileRow(
                        icon = Icons.Outlined.Notifications,
                        title = if (isFr) "Notifications" else "Notifications",
                        subtitle = if (unreadCount > 0) {
                            if (isFr) "$unreadCount non lues" else "$unreadCount unread"
                        } else {
                            if (isFr) "Rappels & alertes" else "Reminders & alert preferences"
                        },
                        onClick = onOpenNotifications
                    )
                    HorizontalDivider()
                    ProfileRow(
                        icon = Icons.Outlined.SupportAgent,
                        title = if (isFr) "Support & Aide" else "Support & Help",
                        subtitle = if (isFr) "${state.tickets.size} tickets" else "${state.tickets.size} support tickets",
                        onClick = onOpenSupport
                    )
                }
            }

            item {
                Text(if (isFr) "Profil Académique" else "Academic Profile", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(8.dp))
                AppSurface {
                    ProfileRow(
                        icon = Icons.Outlined.School,
                        title = if (isFr) "Filière & Matières" else "Track & Subjects",
                        subtitle = user.subjects.joinToString(", "),
                        onClick = onOpenOnboarding
                    )
                    HorizontalDivider()
                    ProfileRow(
                        icon = Icons.Outlined.Language,
                        title = if (isFr) "Langue" else "Language",
                        subtitle = user.preferredLanguage.label,
                        onClick = onOpenSettings
                    )
                    HorizontalDivider()
                    ProfileRow(
                        icon = Icons.Outlined.Public,
                        title = if (isFr) "Pays" else "Country",
                        subtitle = user.countryCode,
                        onClick = onOpenOnboarding
                    )
                }
            }

            item {
                Text(if (isFr) "Outils d'étude" else "Study Tools", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(8.dp))
                AppSurface {
                    ProfileRow(
                        icon = Icons.Outlined.FolderCopy,
                        title = if (isFr) "Mes contributions" else "My contributions",
                        subtitle = "${state.documents.size} documents",
                        onClick = onOpenContributions
                    )
                    HorizontalDivider()
                    ProfileRow(
                        icon = Icons.Outlined.Quiz,
                        title = if (isFr) "Examens blancs" else "Mock exams",
                        subtitle = if (isFr) "Tests chronométrés corrigés par le serveur" else "Timed server-graded tests",
                        onClick = onOpenMockExams
                    )
                    HorizontalDivider()
                    ProfileRow(
                        icon = Icons.Outlined.Style,
                        title = "Flashcards",
                        subtitle = if (isFr) "Révision espacée SM-2" else "Spaced repetition review decks",
                        onClick = onOpenFlashcards
                    )
                    HorizontalDivider()
                    ProfileRow(
                        icon = Icons.Outlined.Groups,
                        title = if (isFr) "Groupes d'étude" else "Study groups",
                        subtitle = if (isFr) "Discuter en direct par WebSocket" else "Collaborate live with peers",
                        onClick = onOpenStudyGroups
                    )
                }
            }

            item {
                AppSurface {
                    ProfileRow(
                        icon = Icons.Outlined.Settings,
                        title = if (isFr) "Paramètres" else "Settings",
                        subtitle = if (isFr) "Thème, langue, serveur API, synchro" else "Theme, language, sync, API URL",
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
                    Text(if (isFr) "Se déconnecter" else "Sign out")
                }
                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }

    if (showSignOutDialog) {
        ConfirmDialog(
            title = if (isFr) "Se déconnecter ?" else "Sign out?",
            message = if (isFr) "Tu pourras te reconnecter à tout moment avec ton email."
            else "You can sign back in anytime with your email.",
            confirmLabel = if (isFr) "Déconnexion" else "Sign out",
            destructive = true,
            onConfirm = {
                showSignOutDialog = false
                scope.launch { onSignOut() }
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
    apiBaseUrl: String,
    onThemeModeChange: (ThemeModeSetting) -> Unit,
    onLanguageChange: (AppLanguage) -> Unit,
    onUpdateApiBaseUrl: (String) -> Unit,
    onSyncNow: suspend () -> Unit,
    onBack: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    val scope = rememberCoroutineScope()
    var showApiDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = { MindoraTopBar(title = if (isFr) "Paramètres" else "Settings", onBack = onBack) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            item {
                Text(if (isFr) "Apparence" else "Appearance", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(8.dp))
                AppSurface {
                    ThemeOptionRow(
                        icon = Icons.Outlined.BrightnessAuto,
                        title = if (isFr) "Système" else "Follow system",
                        subtitle = if (isFr) "Adapter aux réglages du téléphone" else "Match your device settings",
                        selected = themeMode == ThemeModeSetting.SYSTEM,
                        onClick = { onThemeModeChange(ThemeModeSetting.SYSTEM) }
                    )
                    HorizontalDivider()
                    ThemeOptionRow(
                        icon = Icons.Outlined.LightMode,
                        title = if (isFr) "Clair" else "Light",
                        subtitle = if (isFr) "Toujours utiliser le thème clair" else "Always use light mode",
                        selected = themeMode == ThemeModeSetting.LIGHT,
                        onClick = { onThemeModeChange(ThemeModeSetting.LIGHT) }
                    )
                    HorizontalDivider()
                    ThemeOptionRow(
                        icon = Icons.Outlined.DarkMode,
                        title = if (isFr) "Sombre" else "Dark",
                        subtitle = if (isFr) "Toujours utiliser le thème sombre" else "Always use dark mode",
                        selected = themeMode == ThemeModeSetting.DARK,
                        onClick = { onThemeModeChange(ThemeModeSetting.DARK) }
                    )
                }
            }

            item {
                Text(if (isFr) "Langue" else "Language", style = MaterialTheme.typography.titleMedium)
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
                Text(if (isFr) "Synchronisation & Serveur" else "Sync & Server", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(8.dp))
                AppSurface {
                    ProfileRow(
                        icon = Icons.Outlined.CloudSync,
                        title = if (isFr) "Synchroniser maintenant" else "Sync now",
                        subtitle = if (isFr) "Actualiser les données depuis le serveur" else "Refresh all study data from server",
                        onClick = { scope.launch { onSyncNow() } }
                    )
                    HorizontalDivider()
                    ProfileRow(
                        icon = Icons.Outlined.Dns,
                        title = if (isFr) "URL du serveur API" else "API Server URL",
                        subtitle = apiBaseUrl,
                        onClick = { showApiDialog = true }
                    )
                }
            }

            item {
                Text(if (isFr) "À propos" else "About", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(8.dp))
                AppSurface {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Outlined.Info, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                        Spacer(modifier = Modifier.width(12.dp))
                        Text("Version", style = MaterialTheme.typography.titleSmall, modifier = Modifier.weight(1f))
                        Text(BuildConfig.VERSION_NAME, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
        }
    }

    if (showApiDialog) {
        var draftUrl by remember { mutableStateOf(apiBaseUrl) }
        AlertDialog(
            onDismissRequest = { showApiDialog = false },
            title = { Text(if (isFr) "Adresse API MINDORA" else "MINDORA API Endpoint") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = draftUrl,
                        onValueChange = { draftUrl = it },
                        label = { Text("Base URL") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    TextButton(onClick = { draftUrl = "https://mindora-w3jv.onrender.com/api/v1/" }) {
                        Text("Use Render Prod (mindora-w3jv.onrender.com)")
                    }
                }
            },
            confirmButton = {
                Button(onClick = {
                    if (draftUrl.startsWith("http")) {
                        onUpdateApiBaseUrl(draftUrl)
                        scope.launch { onSyncNow() }
                    }
                    showApiDialog = false
                }) { Text(if (isFr) "Enregistrer" else "Save") }
            },
            dismissButton = {
                TextButton(onClick = { showApiDialog = false }) { Text(if (isFr) "Annuler" else "Cancel") }
            }
        )
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
    language: AppLanguage,
    groups: List<StudyGroup>,
    onCreateGroup: suspend (name: String, subject: String, examLevel: String) -> Unit,
    onJoinGroup: suspend (String) -> Unit,
    onOpenGroup: (String) -> Unit,
    onBack: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    val scope = rememberCoroutineScope()
    var showCreate by remember { mutableStateOf(false) }

    Scaffold(
        topBar = { MindoraTopBar(title = if (isFr) "Groupes d'étude" else "Study groups", onBack = onBack) },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { showCreate = true },
                icon = { Icon(Icons.Default.Add, contentDescription = null) },
                text = { Text(if (isFr) "Créer un groupe" else "New group") }
            )
        }
    ) { padding ->
        if (groups.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                AppEmptyState(
                    icon = Icons.Outlined.Groups,
                    title = if (isFr) "Aucun groupe" else "No study groups yet",
                    message = if (isFr) "Crée un salon pour réviser avec d'autres étudiants."
                    else "Create a room to study live with peers.",
                    actionLabel = if (isFr) "Créer un groupe" else "Create group",
                    onAction = { showCreate = true }
                )
            }
        } else {
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
                                    text = "${g.subject} · ${g.examLevel} · ${g.memberCount} ${if (isFr) "membres" else "members"}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            if (g.isMember) {
                                AppBadge(label = if (isFr) "MEMBRE" else "JOINED", tone = BadgeTone.SUCCESS)
                            } else {
                                OutlinedButton(onClick = { scope.launch { onJoinGroup(g.id) } }) {
                                    Text(if (isFr) "Rejoindre" else "Join")
                                }
                            }
                            Spacer(modifier = Modifier.width(4.dp))
                            Icon(Icons.Outlined.ChevronRight, contentDescription = null)
                        }
                    }
                }
                item { Spacer(modifier = Modifier.height(72.dp)) }
            }
        }
    }

    if (showCreate) {
        var name by remember { mutableStateOf("") }
        var subject by remember { mutableStateOf("Mathematics") }
        var level by remember { mutableStateOf("GCE A-Level") }
        AlertDialog(
            onDismissRequest = { showCreate = false },
            title = { Text(if (isFr) "Nouveau groupe d'étude" else "New Study Group") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedTextField(
                        value = name,
                        onValueChange = { name = it },
                        label = { Text(if (isFr) "Nom du groupe" else "Group name") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = subject,
                        onValueChange = { subject = it },
                        label = { Text(if (isFr) "Matière" else "Subject") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = level,
                        onValueChange = { level = it },
                        label = { Text(if (isFr) "Niveau" else "Exam level") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(onClick = {
                    if (name.isNotBlank()) {
                        scope.launch { onCreateGroup(name, subject, level) }
                        showCreate = false
                    }
                }) { Text(if (isFr) "Créer" else "Create") }
            },
            dismissButton = {
                TextButton(onClick = { showCreate = false }) { Text(if (isFr) "Annuler" else "Cancel") }
            }
        )
    }
}

@Composable
fun StudyGroupChatScreen(
    groupId: String,
    group: StudyGroup?,
    presenceCount: Int,
    language: AppLanguage,
    onOpenGroup: suspend (String) -> Unit,
    onCloseGroup: () -> Unit,
    onSendMessage: suspend (String, String) -> Unit,
    onBack: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    val scope = rememberCoroutineScope()
    val listState = rememberLazyListState()

    LaunchedEffect(groupId) {
        onOpenGroup(groupId)
    }

    DisposableEffect(groupId) {
        onDispose { onCloseGroup() }
    }

    if (group == null) {
        Scaffold(topBar = { MindoraTopBar(title = if (isFr) "Groupe" else "Study group", onBack = onBack) }) { padding ->
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text(if (isFr) "Groupe introuvable." else "Study group not found.")
            }
        }
        return
    }

    val msgs = group.messages
    LaunchedEffect(msgs.size) {
        if (msgs.isNotEmpty()) {
            listState.animateScrollToItem(msgs.lastIndex)
        }
    }

    var draft by remember { mutableStateOf("") }

    Scaffold(
        topBar = {
            MindoraTopBar(
                title = group.name,
                onBack = onBack,
                actions = {
                    AppBadge(
                        label = "$presenceCount ${if (isFr) "en ligne" else "online"}",
                        tone = BadgeTone.SUCCESS
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                }
            )
        }
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            LazyColumn(
                state = listState,
                modifier = Modifier.weight(1f),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(msgs, key = { it.id }) { msg ->
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
                            val text = draft
                            draft = ""
                            scope.launch { onSendMessage(group.id, text) }
                        }
                    },
                    colors = IconButtonDefaults.filledIconButtonColors()
                ) {
                    Icon(Icons.AutoMirrored.Filled.Send, contentDescription = if (isFr) "Envoyer" else "Send")
                }
            }
        }
    }
}
