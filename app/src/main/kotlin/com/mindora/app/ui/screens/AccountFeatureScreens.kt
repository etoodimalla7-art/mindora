package com.mindora.app.ui.screens

import android.annotation.SuppressLint
import android.webkit.WebView
import android.webkit.WebViewClient
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
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.SupportAgent
import androidx.compose.material.icons.outlined.WorkspacePremium
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.mindora.app.data.ActiveSubscription
import com.mindora.app.data.AppLanguage
import com.mindora.app.data.AppNotification
import com.mindora.app.data.NotificationPrefs
import com.mindora.app.data.SubscriptionPlan
import com.mindora.app.data.SupportTicket
import com.mindora.app.ui.components.AppBadge
import com.mindora.app.ui.components.AppEmptyState
import com.mindora.app.ui.components.AppSurface
import com.mindora.app.ui.components.BadgeTone
import com.mindora.app.ui.components.MindoraTopBar
import com.mindora.app.ui.theme.MindoraPalette
import kotlinx.coroutines.launch

@SuppressLint("SetJavaScriptEnabled")
@Composable
fun SubscriptionsScreen(
    language: AppLanguage,
    plans: List<SubscriptionPlan>,
    activeSubscription: ActiveSubscription?,
    loading: Boolean,
    onStartCheckout: suspend (String) -> Result<Pair<String, String>>,
    onConfirmPayment: suspend (String) -> Result<String>,
    onCancelSubscription: suspend () -> Unit,
    onBack: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    val scope = rememberCoroutineScope()
    var checkoutSession by remember { mutableStateOf<Pair<String, String>?>(null) }

    Scaffold(
        topBar = { MindoraTopBar(title = if (isFr) "Abonnements Pro" else "Plans & Pro Access", onBack = onBack) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            activeSubscription?.let { sub ->
                item {
                    AppSurface(containerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.08f)) {
                        Column(modifier = Modifier.padding(18.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Outlined.WorkspacePremium,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(sub.planName, style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
                                AppBadge(label = sub.status.uppercase(), tone = BadgeTone.SUCCESS)
                            }
                            if (!sub.periodEnd.isNullOrBlank()) {
                                Spacer(modifier = Modifier.height(6.dp))
                                Text(
                                    text = if (isFr) "Renouvellement : ${sub.periodEnd.take(10)}" else "Valid until: ${sub.periodEnd.take(10)}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            if (sub.status == "active") {
                                Spacer(modifier = Modifier.height(10.dp))
                                OutlinedButton(
                                    onClick = { scope.launch { onCancelSubscription() } },
                                    colors = ButtonDefaults.outlinedButtonColors(contentColor = MindoraPalette.Danger)
                                ) {
                                    Text(if (isFr) "Annuler l'abonnement" else "Cancel subscription")
                                }
                            }
                        }
                    }
                }
            }

            if (plans.isEmpty()) {
                item {
                    AppEmptyState(
                        icon = Icons.Outlined.WorkspacePremium,
                        title = if (isFr) "Formules indisponibles" else "No plans loaded",
                        message = if (isFr) "Vérifie ta connexion et réessaie." else "Check your connection to load plans."
                    )
                }
            } else {
                items(plans, key = { it.id }) { plan ->
                    val isCurrent = activeSubscription?.planName == plan.name && activeSubscription.status == "active"
                    AppSurface {
                        Column(modifier = Modifier.padding(18.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(plan.name, style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
                                AppBadge(label = plan.tier.uppercase(), tone = BadgeTone.PRIMARY)
                            }
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = if (plan.amountMinor <= 0) (if (isFr) "Gratuit" else "Free")
                                else "${plan.amountMinor} ${plan.currency} / ${plan.billingCycle}",
                                style = MaterialTheme.typography.headlineSmall,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                            if (plan.description.isNotBlank()) {
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    plan.description,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            Spacer(modifier = Modifier.height(10.dp))
                            plan.features.forEach { feat ->
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    modifier = Modifier.padding(vertical = 2.dp)
                                ) {
                                    Icon(
                                        Icons.Outlined.Check,
                                        contentDescription = null,
                                        tint = MindoraPalette.Success,
                                        modifier = Modifier.size(16.dp)
                                    )
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(feat, style = MaterialTheme.typography.bodySmall)
                                }
                            }
                            if (plan.amountMinor > 0 && !isCurrent) {
                                Spacer(modifier = Modifier.height(12.dp))
                                Button(
                                    onClick = {
                                        scope.launch {
                                            onStartCheckout(plan.code).onSuccess { pair ->
                                                checkoutSession = pair
                                            }
                                        }
                                    },
                                    enabled = !loading,
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Text(if (isFr) "S'abonner avec Flutterwave" else "Subscribe via Flutterwave")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    checkoutSession?.let { (url, ref) ->
        Dialog(
            onDismissRequest = { checkoutSession = null },
            properties = DialogProperties(usePlatformDefaultWidth = false)
        ) {
            Surface(
                modifier = Modifier.fillMaxSize().padding(12.dp),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(modifier = Modifier.fillMaxSize()) {
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            if (isFr) "Paiement sécurisé Flutterwave" else "Flutterwave Checkout",
                            style = MaterialTheme.typography.titleMedium,
                            modifier = Modifier.weight(1f)
                        )
                        IconButton(onClick = { checkoutSession = null }) {
                            Icon(Icons.Outlined.Close, contentDescription = "Close")
                        }
                    }
                    AndroidView(
                        factory = { ctx ->
                            WebView(ctx).apply {
                                settings.javaScriptEnabled = true
                                settings.domStorageEnabled = true
                                webViewClient = WebViewClient()
                                loadUrl(url)
                            }
                        },
                        modifier = Modifier.weight(1f).fillMaxWidth()
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(12.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedButton(
                            onClick = { checkoutSession = null },
                            modifier = Modifier.weight(1f)
                        ) {
                            Text(if (isFr) "Fermer" else "Close")
                        }
                        Button(
                            onClick = {
                                scope.launch {
                                    onConfirmPayment(ref).onSuccess { checkoutSession = null }
                                }
                            },
                            modifier = Modifier.weight(1f)
                        ) {
                            Text(if (isFr) "Confirmer paiement" else "Confirm payment")
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun NotificationsScreen(
    language: AppLanguage,
    notifications: List<AppNotification>,
    prefs: NotificationPrefs,
    onMarkRead: suspend (String) -> Unit,
    onUpdatePrefs: suspend (NotificationPrefs) -> Unit,
    onBack: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    val scope = rememberCoroutineScope()

    Scaffold(
        topBar = { MindoraTopBar(title = if (isFr) "Notifications" else "Notifications", onBack = onBack) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                Text(if (isFr) "Préférences d'alertes" else "Alert preferences", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(6.dp))
                AppSurface {
                    PrefToggleRow(
                        label = if (isFr) "Notifications activées" else "Enable notifications",
                        checked = prefs.enabled,
                        onCheckedChange = { scope.launch { onUpdatePrefs(prefs.copy(enabled = it)) } }
                    )
                    HorizontalDivider()
                    PrefToggleRow(
                        label = if (isFr) "Rappels de révision" else "Session reminders",
                        checked = prefs.sessionReminders,
                        onCheckedChange = { scope.launch { onUpdatePrefs(prefs.copy(sessionReminders = it)) } }
                    )
                    HorizontalDivider()
                    PrefToggleRow(
                        label = if (isFr) "Compte à rebours examen" else "Exam countdown",
                        checked = prefs.examCountdown,
                        onCheckedChange = { scope.launch { onUpdatePrefs(prefs.copy(examCountdown = it)) } }
                    )
                    HorizontalDivider()
                    PrefToggleRow(
                        label = if (isFr) "Rappels de série (Streak)" else "Streak alerts",
                        checked = prefs.streakReminders,
                        onCheckedChange = { scope.launch { onUpdatePrefs(prefs.copy(streakReminders = it)) } }
                    )
                }
            }

            item {
                Text(if (isFr) "Messages récents" else "Recent alerts", style = MaterialTheme.typography.titleMedium)
            }

            if (notifications.isEmpty()) {
                item {
                    AppEmptyState(
                        icon = Icons.Outlined.Notifications,
                        title = if (isFr) "Aucune notification" else "No notifications yet",
                        message = if (isFr) "Tu recevras ici tes rappels et annonces officielles."
                        else "Your study reminders and updates will appear here."
                    )
                }
            } else {
                items(notifications, key = { it.id }) { n ->
                    AppSurface(onClick = { scope.launch { onMarkRead(n.id) } }) {
                        Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.Top) {
                            if (!n.isRead) {
                                Box(
                                    modifier = Modifier
                                        .padding(top = 6.dp, end = 10.dp)
                                        .size(8.dp)
                                        .clip(CircleShape)
                                        .background(MaterialTheme.colorScheme.primary)
                                )
                            }
                            Column(modifier = Modifier.weight(1f)) {
                                Text(n.title, style = MaterialTheme.typography.titleSmall)
                                Spacer(modifier = Modifier.height(2.dp))
                                Text(
                                    n.body,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun PrefToggleRow(
    label: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, style = MaterialTheme.typography.bodyMedium)
        Switch(checked = checked, onCheckedChange = onCheckedChange)
    }
}

@Composable
fun SupportTicketsScreen(
    language: AppLanguage,
    tickets: List<SupportTicket>,
    onCreateTicket: suspend (subject: String, description: String, priority: String) -> Unit,
    onOpenTicket: (String) -> Unit,
    onBack: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    val scope = rememberCoroutineScope()
    var showCreate by remember { mutableStateOf(false) }

    Scaffold(
        topBar = { MindoraTopBar(title = if (isFr) "Support & Aide" else "Support & Help", onBack = onBack) },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { showCreate = true },
                icon = { Icon(Icons.Default.Add, contentDescription = null) },
                text = { Text(if (isFr) "Nouveau ticket" else "New ticket") }
            )
        }
    ) { padding ->
        if (tickets.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                AppEmptyState(
                    icon = Icons.Outlined.SupportAgent,
                    title = if (isFr) "Aucun ticket de support" else "No support tickets",
                    message = if (isFr) "Un souci avec ton compte ou un paiement ? Écris-nous."
                    else "Need help with your account or payments? Create a ticket.",
                    actionLabel = if (isFr) "Contacter le support" else "Create ticket",
                    onAction = { showCreate = true }
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentPadding = PaddingValues(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(tickets, key = { it.id }) { ticket ->
                    AppSurface(onClick = { onOpenTicket(ticket.id) }) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(ticket.subject, style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
                                AppBadge(
                                    label = ticket.status.uppercase(),
                                    tone = if (ticket.status == "resolved" || ticket.status == "closed") BadgeTone.SUCCESS else BadgeTone.PRIMARY
                                )
                            }
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                ticket.description,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                maxLines = 2
                            )
                        }
                    }
                }
                item { Spacer(modifier = Modifier.height(72.dp)) }
            }
        }
    }

    if (showCreate) {
        var subject by remember { mutableStateOf("") }
        var description by remember { mutableStateOf("") }
        var priority by remember { mutableStateOf("medium") }
        AlertDialog(
            onDismissRequest = { showCreate = false },
            title = { Text(if (isFr) "Nouveau ticket" else "New Support Ticket") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedTextField(
                        value = subject,
                        onValueChange = { subject = it },
                        label = { Text(if (isFr) "Objet" else "Subject") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = description,
                        onValueChange = { description = it },
                        label = { Text(if (isFr) "Décris ton problème" else "Describe your issue") },
                        minLines = 3,
                        modifier = Modifier.fillMaxWidth()
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        listOf("low", "medium", "high").forEach { p ->
                            FilterChip(
                                selected = priority == p,
                                onClick = { priority = p },
                                label = { Text(p.uppercase()) }
                            )
                        }
                    }
                }
            },
            confirmButton = {
                Button(onClick = {
                    if (subject.isNotBlank() && description.isNotBlank()) {
                        scope.launch { onCreateTicket(subject, description, priority) }
                        showCreate = false
                    }
                }) { Text(if (isFr) "Envoyer" else "Submit") }
            },
            dismissButton = {
                TextButton(onClick = { showCreate = false }) { Text(if (isFr) "Annuler" else "Cancel") }
            }
        )
    }
}

@Composable
fun SupportTicketDetailScreen(
    ticketId: String,
    ticket: SupportTicket?,
    language: AppLanguage,
    onLoadTicket: suspend (String) -> Unit,
    onReply: suspend (String, String) -> Unit,
    onBack: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    val scope = rememberCoroutineScope()
    var draft by remember { mutableStateOf("") }

    LaunchedEffect(ticketId) {
        onLoadTicket(ticketId)
    }

    Scaffold(
        topBar = { MindoraTopBar(title = ticket?.subject ?: "Ticket", onBack = onBack) }
    ) { padding ->
        if (ticket == null) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
            return@Scaffold
        }
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            LazyColumn(
                modifier = Modifier.weight(1f),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                item {
                    AppSurface {
                        Column(modifier = Modifier.padding(14.dp)) {
                            AppBadge(label = ticket.status.uppercase(), tone = BadgeTone.PRIMARY)
                            Spacer(modifier = Modifier.height(6.dp))
                            Text(ticket.description, style = MaterialTheme.typography.bodyMedium)
                        }
                    }
                }
                items(ticket.messages, key = { it.id }) { m ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = if (m.isAdmin) Arrangement.Start else Arrangement.End
                    ) {
                        Surface(
                            shape = RoundedCornerShape(14.dp),
                            color = if (m.isAdmin) MaterialTheme.colorScheme.surfaceVariant else MaterialTheme.colorScheme.primary,
                            modifier = Modifier.widthIn(max = 280.dp)
                        ) {
                            Column(modifier = Modifier.padding(12.dp)) {
                                if (m.isAdmin) {
                                    Text(
                                        "Support MINDORA",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MaterialTheme.colorScheme.primary,
                                        fontWeight = FontWeight.Bold
                                    )
                                }
                                Text(
                                    m.body,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = if (m.isAdmin) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onPrimary
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
                    placeholder = { Text(if (isFr) "Ajouter une réponse..." else "Add a reply...") },
                    singleLine = true,
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.width(8.dp))
                IconButton(
                    onClick = {
                        if (draft.isNotBlank()) {
                            val text = draft
                            draft = ""
                            scope.launch { onReply(ticketId, text) }
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
