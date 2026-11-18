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
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.mindora.app.data.Deck
import com.mindora.app.ui.components.AppBadge
import com.mindora.app.ui.components.AppEmptyState
import com.mindora.app.ui.components.AppSurface
import com.mindora.app.ui.components.BadgeTone
import com.mindora.app.ui.components.MindoraTopBar
import com.mindora.app.ui.theme.MindoraPalette

@Composable
fun FlashcardsScreen(
    decks: List<Deck>,
    onOpenDeck: (String) -> Unit,
    onCreateDeck: (title: String, subject: String, description: String) -> Unit,
    onAddCard: (deckId: String, front: String, back: String) -> Unit,
    onGenerateCards: (deckId: String, topic: String) -> Unit,
    onBack: () -> Unit
) {
    var showCreateDialog by remember { mutableStateOf(false) }
    var addCardDeckId by remember { mutableStateOf<String?>(null) }

    Scaffold(
        topBar = { MindoraTopBar(title = "Flashcards", onBack = onBack) },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { showCreateDialog = true },
                icon = { Icon(Icons.Default.Add, contentDescription = null) },
                text = { Text("New deck") }
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
                    title = "No decks yet",
                    message = "Create your first flashcard deck to start SM-2 spaced repetition.",
                    actionLabel = "Create deck",
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
                                        text = "${deck.cardCount} cards · ${deck.dueCount} due for review",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                                if (deck.dueCount > 0) {
                                    AppBadge(label = "${deck.dueCount} DUE", tone = BadgeTone.PRIMARY)
                                } else {
                                    AppBadge(label = "UP TO DATE", tone = BadgeTone.SUCCESS)
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
                                    Text("Add card")
                                }
                                OutlinedButton(
                                    onClick = { onGenerateCards(deck.id, deck.subject) },
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Icon(Icons.Outlined.AutoAwesome, contentDescription = null)
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("AI cards")
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
            title = { Text("New Deck") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedTextField(
                        value = title,
                        onValueChange = { title = it },
                        label = { Text("Deck title") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = subject,
                        onValueChange = { subject = it },
                        label = { Text("Subject") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = desc,
                        onValueChange = { desc = it },
                        label = { Text("Description (optional)") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (title.isNotBlank()) {
                            onCreateDeck(title, subject.ifBlank { "General" }, desc)
                            showCreateDialog = false
                        }
                    }
                ) { Text("Create") }
            },
            dismissButton = {
                TextButton(onClick = { showCreateDialog = false }) { Text("Cancel") }
            }
        )
    }

    addCardDeckId?.let { deckId ->
        var front by remember { mutableStateOf("") }
        var back by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { addCardDeckId = null },
            title = { Text("Add Flashcard") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedTextField(
                        value = front,
                        onValueChange = { front = it },
                        label = { Text("Question (front)") },
                        minLines = 2,
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = back,
                        onValueChange = { back = it },
                        label = { Text("Answer (back)") },
                        minLines = 2,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (front.isNotBlank() && back.isNotBlank()) {
                            onAddCard(deckId, front, back)
                            addCardDeckId = null
                        }
                    }
                ) { Text("Save card") }
            },
            dismissButton = {
                TextButton(onClick = { addCardDeckId = null }) { Text("Cancel") }
            }
        )
    }
}

@Composable
fun FlashcardReviewScreen(
    deck: Deck?,
    onReviewCard: (deckId: String, cardId: String, quality: Int) -> Unit,
    onBack: () -> Unit
) {
    if (deck == null) {
        Scaffold(topBar = { MindoraTopBar(title = "Review", onBack = onBack) }) { padding ->
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text("Deck not found.")
            }
        }
        return
    }

    val initialQueue = remember(deck.id) {
        val due = deck.cards.filter { it.isDue }
        due.ifEmpty { deck.cards }
    }
    var currentIndex by remember(deck.id) { mutableIntStateOf(0) }
    var showBack by remember(deck.id) { mutableStateOf(false) }
    var finished by remember(deck.id) { mutableStateOf(initialQueue.isEmpty()) }

    Scaffold(
        topBar = {
            MindoraTopBar(
                title = if (finished) deck.title else "Review ${currentIndex + 1}/${initialQueue.size}",
                onBack = onBack
            )
        }
    ) { padding ->
        if (finished || currentIndex >= initialQueue.size) {
            Box(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentAlignment = Alignment.Center
            ) {
                AppEmptyState(
                    icon = Icons.Outlined.Style,
                    title = "All cards are up to date!",
                    message = "SM-2 intervals have been updated based on your recall confidence.",
                    actionLabel = "Back to decks",
                    onAction = onBack
                )
            }
            return@Scaffold
        }

        val card = initialQueue[currentIndex]

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
                        text = if (showBack) "ANSWER" else "QUESTION",
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
                        text = "Tap card to flip · Ease ${card.easeFactor} · Interval ${card.intervalDays}d",
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
                    Text("Show answer")
                }
            } else {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = {
                            onReviewCard(deck.id, card.id, 1)
                            if (currentIndex < initialQueue.lastIndex) {
                                currentIndex++
                                showBack = false
                            } else finished = true
                        },
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = MindoraPalette.Danger),
                        modifier = Modifier.weight(1f).height(50.dp)
                    ) {
                        Text("Hard")
                    }
                    OutlinedButton(
                        onClick = {
                            onReviewCard(deck.id, card.id, 3)
                            if (currentIndex < initialQueue.lastIndex) {
                                currentIndex++
                                showBack = false
                            } else finished = true
                        },
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = MindoraPalette.Warning),
                        modifier = Modifier.weight(1f).height(50.dp)
                    ) {
                        Text("Good")
                    }
                    Button(
                        onClick = {
                            onReviewCard(deck.id, card.id, 5)
                            if (currentIndex < initialQueue.lastIndex) {
                                currentIndex++
                                showBack = false
                            } else finished = true
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = MindoraPalette.Success),
                        modifier = Modifier.weight(1f).height(50.dp)
                    ) {
                        Text("Easy")
                    }
                }
            }
        }
    }
}
