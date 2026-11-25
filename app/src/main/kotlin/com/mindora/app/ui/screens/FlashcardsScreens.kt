package com.mindora.app.ui.screens

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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material.icons.outlined.Style
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.mindora.app.data.AppLanguage
import com.mindora.app.data.Deck
import com.mindora.app.data.Flashcard
import com.mindora.app.ui.components.AppBadge
import com.mindora.app.ui.components.AppEmptyState
import com.mindora.app.ui.components.AppSurface
import com.mindora.app.ui.components.BadgeTone
import com.mindora.app.ui.components.MindoraTopBar
import com.mindora.app.ui.theme.MindoraPalette
import kotlinx.coroutines.launch

@Composable
fun FlashcardsScreen(
    language: AppLanguage,
    decks: List<Deck>,
    loading: Boolean,
    onOpenDeck: (String) -> Unit,
    onCreateDeck: suspend (title: String, subject: String, description: String) -> Unit,
    onAddCard: suspend (deckId: String, front: String, back: String) -> Unit,
    onGenerateCards: suspend (deckId: String, topic: String) -> Unit,
    onBack: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    val scope = rememberCoroutineScope()
    var showCreateDialog by remember { mutableStateOf(false) }
    var addCardDeckId by remember { mutableStateOf<String?>(null) }

    Scaffold(
        topBar = { MindoraTopBar(title = "Flashcards", onBack = onBack) },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { showCreateDialog = true },
                icon = { Icon(Icons.Default.Add, contentDescription = null) },
                text = { Text(if (isFr) "Nouveau deck" else "New deck") }
            )
        }
    ) { padding ->
        if (decks.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentAlignment = Alignment.Center
            ) {
                AppEmptyState(
                    icon = Icons.Outlined.Style,
                    title = if (isFr) "Aucun deck pour l'instant" else "No decks yet",
                    message = if (isFr) {
                        "Crée ton premier paquet pour démarrer la répétition espacée SM-2."
                    } else {
                        "Create your first flashcard deck to start SM-2 spaced repetition."
                    },
                    actionLabel = if (isFr) "Créer un deck" else "Create deck",
                    onAction = { showCreateDialog = true }
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentPadding = PaddingValues(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(decks, key = { it.id }) { deck ->
                    AppSurface(onClick = { onOpenDeck(deck.id) }) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(deck.title, style = MaterialTheme.typography.titleMedium)
                                    Spacer(modifier = Modifier.height(2.dp))
                                    Text(
                                        text = if (isFr) {
                                            "${deck.cardCount} cartes · ${deck.dueCount} à réviser"
                                        } else {
                                            "${deck.cardCount} cards · ${deck.dueCount} due for review"
                                        },
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                                if (deck.dueCount > 0) {
                                    AppBadge(
                                        label = if (isFr) "${deck.dueCount} À REVOIR" else "${deck.dueCount} DUE",
                                        tone = BadgeTone.PRIMARY
                                    )
                                } else {
                                    AppBadge(
                                        label = if (isFr) "À JOUR" else "UP TO DATE",
                                        tone = BadgeTone.SUCCESS
                                    )
                                }
                                Spacer(modifier = Modifier.width(4.dp))
                                Icon(Icons.Outlined.ChevronRight, contentDescription = null)
                            }
                            Spacer(modifier = Modifier.height(10.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                OutlinedButton(
                                    onClick = { addCardDeckId = deck.id },
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Icon(Icons.Default.Add, contentDescription = null)
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(if (isFr) "Ajouter" else "Add card")
                                }
                                OutlinedButton(
                                    onClick = {
                                        scope.launch { onGenerateCards(deck.id, deck.subject) }
                                    },
                                    enabled = !loading,
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Icon(Icons.Outlined.AutoAwesome, contentDescription = null)
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(if (isFr) "Cartes IA" else "AI cards")
                                }
                            }
                        }
                    }
                }
                item { Spacer(modifier = Modifier.height(72.dp)) }
            }
        }
    }

    if (showCreateDialog) {
        var title by remember { mutableStateOf("") }
        var subject by remember { mutableStateOf("Mathematics") }
        var desc by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { showCreateDialog = false },
            title = { Text(if (isFr) "Nouveau deck" else "New Deck") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedTextField(
                        value = title,
                        onValueChange = { title = it },
                        label = { Text(if (isFr) "Titre du deck" else "Deck title") },
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
                        value = desc,
                        onValueChange = { desc = it },
                        label = { Text(if (isFr) "Description (optionnel)" else "Description (optional)") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (title.isNotBlank()) {
                            scope.launch { onCreateDeck(title, subject.ifBlank { "General" }, desc) }
                            showCreateDialog = false
                        }
                    }
                ) { Text(if (isFr) "Créer" else "Create") }
            },
            dismissButton = {
                TextButton(onClick = { showCreateDialog = false }) { Text(if (isFr) "Annuler" else "Cancel") }
            }
        )
    }

    addCardDeckId?.let { deckId ->
        var front by remember { mutableStateOf("") }
        var back by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { addCardDeckId = null },
            title = { Text(if (isFr) "Ajouter une flashcard" else "Add Flashcard") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedTextField(
                        value = front,
                        onValueChange = { front = it },
                        label = { Text(if (isFr) "Question (recto)" else "Question (front)") },
                        minLines = 2,
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = back,
                        onValueChange = { back = it },
                        label = { Text(if (isFr) "Réponse (verso)" else "Answer (back)") },
                        minLines = 2,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (front.isNotBlank() && back.isNotBlank()) {
                            scope.launch { onAddCard(deckId, front, back) }
                            addCardDeckId = null
                        }
                    }
                ) { Text(if (isFr) "Enregistrer" else "Save card") }
            },
            dismissButton = {
                TextButton(onClick = { addCardDeckId = null }) { Text(if (isFr) "Annuler" else "Cancel") }
            }
        )
    }
}

@Composable
fun FlashcardReviewScreen(
    deckId: String,
    deck: Deck?,
    language: AppLanguage,
    onLoadDueCards: suspend (String) -> Unit,
    onReviewCard: suspend (deckId: String, cardId: String, quality: Int) -> Unit,
    onBack: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    val scope = rememberCoroutineScope()
    var loaded by remember(deckId) { mutableStateOf(false) }
    var reviewQueue by remember(deckId) { mutableStateOf<List<Flashcard>>(emptyList()) }
    var currentIndex by remember(deckId) { mutableIntStateOf(0) }
    var showBack by remember(deckId) { mutableStateOf(false) }
    var finished by remember(deckId) { mutableStateOf(false) }

    LaunchedEffect(deckId) {
        onLoadDueCards(deckId)
        loaded = true
    }

    LaunchedEffect(deck?.cards, loaded) {
        if (deck != null && reviewQueue.isEmpty() && !finished) {
            val due = deck.cards.filter { it.isDue }
            val q = due.ifEmpty { deck.cards }
            if (q.isNotEmpty()) {
                reviewQueue = q
            } else if (loaded) {
                finished = true
            }
        }
    }

    if (deck == null) {
        Scaffold(topBar = { MindoraTopBar(title = if (isFr) "Révision" else "Review", onBack = onBack) }) { padding ->
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text(if (isFr) "Deck introuvable." else "Deck not found.")
            }
        }
        return
    }

    Scaffold(
        topBar = {
            MindoraTopBar(
                title = if (finished || reviewQueue.isEmpty()) deck.title
                else "${if (isFr) "Carte" else "Review"} ${currentIndex + 1}/${reviewQueue.size}",
                onBack = onBack
            )
        }
    ) { padding ->
        if (!loaded && reviewQueue.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
            return@Scaffold
        }

        if (finished || reviewQueue.isEmpty() || currentIndex >= reviewQueue.size) {
            Box(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentAlignment = Alignment.Center
            ) {
                AppEmptyState(
                    icon = Icons.Outlined.Style,
                    title = if (isFr) "Toutes les cartes sont à jour !" else "All cards are up to date!",
                    message = if (isFr) {
                        "Les intervalles SM-2 ont été synchronisés avec le serveur."
                    } else {
                        "SM-2 intervals have been synced based on your recall confidence."
                    },
                    actionLabel = if (isFr) "Retour aux decks" else "Back to decks",
                    onAction = onBack
                )
            }
            return@Scaffold
        }

        val card = reviewQueue[currentIndex]

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(20.dp)
        ) {
            Card(
                onClick = { showBack = !showBack },
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = if (showBack) (if (isFr) "RÉPONSE" else "ANSWER") else "QUESTION",
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = if (showBack) card.back else card.front,
                        style = MaterialTheme.typography.headlineSmall,
                        textAlign = TextAlign.Center
                    )
                    Spacer(modifier = Modifier.height(20.dp))
                    Text(
                        text = if (isFr) {
                            "Touchez pour retourner · Facilité ${card.easeFactor} · Intervalle ${card.intervalDays}j"
                        } else {
                            "Tap card to flip · Ease ${card.easeFactor} · Interval ${card.intervalDays}d"
                        },
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
            if (!showBack) {
                OutlinedButton(
                    onClick = { showBack = true },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp)
                ) {
                    Text(if (isFr) "Afficher la réponse" else "Show answer")
                }
            } else {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    val advance: (Int) -> Unit = { quality ->
                        scope.launch { onReviewCard(deck.id, card.id, quality) }
                        if (currentIndex < reviewQueue.lastIndex) {
                            currentIndex++
                            showBack = false
                        } else {
                            finished = true
                        }
                    }
                    OutlinedButton(
                        onClick = { advance(1) },
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = MindoraPalette.Danger),
                        modifier = Modifier.weight(1f).height(50.dp)
                    ) {
                        Text(if (isFr) "Difficile" else "Hard")
                    }
                    OutlinedButton(
                        onClick = { advance(3) },
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = MindoraPalette.Warning),
                        modifier = Modifier.weight(1f).height(50.dp)
                    ) {
                        Text(if (isFr) "Correct" else "Good")
                    }
                    Button(
                        onClick = { advance(5) },
                        colors = ButtonDefaults.buttonColors(containerColor = MindoraPalette.Success),
                        modifier = Modifier.weight(1f).height(50.dp)
                    ) {
                        Text(if (isFr) "Facile" else "Easy")
                    }
                }
            }
        }
    }
}
