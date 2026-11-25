package com.mindora.app.data

import kotlin.math.max
import kotlin.math.roundToInt

enum class ThemeModeSetting(val id: String) {
    SYSTEM("system"),
    LIGHT("light"),
    DARK("dark");

    companion object {
        fun fromId(id: String?): ThemeModeSetting = entries.find { it.id == id } ?: SYSTEM
    }
}

enum class AppLanguage(val code: String, val label: String) {
    EN("en", "English"),
    FR("fr", "Français");

    companion object {
        fun fromCode(code: String?): AppLanguage = entries.find { it.code == code } ?: EN
    }
}

data class MaintenanceStatus(
    val enabled: Boolean = false,
    val message: String = "",
    val eta: String? = null
)

data class UserProfile(
    val id: String = "",
    val fullName: String = "",
    val email: String = "",
    val isVerified: Boolean = false,
    val preferredLanguage: AppLanguage = AppLanguage.EN,
    val countryCode: String = "CM",
    val educationSystem: String = "Anglophone",
    val level: String = "GCE Advanced Level",
    val program: String = "Science",
    val subjects: List<String> = listOf("Mathematics", "Physics", "Computer Science"),
    val goal: String = "pass_exam",
    val targetExamDateMillis: Long = System.currentTimeMillis() + 42L * 86_400_000L,
    val studyWindows: List<String> = listOf("evening"),
    val explanationStyle: String = "standard",
    val allowNotifications: Boolean = true,
    val onboardingCompleted: Boolean = false
)

data class ExamCountdown(
    val examName: String,
    val targetDateMillis: Long,
    val daysRemaining: Int
)

data class TodayFocus(
    val sessionId: String,
    val title: String,
    val subject: String,
    val topic: String,
    val objective: String,
    val durationMinutes: Int
)

data class ReadinessBreakdown(
    val knowledge: Float = 0f,
    val practice: Float = 0f,
    val retention: Float = 0f,
    val consistency: Float = 0f
)

data class WeakTopic(
    val subject: String,
    val topic: String,
    val mastery: Float
)

data class TopicMasteryItem(
    val subject: String,
    val topic: String,
    val mastery: Float,
    val questionsSeen: Int,
    val questionsCorrect: Int,
    val minutesStudied: Int
)

data class RecentActivity(
    val sessionId: String,
    val title: String,
    val subject: String,
    val durationMinutes: Int,
    val completedAtMillis: Long
)

data class DashboardData(
    val streakDays: Int,
    val examCountdown: ExamCountdown?,
    val todayFocus: TodayFocus?,
    val readinessScore: Int,
    val readinessBreakdown: ReadinessBreakdown,
    val weakTopics: List<WeakTopic>,
    val recentActivity: List<RecentActivity>
)

data class StudySession(
    val id: String,
    val planId: String,
    val title: String,
    val subject: String,
    val topic: String,
    val objective: String,
    val scheduledForMillis: Long,
    val durationMinutes: Int,
    val status: String
) {
    val isCompleted: Boolean get() = status == "completed"
}

data class StudyPlan(
    val id: String,
    val planType: String,
    val title: String,
    val subject: String,
    val examSystem: String,
    val examLevel: String,
    val targetDateMillis: Long,
    val dailyMinutes: Int,
    val isActive: Boolean,
    val sessions: List<StudySession>
) {
    val daysRemaining: Int
        get() = max(0, ((targetDateMillis - System.currentTimeMillis()) / 86_400_000L).toInt())
}

data class ToolUsage(
    val name: String,
    val detail: String? = null
)

data class ChatMessage(
    val id: String,
    val role: String,
    val content: String,
    val attachmentLabel: String? = null,
    val toolsUsed: List<ToolUsage> = emptyList(),
    val createdAtMillis: Long = System.currentTimeMillis()
) {
    val isUser: Boolean get() = role == "user"
}

data class Conversation(
    val id: String,
    val title: String,
    val subject: String? = null,
    val messages: List<ChatMessage> = emptyList(),
    val updatedAtMillis: Long = System.currentTimeMillis()
)

data class Flashcard(
    val id: String,
    val deckId: String,
    val front: String,
    val back: String,
    val easeFactor: Double = 2.5,
    val intervalDays: Int = 0,
    val repetitions: Int = 0,
    val nextReviewAtMillis: Long = System.currentTimeMillis()
) {
    val isDue: Boolean get() = nextReviewAtMillis <= System.currentTimeMillis()
}

data class Deck(
    val id: String,
    val title: String,
    val subject: String,
    val description: String,
    val cards: List<Flashcard>,
    val serverCardCount: Int? = null,
    val serverDueCount: Int? = null
) {
    val cardCount: Int get() = serverCardCount ?: cards.size
    val dueCount: Int get() = serverDueCount ?: cards.count { it.isDue }
}

/**
 * SuperMemo 2 (SM-2) offline spaced repetition engine matching backend/python_api/app/services/sm2.py.
 */
object Sm2Engine {
    fun update(card: Flashcard, quality: Int, nowMillis: Long = System.currentTimeMillis()): Flashcard {
        val q = quality.coerceIn(0, 5)
        val rawEase = card.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        val newEase = ((max(1.3, rawEase)) * 100.0).roundToInt() / 100.0

        val newReps: Int
        val newInterval: Int
        if (q < 3) {
            newReps = 0
            newInterval = 1
        } else {
            newReps = card.repetitions + 1
            newInterval = when (newReps) {
                1 -> 1
                2 -> 6
                else -> (card.intervalDays * newEase).roundToInt().coerceAtLeast(1)
            }
        }
        val nextReview = nowMillis + newInterval.toLong() * 86_400_000L
        return card.copy(
            easeFactor = newEase,
            intervalDays = newInterval,
            repetitions = newReps,
            nextReviewAtMillis = nextReview
        )
    }
}

data class MockQuestionOption(
    val label: String,
    val text: String
)

data class MockQuestion(
    val id: String,
    val position: Int,
    val topic: String,
    val questionType: String,
    val prompt: String,
    val options: List<MockQuestionOption>,
    val correctAnswer: String? = null,
    val explanation: String? = null,
    val points: Int = 1
)

data class AnswerResult(
    val questionId: String,
    val userAnswer: String?,
    val isCorrect: Boolean,
    val correctAnswer: String,
    val explanation: String?
)

data class TopicStat(
    val total: Int,
    val correct: Int
)

data class MockExam(
    val id: String,
    val title: String,
    val subject: String,
    val academicLevel: String,
    val difficulty: String,
    val durationMinutes: Int,
    val status: String,
    val serverQuestionCount: Int = 0,
    val questions: List<MockQuestion> = emptyList(),
    val answers: Map<String, String> = emptyMap(),
    val answerResults: List<AnswerResult> = emptyList(),
    val topicBreakdown: Map<String, TopicStat> = emptyMap(),
    val score: Double? = null,
    val correctCount: Int? = null,
    val wrongCount: Int? = null,
    val skippedCount: Int? = null,
    val feedbackSummary: String? = null,
    val createdAtMillis: Long = System.currentTimeMillis()
) {
    val questionCount: Int get() = if (questions.isNotEmpty()) questions.size else serverQuestionCount
    val isReady: Boolean get() = status == "ready"
    val isInProgress: Boolean get() = status == "in_progress"
    val isGraded: Boolean get() = status == "graded"
}

data class PastPaper(
    val id: String,
    val title: String,
    val subject: String,
    val examSystem: String,
    val examLevel: String,
    val examYear: Int,
    val session: String,
    val language: String,
    val fileName: String,
    val fileSizeLabel: String,
    val downloadCount: Int,
    val localFilePath: String? = null
)

data class ContributedDocument(
    val id: String,
    val title: String,
    val subject: String,
    val examSystem: String,
    val examLevel: String,
    val description: String,
    val contentText: String,
    val fileName: String,
    val status: String,
    val creditsAwarded: Int,
    val createdAtMillis: Long = System.currentTimeMillis()
)

data class GroupMessage(
    val id: String,
    val senderName: String,
    val content: String,
    val isMe: Boolean,
    val sentAtMillis: Long = System.currentTimeMillis()
)

data class StudyGroup(
    val id: String,
    val name: String,
    val subject: String,
    val examLevel: String,
    val memberCount: Int,
    val isMember: Boolean = false,
    val messages: List<GroupMessage> = emptyList()
)

data class SubscriptionPlan(
    val id: String,
    val code: String,
    val name: String,
    val description: String,
    val tier: String,
    val amountMinor: Int,
    val currency: String,
    val billingCycle: String,
    val features: List<String>
)

data class ActiveSubscription(
    val id: String,
    val status: String,
    val planName: String,
    val tier: String,
    val periodEnd: String?
)

data class AppNotification(
    val id: String,
    val type: String,
    val title: String,
    val body: String,
    val isRead: Boolean,
    val createdAt: String?
)

data class NotificationPrefs(
    val enabled: Boolean = true,
    val sessionReminders: Boolean = true,
    val examCountdown: Boolean = true,
    val streakReminders: Boolean = true
)

data class SupportMessage(
    val id: String,
    val authorEmail: String?,
    val body: String,
    val isAdmin: Boolean,
    val createdAt: String?
)

data class SupportTicket(
    val id: String,
    val subject: String,
    val description: String,
    val status: String,
    val priority: String,
    val createdAt: String?,
    val messages: List<SupportMessage> = emptyList()
)
