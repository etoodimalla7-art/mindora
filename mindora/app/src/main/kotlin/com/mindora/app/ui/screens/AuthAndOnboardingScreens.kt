package com.mindora.app.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.Build
import androidx.compose.material.icons.outlined.CalendarToday
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.MarkEmailRead
import androidx.compose.material.icons.outlined.Psychology
import androidx.compose.material.icons.outlined.School
import androidx.compose.material.icons.outlined.TrendingUp
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.mindora.app.data.AppLanguage
import com.mindora.app.data.MaintenanceStatus
import com.mindora.app.data.UserProfile
import com.mindora.app.ui.components.AppSurface
import com.mindora.app.ui.components.MindoraBrandLogo
import com.mindora.app.ui.components.MindoraTopBar
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

private data class WelcomeSlide(
    val icon: ImageVector,
    val titleEn: String,
    val titleFr: String,
    val descEn: String,
    val descFr: String
)

@Composable
fun MaintenanceScreen(
    maintenance: MaintenanceStatus,
    language: AppLanguage,
    onRetry: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    Scaffold { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Box(
                modifier = Modifier
                    .size(88.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Outlined.Build,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(44.dp)
                )
            }
            Spacer(modifier = Modifier.height(20.dp))
            Text(
                text = if (isFr) "Maintenance programmée" else "Scheduled Maintenance",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(10.dp))
            Text(
                text = maintenance.message.ifBlank {
                    if (isFr) "MINDORA est en cours de mise à jour. Réessayez dans quelques instants."
                    else "MINDORA is currently undergoing maintenance. Please check back shortly."
                },
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            if (!maintenance.eta.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "ETA: ${maintenance.eta}",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.primary
                )
            }
            Spacer(modifier = Modifier.height(24.dp))
            Button(onClick = onRetry, modifier = Modifier.fillMaxWidth().height(50.dp)) {
                Text(if (isFr) "Réessayer" else "Retry")
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun WelcomeScreen(
    language: AppLanguage,
    onLanguageToggle: (AppLanguage) -> Unit,
    onGoToRegister: () -> Unit,
    onGoToLogin: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    val slides = remember {
        listOf(
            WelcomeSlide(
                icon = Icons.Outlined.School,
                titleEn = "Welcome to MINDORA",
                titleFr = "Bienvenue sur MINDORA",
                descEn = "Your personal tutor to master GCE, BEPC, Bac, HND, and Bachelor exams.",
                descFr = "Ton tuteur personnel pour réussir tes examens. GCE, BEPC, Bac, HND, Licence — on t'accompagne."
            ),
            WelcomeSlide(
                icon = Icons.Outlined.Psychology,
                titleEn = "Intelligent AI Tutor",
                titleFr = "IA Tuteur Intelligent",
                descEn = "Ask questions, snap exercises, speak by voice, and get live streaming explanations.",
                descFr = "Pose tes questions, photographie un exercice ou parle à voix haute pour des explications en direct."
            ),
            WelcomeSlide(
                icon = Icons.Outlined.TrendingUp,
                titleEn = "Track Your Progress",
                titleFr = "Suis ta Progression",
                descEn = "Mock exams, spaced-repetition flashcards, and study streaks so you arrive ready on exam day.",
                descFr = "Mock exams, flashcards SM-2 et streaks — tout ce qu'il faut pour arriver prêt le jour J."
            )
        )
    }

    val pagerState = rememberPagerState(pageCount = { slides.size })
    val scope = rememberCoroutineScope()

    Scaffold { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                MindoraBrandLogo(size = 34.dp, showWordmark = true, wordmarkSize = 18)
                TextButton(onClick = {
                    onLanguageToggle(if (isFr) AppLanguage.EN else AppLanguage.FR)
                }) {
                    Text(if (isFr) "EN" else "FR")
                }
            }

            HorizontalPager(
                state = pagerState,
                modifier = Modifier.weight(1f)
            ) { page ->
                val slide = slides[page]
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 12.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Box(
                        modifier = Modifier
                            .size(144.dp)
                            .clip(CircleShape)
                            .background(
                                Brush.linearGradient(
                                    listOf(
                                        MaterialTheme.colorScheme.primary.copy(alpha = 0.2f),
                                        MaterialTheme.colorScheme.primary.copy(alpha = 0.05f)
                                    )
                                )
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = slide.icon,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(64.dp)
                        )
                    }
                    Spacer(modifier = Modifier.height(28.dp))
                    Text(
                        text = if (isFr) slide.titleFr else slide.titleEn,
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.ExtraBold,
                        textAlign = TextAlign.Center
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        text = if (isFr) slide.descFr else slide.descEn,
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center
                    )
                }
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center
            ) {
                repeat(slides.size) { index ->
                    val active = pagerState.currentPage == index
                    Box(
                        modifier = Modifier
                            .padding(horizontal = 4.dp)
                            .height(8.dp)
                            .width(if (active) 24.dp else 8.dp)
                            .clip(CircleShape)
                            .background(
                                if (active) MaterialTheme.colorScheme.primary
                                else MaterialTheme.colorScheme.primary.copy(alpha = 0.25f)
                            )
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = {
                    if (pagerState.currentPage < slides.lastIndex) {
                        scope.launch { pagerState.animateScrollToPage(pagerState.currentPage + 1) }
                    } else {
                        onGoToRegister()
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp)
            ) {
                val label = when {
                    pagerState.currentPage < slides.lastIndex -> if (isFr) "Suivant" else "Next"
                    else -> if (isFr) "Créer un compte" else "Get started"
                }
                Text(label)
            }

            Spacer(modifier = Modifier.height(8.dp))
            TextButton(
                onClick = onGoToLogin,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(if (isFr) "J'ai déjà un compte" else "I already have an account")
            }
        }
    }
}

@Composable
fun LoginScreen(
    language: AppLanguage,
    loading: Boolean,
    serverError: String?,
    onLogin: suspend (email: String, password: String) -> Result<Unit>,
    onGoToRegister: () -> Unit,
    onBack: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    val scope = rememberCoroutineScope()
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var obscure by remember { mutableStateOf(true) }
    var errorMsg by remember { mutableStateOf<String?>(null) }

    Scaffold(
        topBar = { MindoraTopBar(title = if (isFr) "Connexion" else "Sign in", onBack = onBack) }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp),
            verticalArrangement = Arrangement.Center
        ) {
            MindoraBrandLogo(size = 44.dp, showWordmark = true, wordmarkSize = 22)
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = if (isFr) "Connecte-toi pour synchroniser tes révisions, flashcards et tuteur IA."
                else "Sign in to sync your study plans, flashcards, and AI tutor sessions.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(24.dp))

            OutlinedTextField(
                value = email,
                onValueChange = { email = it; errorMsg = null },
                label = { Text("Email") },
                placeholder = { Text("student@mindora.dev") },
                singleLine = true,
                enabled = !loading,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(14.dp))
            OutlinedTextField(
                value = password,
                onValueChange = { password = it; errorMsg = null },
                label = { Text(if (isFr) "Mot de passe" else "Password") },
                singleLine = true,
                enabled = !loading,
                visualTransformation = if (obscure) PasswordVisualTransformation() else VisualTransformation.None,
                trailingIcon = {
                    IconButton(onClick = { obscure = !obscure }) {
                        Icon(
                            imageVector = if (obscure) Icons.Outlined.VisibilityOff else Icons.Outlined.Visibility,
                            contentDescription = "Toggle password visibility"
                        )
                    }
                },
                modifier = Modifier.fillMaxWidth()
            )

            val shownError = errorMsg ?: serverError
            if (!shownError.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = shownError,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall
                )
            }
            Spacer(modifier = Modifier.height(20.dp))

            Button(
                onClick = {
                    if (!email.contains("@") || password.length < 4) {
                        errorMsg = if (isFr) "Entre un email valide et un mot de passe." else "Enter a valid email and password."
                    } else {
                        scope.launch {
                            onLogin(email, password)
                        }
                    }
                },
                enabled = !loading,
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
                    Text(if (isFr) "Se connecter" else "Sign in")
                }
            }

            Spacer(modifier = Modifier.height(12.dp))
            OutlinedButton(
                onClick = onGoToRegister,
                enabled = !loading,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp)
            ) {
                Text(if (isFr) "Créer un compte" else "Create an account")
            }
        }
    }
}

@Composable
fun RegisterScreen(
    language: AppLanguage,
    loading: Boolean,
    serverError: String?,
    onRegister: suspend (fullName: String, email: String, password: String) -> Result<Unit>,
    onBack: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    val scope = rememberCoroutineScope()
    var fullName by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var obscure by remember { mutableStateOf(true) }
    var errorMsg by remember { mutableStateOf<String?>(null) }

    Scaffold(
        topBar = { MindoraTopBar(title = if (isFr) "Créer un compte" else "Create account", onBack = onBack) }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp),
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = if (isFr) "Rejoindre MINDORA" else "Join MINDORA",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = if (isFr) "Personnalise ta préparation aux examens en moins d'une minute."
                else "Personalize your exam preparation in under a minute.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(20.dp))

            OutlinedTextField(
                value = fullName,
                onValueChange = { fullName = it; errorMsg = null },
                label = { Text(if (isFr) "Nom complet" else "Full name") },
                singleLine = true,
                enabled = !loading,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(12.dp))
            OutlinedTextField(
                value = email,
                onValueChange = { email = it; errorMsg = null },
                label = { Text("Email") },
                singleLine = true,
                enabled = !loading,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(12.dp))
            OutlinedTextField(
                value = password,
                onValueChange = { password = it; errorMsg = null },
                label = { Text(if (isFr) "Mot de passe (8+ caractères)" else "Password (8+ characters)") },
                singleLine = true,
                enabled = !loading,
                visualTransformation = if (obscure) PasswordVisualTransformation() else VisualTransformation.None,
                trailingIcon = {
                    IconButton(onClick = { obscure = !obscure }) {
                        Icon(
                            imageVector = if (obscure) Icons.Outlined.VisibilityOff else Icons.Outlined.Visibility,
                            contentDescription = "Toggle password visibility"
                        )
                    }
                },
                modifier = Modifier.fillMaxWidth()
            )
            val shownError = errorMsg ?: serverError
            if (!shownError.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = shownError,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall
                )
            }
            Spacer(modifier = Modifier.height(20.dp))
            Button(
                onClick = {
                    if (fullName.trim().length < 2 || !email.contains("@") || password.length < 8) {
                        errorMsg = if (isFr) "Entre ton nom, un email valide et 8+ caractères."
                        else "Enter your name, a valid email, and an 8+ character password."
                    } else {
                        scope.launch {
                            onRegister(fullName.trim(), email.trim(), password)
                        }
                    }
                },
                enabled = !loading,
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
                    Text(if (isFr) "Continuer" else "Continue")
                }
            }
        }
    }
}

@Composable
fun VerifyOtpScreen(
    email: String,
    language: AppLanguage,
    loading: Boolean,
    errorMessage: String?,
    onVerify: suspend (String, String) -> Result<Unit>,
    onResend: suspend (String) -> Result<String>,
    onSkip: () -> Unit
) {
    val isFr = language == AppLanguage.FR
    val scope = rememberCoroutineScope()
    var code by remember { mutableStateOf("") }
    var infoMsg by remember { mutableStateOf<String?>(null) }

    Scaffold(
        topBar = { MindoraTopBar(title = if (isFr) "Vérification Email" else "Verify Email") }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Outlined.MarkEmailRead,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(56.dp)
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = if (isFr) "Code à 6 chiffres envoyé à" else "6-digit code sent to",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(email, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(20.dp))

            OutlinedTextField(
                value = code,
                onValueChange = { if (it.length <= 6 && it.all { c -> c.isDigit() }) code = it },
                label = { Text(if (isFr) "Code OTP (6 chiffres)" else "6-digit OTP code") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            if (!errorMessage.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(errorMessage, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
            }
            if (!infoMsg.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(infoMsg!!, color = MaterialTheme.colorScheme.primary, style = MaterialTheme.typography.bodySmall)
            }
            Spacer(modifier = Modifier.height(20.dp))
            Button(
                onClick = { scope.launch { onVerify(email, code) } },
                enabled = !loading && code.length == 6,
                modifier = Modifier.fillMaxWidth().height(50.dp)
            ) {
                Text(if (isFr) "Valider le code" else "Verify code")
            }
            Spacer(modifier = Modifier.height(8.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                TextButton(onClick = {
                    scope.launch {
                        onResend(email).onSuccess { infoMsg = it }
                    }
                }) {
                    Text(if (isFr) "Renvoyer le code" else "Resend code")
                }
                TextButton(onClick = onSkip) {
                    Text(if (isFr) "Plus tard" else "Verify later")
                }
            }
        }
    }
}

private enum class OnboardingStep(val titleEn: String, val titleFr: String, val subEn: String, val subFr: String) {
    LANGUAGE("Choose your language", "Choisis ta langue", "You can switch between English and French anytime.", "Tu peux changer entre français et anglais à tout moment."),
    COUNTRY("Your country", "Ton pays", "Helps tailor past papers and curriculum standards.", "Adapte les annales et le programme officiel."),
    SYSTEM("Education system", "Système éducatif", "Select your academic track.", "Sélectionne ta filière."),
    LEVEL("Academic level", "Niveau scolaire", "Pick the examination or degree you are preparing for.", "Choisis l'examen ou le diplôme préparé."),
    SUBJECTS("Select your subjects", "Tes matières", "Choose one or more subjects to focus on.", "Choisis une ou plusieurs matières principales."),
    GOAL("Primary study goal", "Objectif principal", "What matters most right now?", "Quelle est ta priorité actuelle ?"),
    EXAM_DATE("Target exam date", "Date cible de l'examen", "Set your countdown horizon.", "Définis ton compte à rebours."),
    PREFERENCES("Study windows & alerts", "Créneaux & rappels", "When do you learn best?", "À quel moment préfères-tu réviser ?"),
    AI_STYLE("AI Tutor style", "Style du Tuteur IA", "How should MINDORA explain concepts?", "Comment MINDORA doit-il t'expliquer ?"),
    DONE("Your plan is ready", "Ton profil est prêt", "Tap Finish to open your dashboard.", "Appuie sur Terminer pour ouvrir ton tableau de bord.")
}

@Composable
fun OnboardingWizardScreen(
    initialProfile: UserProfile,
    onLanguageChanged: (AppLanguage) -> Unit,
    onFinish: suspend (UserProfile) -> Unit
) {
    val scope = rememberCoroutineScope()
    var stepIndex by remember { mutableIntStateOf(0) }
    var language by remember { mutableStateOf(initialProfile.preferredLanguage) }
    var country by remember { mutableStateOf(initialProfile.countryCode) }
    var system by remember { mutableStateOf(initialProfile.educationSystem) }
    var level by remember { mutableStateOf(initialProfile.level) }
    var subjects by remember { mutableStateOf(initialProfile.subjects) }
    var customSubject by remember { mutableStateOf("") }
    var goal by remember { mutableStateOf(initialProfile.goal) }
    var daysOut by remember { mutableIntStateOf(42) }
    var studyWindows by remember { mutableStateOf(initialProfile.studyWindows) }
    var allowNotifications by remember { mutableStateOf(initialProfile.allowNotifications) }
    var explanationStyle by remember { mutableStateOf(initialProfile.explanationStyle) }

    val isFr = language == AppLanguage.FR
    val steps = OnboardingStep.entries
    val step = steps[stepIndex]
    val progress = (stepIndex + 1f) / steps.size.toFloat()

    Scaffold { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (stepIndex > 0) {
                    IconButton(onClick = { stepIndex-- }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                } else {
                    Spacer(modifier = Modifier.width(48.dp))
                }
                LinearProgressIndicator(
                    progress = { progress },
                    modifier = Modifier
                        .weight(1f)
                        .height(6.dp)
                        .clip(CircleShape)
                )
                TextButton(onClick = { stepIndex = steps.lastIndex }) {
                    Text(if (isFr) "Passer" else "Skip")
                }
            }

            Spacer(modifier = Modifier.height(24.dp))
            Text(text = if (isFr) step.titleFr else step.titleEn, style = MaterialTheme.typography.headlineSmall)
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = if (isFr) step.subFr else step.subEn,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(20.dp))

            Box(modifier = Modifier.weight(1f)) {
                when (step) {
                    OnboardingStep.LANGUAGE -> ChoiceList(
                        options = listOf(
                            Triple("en", "English", "Continue in English"),
                            Triple("fr", "Français", "Continuer en français")
                        ),
                        selected = language.code,
                        onSelect = {
                            val lang = AppLanguage.fromCode(it)
                            language = lang
                            onLanguageChanged(lang)
                        }
                    )

                    OnboardingStep.COUNTRY -> ChoiceList(
                        options = listOf(
                            Triple("CM", "Cameroon / Cameroun", "MINESEC / GCE Board"),
                            Triple("NG", "Nigeria", "WAEC / NECO"),
                            Triple("GH", "Ghana", "WASSCE")
                        ),
                        selected = country,
                        onSelect = { country = it }
                    )

                    OnboardingStep.SYSTEM -> ChoiceList(
                        options = listOf(
                            Triple("Anglophone", "Anglophone", "GCE O-Level, A-Level, HND, Bachelor"),
                            Triple("Francophone", "Francophone", "BEPC, Probatoire, Baccalauréat, BTS, Licence")
                        ),
                        selected = system,
                        onSelect = {
                            system = it
                            level = if (it == "Anglophone") "GCE Advanced Level" else "Baccalauréat"
                        }
                    )

                    OnboardingStep.LEVEL -> {
                        val levelOpts = if (system == "Anglophone") {
                            listOf(
                                Triple("GCE Ordinary Level", "GCE Ordinary Level", null),
                                Triple("GCE Advanced Level", "GCE Advanced Level", null),
                                Triple("HND", "HND", null),
                                Triple("Bachelor", "Bachelor", null),
                                Triple("Master", "Master", null)
                            )
                        } else {
                            listOf(
                                Triple("BEPC", "BEPC", null),
                                Triple("Probatoire", "Probatoire", null),
                                Triple("Baccalauréat", "Baccalauréat", null),
                                Triple("BTS", "BTS", null),
                                Triple("Licence", "Licence", null),
                                Triple("Master", "Master", null)
                            )
                        }
                        ChoiceList(options = levelOpts, selected = level, onSelect = { level = it })
                    }

                    OnboardingStep.SUBJECTS -> {
                        val allSubjects = listOf(
                            "Mathematics", "Physics", "Chemistry", "Biology",
                            "Computer Science", "Economics", "English", "French", "Mathématiques"
                        )
                        Column(modifier = Modifier.fillMaxSize()) {
                            LazyColumn(
                                modifier = Modifier.weight(1f),
                                verticalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                                items(allSubjects) { subj ->
                                    val checked = subjects.contains(subj)
                                    SelectableTile(
                                        title = subj,
                                        subtitle = null,
                                        selected = checked,
                                        isMulti = true,
                                        onClick = {
                                            subjects = if (checked) subjects - subj else subjects + subj
                                        }
                                    )
                                }
                            }
                            Spacer(modifier = Modifier.height(10.dp))
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                OutlinedTextField(
                                    value = customSubject,
                                    onValueChange = { customSubject = it },
                                    placeholder = { Text(if (isFr) "Ajouter une matière" else "Add another subject") },
                                    singleLine = true,
                                    modifier = Modifier.weight(1f)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                IconButton(
                                    onClick = {
                                        val trimmed = customSubject.trim()
                                        if (trimmed.isNotEmpty() && !subjects.contains(trimmed)) {
                                            subjects = subjects + trimmed
                                            customSubject = ""
                                        }
                                    }
                                ) {
                                    Icon(Icons.Default.Check, contentDescription = "Add subject")
                                }
                            }
                        }
                    }

                    OnboardingStep.GOAL -> ChoiceList(
                        options = listOf(
                            Triple("pass_exam", if (isFr) "Réussir mon examen" else "Pass my examination", if (isFr) "Révisions ciblées & examens blancs" else "Focused revision & mock exams"),
                            Triple("improve_grades", if (isFr) "Améliorer mes notes" else "Improve my grades", if (isFr) "Renforcer les chapitres faibles" else "Strengthen weak topics"),
                            Triple("learn_deeply", if (isFr) "Maîtriser en profondeur" else "Learn deeply", if (isFr) "Comprendre les notions clés" else "Master underlying concepts"),
                            Triple("short_revision", if (isFr) "Révision rapide" else "Quick revision", if (isFr) "Fiches synthétiques & flashcards" else "Condensed summaries & flashcards")
                        ),
                        selected = goal,
                        onSelect = { goal = it }
                    )

                    OnboardingStep.EXAM_DATE -> {
                        val targetMillis = System.currentTimeMillis() + daysOut.toLong() * 86_400_000L
                        val formatted = SimpleDateFormat("MMMM d, yyyy", Locale.getDefault()).format(Date(targetMillis))
                        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            AppSurface {
                                Row(
                                    modifier = Modifier.padding(18.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(Icons.Outlined.CalendarToday, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                                    Spacer(modifier = Modifier.width(12.dp))
                                    Column {
                                        Text("$daysOut ${if (isFr) "jours restants" else "days from today"}", style = MaterialTheme.typography.titleMedium)
                                        Text(formatted, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    }
                                }
                            }
                            ChoiceList(
                                options = listOf(
                                    Triple("14", if (isFr) "2 semaines" else "2 weeks", "Sprint"),
                                    Triple("30", if (isFr) "1 mois" else "1 month", if (isFr) "Préparation ciblée" else "Focused preparation"),
                                    Triple("42", if (isFr) "6 semaines" else "6 weeks", if (isFr) "Rythme équilibré" else "Balanced exam prep"),
                                    Triple("90", if (isFr) "3 mois" else "3 months", if (isFr) "Programme complet" else "Full syllabus mastery")
                                ),
                                selected = daysOut.toString(),
                                onSelect = { daysOut = it.toIntOrNull() ?: 42 }
                            )
                        }
                    }

                    OnboardingStep.PREFERENCES -> {
                        val windows = listOf(
                            "morning" to (if (isFr) "Matin (6h – 11h)" else "Morning (6am – 11am)"),
                            "afternoon" to (if (isFr) "Après-midi (11h – 17h)" else "Afternoon (11am – 5pm)"),
                            "evening" to (if (isFr) "Soir (17h – 21h)" else "Evening (5pm – 9pm)"),
                            "night" to (if (isFr) "Nuit (21h – 00h)" else "Night (9pm – 12am)")
                        )
                        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                            windows.forEach { (key, label) ->
                                val selected = studyWindows.contains(key)
                                SelectableTile(
                                    title = label,
                                    subtitle = null,
                                    selected = selected,
                                    isMulti = true,
                                    onClick = {
                                        studyWindows = if (selected) studyWindows - key else studyWindows + key
                                    }
                                )
                            }
                            Spacer(modifier = Modifier.height(6.dp))
                            AppSurface {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(horizontal = 16.dp, vertical = 12.dp),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(if (isFr) "Activer les rappels d'étude" else "Enable study reminders", style = MaterialTheme.typography.titleSmall)
                                    Switch(
                                        checked = allowNotifications,
                                        onCheckedChange = { allowNotifications = it }
                                    )
                                }
                            }
                        }
                    }

                    OnboardingStep.AI_STYLE -> ChoiceList(
                        options = listOf(
                            Triple("concise", if (isFr) "Concis" else "Concise", if (isFr) "Réponses directes" else "Short, direct answers"),
                            Triple("standard", "Standard", if (isFr) "Explications équilibrées" else "Balanced explanations"),
                            Triple("detailed", if (isFr) "Détaillé" else "Detailed", if (isFr) "Étapes complètes" else "Step-by-step depth"),
                            Triple("socratic", if (isFr) "Socratique" else "Socratic", if (isFr) "Questions guidées" else "Guided questions")
                        ),
                        selected = explanationStyle,
                        onSelect = { explanationStyle = it }
                    )

                    OnboardingStep.DONE -> Column(
                        modifier = Modifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Box(
                            modifier = Modifier
                                .size(92.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.CheckCircle,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(48.dp)
                            )
                        }
                        Spacer(modifier = Modifier.height(20.dp))
                        Text(if (isFr) "Ton profil est prêt !" else "Your profile is ready.", style = MaterialTheme.typography.titleLarge)
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = if (isFr) "Appuie sur Terminer pour accéder à ton espace." else "Tap Finish to open your dashboard.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
            Button(
                onClick = {
                    if (stepIndex < steps.lastIndex) {
                        stepIndex++
                    } else {
                        scope.launch {
                            onFinish(
                                initialProfile.copy(
                                    preferredLanguage = language,
                                    countryCode = country,
                                    educationSystem = system,
                                    level = level,
                                    subjects = subjects.ifEmpty { listOf("Mathematics") },
                                    goal = goal,
                                    targetExamDateMillis = System.currentTimeMillis() + daysOut.toLong() * 86_400_000L,
                                    studyWindows = studyWindows.ifEmpty { listOf("evening") },
                                    allowNotifications = allowNotifications,
                                    explanationStyle = explanationStyle,
                                    onboardingCompleted = true
                                )
                            )
                        }
                    }
                },
                enabled = step != OnboardingStep.SUBJECTS || subjects.isNotEmpty(),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp)
            ) {
                if (stepIndex == steps.lastIndex) {
                    Icon(Icons.Outlined.AutoAwesome, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(if (isFr) "Terminer" else "Finish")
                } else {
                    Text(if (isFr) "Continuer" else "Continue")
                }
            }
        }
    }
}

@Composable
private fun ChoiceList(
    options: List<Triple<String, String, String?>>,
    selected: String?,
    onSelect: (String) -> Unit
) {
    LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        items(options) { (value, label, sub) ->
            SelectableTile(
                title = label,
                subtitle = sub,
                selected = selected == value,
                isMulti = false,
                onClick = { onSelect(value) }
            )
        }
    }
}

@Composable
private fun SelectableTile(
    title: String,
    subtitle: String?,
    selected: Boolean,
    isMulti: Boolean,
    onClick: () -> Unit
) {
    val borderColor = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline.copy(alpha = 0.6f)
    val bgColor = if (selected) MaterialTheme.colorScheme.primary.copy(alpha = 0.08f) else MaterialTheme.colorScheme.surface
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(14.dp),
        color = bgColor,
        border = BorderStroke(if (selected) 1.5.dp else 1.dp, borderColor)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(text = title, style = MaterialTheme.typography.titleMedium)
                if (!subtitle.isNullOrBlank()) {
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            if (isMulti) {
                Checkbox(checked = selected, onCheckedChange = { onClick() })
            } else {
                RadioButton(selected = selected, onClick = onClick)
            }
        }
    }
}
