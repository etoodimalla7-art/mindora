package com.mindora.app.core.network

import com.google.gson.annotations.SerializedName

// --- Settings / Maintenance (Unauthenticated) ---

data class MaintenancePublicDto(
    val enabled: Boolean = false,
    val message: String = "",
    val eta: String? = null
)

data class PublicSettingsDto(
    val identity: Map<String, Any?> = emptyMap(),
    val languages: Map<String, Any?> = emptyMap(),
    @SerializedName("education_systems") val educationSystems: List<String> = emptyList(),
    val subjects: List<String> = emptyList(),
    val levels: List<String> = emptyList(),
    val maintenance: MaintenancePublicDto = MaintenancePublicDto(),
    val flags: Map<String, Boolean> = emptyMap(),
    @SerializedName("content_strings") val contentStrings: Map<String, Map<String, String>> = emptyMap()
)

// --- Auth & Users ---

data class LoginRequestDto(
    val email: String,
    val password: String
)

data class RegisterRequestDto(
    val email: String,
    val password: String,
    @SerializedName("full_name") val fullName: String? = null,
    @SerializedName("preferred_language") val preferredLanguage: String = "en",
    @SerializedName("country_code") val countryCode: String = "CM"
)

data class RefreshRequestDto(
    @SerializedName("refresh_token") val refreshToken: String
)

data class SendOtpRequestDto(
    val email: String,
    val purpose: String = "verify_email"
)

data class VerifyOtpRequestDto(
    val email: String,
    val code: String,
    val purpose: String = "verify_email"
)

data class SendOtpResponseDto(
    val status: String,
    val message: String
)

data class VerifyOtpResponseDto(
    val status: String,
    @SerializedName("is_verified") val isVerified: Boolean,
    val message: String
)

data class TokenPairDto(
    @SerializedName("access_token") val accessToken: String,
    @SerializedName("refresh_token") val refreshToken: String,
    @SerializedName("token_type") val tokenType: String = "bearer"
)

data class ProfileOutDto(
    @SerializedName("avatar_url") val avatarUrl: String? = null,
    val bio: String? = null,
    val timezone: String = "Africa/Douala",
    val preferences: Map<String, Any?> = emptyMap()
)

data class EducationProfileOutDto(
    @SerializedName("education_system") val educationSystem: String? = null,
    val level: String? = null,
    val program: String? = null,
    val subjects: List<String> = emptyList(),
    val goals: List<String> = emptyList(),
    @SerializedName("study_preferences") val studyPreferences: Map<String, Any?> = emptyMap(),
    @SerializedName("target_exam_date") val targetExamDate: String? = null
)

data class EducationUpdateDto(
    @SerializedName("education_system") val educationSystem: String? = null,
    val level: String? = null,
    val program: String? = null,
    val subjects: List<String>? = null,
    val goals: List<String>? = null,
    @SerializedName("study_preferences") val studyPreferences: Map<String, Any?>? = null,
    @SerializedName("target_exam_date") val targetExamDate: String? = null
)

data class UserOutDto(
    val id: String,
    val email: String,
    @SerializedName("full_name") val fullName: String? = null,
    @SerializedName("preferred_language") val preferredLanguage: String = "en",
    @SerializedName("country_code") val countryCode: String = "CM",
    @SerializedName("is_active") val isActive: Boolean = true,
    @SerializedName("is_verified") val isVerified: Boolean = false,
    @SerializedName("is_admin") val isAdmin: Boolean = false,
    @SerializedName("created_at") val createdAt: String? = null,
    val profile: ProfileOutDto? = null,
    @SerializedName("education_profile") val educationProfile: EducationProfileOutDto? = null
)

data class AuthResponseDto(
    val tokens: TokenPairDto,
    val user: UserOutDto
)

// --- Dashboard & Progress ---

data class ExamCountdownDto(
    @SerializedName("exam_name") val examName: String,
    @SerializedName("target_date") val targetDate: String,
    @SerializedName("days_remaining") val daysRemaining: Int
)

data class TodayFocusDto(
    @SerializedName("session_id") val sessionId: String? = null,
    val title: String? = null,
    val subject: String? = null,
    val topic: String? = null,
    val objective: String? = null,
    @SerializedName("duration_minutes") val durationMinutes: Int? = null,
    @SerializedName("scheduled_for") val scheduledFor: String? = null
)

data class ReadinessBreakdownDto(
    val knowledge: Float = 0f,
    val practice: Float = 0f,
    val retention: Float = 0f,
    val consistency: Float = 0f,
    @SerializedName("weak_topics") val weakTopics: Float = 0f
)

data class WeakTopicDto(
    val subject: String,
    val topic: String,
    val mastery: Float
)

data class RecentActivityDto(
    @SerializedName("session_id") val sessionId: String,
    val title: String,
    val subject: String? = null,
    @SerializedName("completed_at") val completedAt: String? = null,
    @SerializedName("duration_minutes") val durationMinutes: Int
)

data class DashboardResponseDto(
    @SerializedName("greeting_name") val greetingName: String? = null,
    @SerializedName("streak_days") val streakDays: Int = 0,
    @SerializedName("exam_countdown") val examCountdown: ExamCountdownDto? = null,
    @SerializedName("today_focus") val todayFocus: TodayFocusDto? = null,
    @SerializedName("readiness_score") val readinessScore: Int = 0,
    @SerializedName("readiness_breakdown") val readinessBreakdown: ReadinessBreakdownDto = ReadinessBreakdownDto(),
    @SerializedName("weak_topics") val weakTopics: List<WeakTopicDto> = emptyList(),
    @SerializedName("recent_activity") val recentActivity: List<RecentActivityDto> = emptyList()
)

data class TopicMasteryDto(
    val subject: String,
    val topic: String,
    val mastery: Float,
    val confidence: Float,
    @SerializedName("questions_seen") val questionsSeen: Int,
    @SerializedName("questions_correct") val questionsCorrect: Int,
    @SerializedName("minutes_studied") val minutesStudied: Int,
    @SerializedName("last_reviewed_at") val lastReviewedAt: String? = null
)

data class ProgressOverviewDto(
    @SerializedName("streak_days") val streakDays: Int = 0,
    @SerializedName("readiness_score") val readinessScore: Int = 0,
    @SerializedName("readiness_breakdown") val readinessBreakdown: ReadinessBreakdownDto = ReadinessBreakdownDto(),
    @SerializedName("total_minutes_studied") val totalMinutesStudied: Int = 0,
    @SerializedName("sessions_completed") val sessionsCompleted: Int = 0,
    @SerializedName("mock_exams_completed") val mockExamsCompleted: Int = 0,
    @SerializedName("average_exam_score") val averageExamScore: Double? = null,
    @SerializedName("weak_topics") val weakTopics: List<WeakTopicDto> = emptyList(),
    val topics: List<TopicMasteryDto> = emptyList()
)

// --- Planner ---

data class ExamPlanCreateDto(
    @SerializedName("exam_system") val examSystem: String,
    @SerializedName("exam_level") val examLevel: String,
    @SerializedName("exam_name") val examName: String,
    val subjects: List<String>,
    @SerializedName("target_date") val targetDate: String,
    @SerializedName("daily_minutes") val dailyMinutes: Int = 45
)

data class SubjectPlanCreateDto(
    val subject: String,
    val topic: String? = null,
    @SerializedName("duration_days") val durationDays: Int = 30,
    @SerializedName("daily_minutes") val dailyMinutes: Int = 45
)

data class StudySessionOutDto(
    val id: String,
    @SerializedName("plan_id") val planId: String? = null,
    val title: String,
    val subject: String? = null,
    val topic: String? = null,
    val objective: String? = null,
    @SerializedName("scheduled_for") val scheduledFor: String? = null,
    @SerializedName("duration_minutes") val durationMinutes: Int = 30,
    val status: String = "scheduled",
    @SerializedName("started_at") val startedAt: String? = null,
    @SerializedName("completed_at") val completedAt: String? = null
)

data class StudyPlanOutDto(
    val id: String,
    @SerializedName("plan_type") val planType: String,
    val title: String,
    val subject: String? = null,
    @SerializedName("exam_system") val examSystem: String? = null,
    @SerializedName("exam_level") val examLevel: String? = null,
    @SerializedName("exam_name") val examName: String? = null,
    @SerializedName("start_date") val startDate: String? = null,
    @SerializedName("target_date") val targetDate: String? = null,
    @SerializedName("daily_minutes") val dailyMinutes: Int = 45,
    @SerializedName("is_active") val isActive: Boolean = true,
    @SerializedName("created_at") val createdAt: String? = null,
    val sessions: List<StudySessionOutDto> = emptyList()
)

data class SessionCompleteDto(
    @SerializedName("confidence_after") val confidenceAfter: Float? = null,
    val notes: String? = null
)

// --- Documents & Past Papers & Credits ---

data class DocumentOutDto(
    val id: String,
    @SerializedName("owner_id") val ownerId: String,
    val title: String,
    val description: String,
    val category: String? = null,
    @SerializedName("academic_level") val academicLevel: String? = null,
    val language: String = "en",
    @SerializedName("is_exam_related") val isExamRelated: Boolean = false,
    @SerializedName("exam_system") val examSystem: String? = null,
    @SerializedName("exam_name") val examName: String? = null,
    @SerializedName("exam_year") val examYear: Int? = null,
    @SerializedName("original_filename") val originalFilename: String,
    @SerializedName("mime_type") val mimeType: String,
    @SerializedName("size_bytes") val sizeBytes: Long = 0,
    val status: String = "pending",
    @SerializedName("rejection_reason") val rejectionReason: String? = null,
    @SerializedName("download_count") val downloadCount: Int = 0,
    @SerializedName("created_at") val createdAt: String? = null
)

data class SubmitDocumentDto(
    val category: String? = null,
    @SerializedName("academic_level") val academicLevel: String? = null,
    val language: String? = null,
    @SerializedName("is_exam_related") val isExamRelated: Boolean = false,
    @SerializedName("exam_system") val examSystem: String? = null,
    @SerializedName("exam_name") val examName: String? = null
)

data class PaperRowDto(
    val id: String,
    val title: String,
    val subject: String,
    @SerializedName("exam_system") val examSystem: String,
    @SerializedName("exam_level") val examLevel: String,
    @SerializedName("exam_year") val examYear: Int? = null,
    val language: String = "en",
    val status: String = "published",
    @SerializedName("file_name") val fileName: String,
    @SerializedName("file_size") val fileSize: Long = 0L,
    @SerializedName("mime_type") val mimeType: String = "application/pdf",
    @SerializedName("download_count") val downloadCount: Int = 0,
    @SerializedName("created_at") val createdAt: String? = null
)

data class CreditBalanceOutDto(
    val balance: Int = 0,
    @SerializedName("signup_bonus") val signupBonus: Int = 5,
    @SerializedName("contribution_reward") val contributionReward: Int = 5,
    @SerializedName("download_cost") val downloadCost: Int = 1
)

// --- Flashcards ---

data class DeckCreateDto(
    val title: String,
    val description: String? = null,
    val subject: String? = null
)

data class DeckOutDto(
    val id: String,
    val title: String,
    val description: String? = null,
    val subject: String? = null,
    @SerializedName("card_count") val cardCount: Int = 0,
    @SerializedName("due_count") val dueCount: Int = 0,
    @SerializedName("created_at") val createdAt: String? = null
)

data class FlashcardCreateDto(
    val front: String,
    val back: String
)

data class FlashcardOutDto(
    val id: String,
    @SerializedName("deck_id") val deckId: String,
    val front: String,
    val back: String,
    @SerializedName("ease_factor") val easeFactor: Double = 2.5,
    @SerializedName("interval_days") val intervalDays: Int = 0,
    val repetitions: Int = 0,
    @SerializedName("next_review_at") val nextReviewAt: String? = null
)

data class ReviewCardRequestDto(
    val quality: Int
)

data class ReviewCardResponseDto(
    @SerializedName("card_id") val cardId: String,
    @SerializedName("ease_factor") val easeFactor: Double,
    @SerializedName("interval_days") val intervalDays: Int,
    val repetitions: Int,
    @SerializedName("next_review_at") val nextReviewAt: String
)

// --- Mock Exams (server-side grading: MockQuestionOutDto omits correct_answer!) ---

data class CreateMockExamDto(
    val title: String,
    val subject: String,
    @SerializedName("academic_level") val academicLevel: String? = null,
    @SerializedName("question_count") val questionCount: Int = 5,
    @SerializedName("duration_minutes") val durationMinutes: Int = 15,
    val difficulty: String = "medium",
    @SerializedName("source_document_ids") val sourceDocumentIds: List<String> = emptyList()
)

data class MockQuestionOptionDto(
    val label: String,
    val text: String
)

data class MockQuestionOutDto(
    val id: String,
    val position: Int,
    @SerializedName("question_type") val questionType: String,
    val prompt: String,
    val options: List<MockQuestionOptionDto> = emptyList(),
    val difficulty: String = "medium",
    val points: Int = 1
)

data class MockExamOutDto(
    val id: String,
    val title: String,
    val subject: String,
    @SerializedName("academic_level") val academicLevel: String? = null,
    @SerializedName("question_count") val questionCount: Int = 0,
    @SerializedName("duration_minutes") val durationMinutes: Int = 15,
    val difficulty: String = "medium",
    val status: String = "ready",
    val score: Double? = null,
    @SerializedName("correct_count") val correctCount: Int? = null,
    @SerializedName("wrong_count") val wrongCount: Int? = null,
    @SerializedName("skipped_count") val skippedCount: Int? = null,
    @SerializedName("created_at") val createdAt: String? = null
)

data class MockExamDetailDto(
    val id: String,
    val title: String,
    val subject: String,
    @SerializedName("academic_level") val academicLevel: String? = null,
    @SerializedName("question_count") val questionCount: Int = 0,
    @SerializedName("duration_minutes") val durationMinutes: Int = 15,
    val difficulty: String = "medium",
    val status: String = "ready",
    val score: Double? = null,
    @SerializedName("correct_count") val correctCount: Int? = null,
    @SerializedName("wrong_count") val wrongCount: Int? = null,
    @SerializedName("skipped_count") val skippedCount: Int? = null,
    @SerializedName("created_at") val createdAt: String? = null,
    val questions: List<MockQuestionOutDto> = emptyList()
)

data class SubmitAnswerDto(
    @SerializedName("question_id") val questionId: String,
    val answer: String,
    @SerializedName("time_spent_seconds") val timeSpentSeconds: Int? = null
)

data class AnswerResultDto(
    @SerializedName("question_id") val questionId: String,
    @SerializedName("user_answer") val userAnswer: String? = null,
    @SerializedName("is_correct") val isCorrect: Boolean? = null,
    @SerializedName("points_awarded") val pointsAwarded: Int = 0,
    @SerializedName("correct_answer") val correctAnswer: String,
    val explanation: String? = null,
    @SerializedName("ai_feedback") val aiFeedback: String? = null
)

data class MockExamResultsDto(
    val id: String,
    val title: String,
    val subject: String,
    @SerializedName("academic_level") val academicLevel: String? = null,
    @SerializedName("question_count") val questionCount: Int = 0,
    @SerializedName("duration_minutes") val durationMinutes: Int = 15,
    val difficulty: String = "medium",
    val status: String = "graded",
    val score: Double? = null,
    @SerializedName("correct_count") val correctCount: Int? = null,
    @SerializedName("wrong_count") val wrongCount: Int? = null,
    @SerializedName("skipped_count") val skippedCount: Int? = null,
    @SerializedName("created_at") val createdAt: String? = null,
    val answers: List<AnswerResultDto> = emptyList(),
    @SerializedName("feedback_summary") val feedbackSummary: String? = null,
    @SerializedName("topic_breakdown") val topicBreakdown: Map<String, Map<String, Int>> = emptyMap()
)

// --- AI Chat / Vision / Voice ---

data class ChatRequestDto(
    val message: String,
    @SerializedName("image_base64") val imageBase64: String? = null,
    @SerializedName("image_mime_type") val imageMimeType: String? = null,
    @SerializedName("conversation_id") val conversationId: String? = null,
    val subject: String? = null,
    @SerializedName("context_type") val contextType: String? = null
)

data class VisionAnalyzeRequestDto(
    @SerializedName("image_base64") val imageBase64: String,
    @SerializedName("image_mime_type") val imageMimeType: String = "image/jpeg",
    val prompt: String = "",
    val subject: String? = null,
    @SerializedName("conversation_id") val conversationId: String? = null
)

data class VoiceAnalyzeRequestDto(
    val transcript: String,
    val language: String = "fr",
    val subject: String? = null,
    @SerializedName("conversation_id") val conversationId: String? = null
)

data class MessageOutDto(
    val id: String,
    val role: String,
    val content: String,
    @SerializedName("tools_used") val toolsUsed: List<Map<String, Any?>> = emptyList(),
    val model: String? = null,
    val provider: String? = null,
    @SerializedName("created_at") val createdAt: String? = null
)

data class ChatResponseDto(
    @SerializedName("conversation_id") val conversationId: String,
    val message: MessageOutDto
)

data class VoiceResponseDto(
    @SerializedName("conversation_id") val conversationId: String,
    val message: MessageOutDto,
    @SerializedName("tts_text") val ttsText: String,
    @SerializedName("tts_locale") val ttsLocale: String
)

data class ConversationOutDto(
    val id: String,
    val title: String,
    val subject: String? = null,
    @SerializedName("message_count") val messageCount: Int = 0,
    @SerializedName("updated_at") val updatedAt: String? = null
)

data class ConversationDetailDto(
    val id: String,
    val title: String,
    val subject: String? = null,
    @SerializedName("message_count") val messageCount: Int = 0,
    @SerializedName("updated_at") val updatedAt: String? = null,
    val messages: List<MessageOutDto> = emptyList()
)

// --- Study Groups & DM ---

data class StudyGroupCreateDto(
    val name: String,
    val description: String? = null,
    @SerializedName("exam_system") val examSystem: String? = null,
    @SerializedName("exam_level") val examLevel: String? = null,
    val subject: String? = null
)

data class StudyGroupOutDto(
    val id: String,
    val name: String,
    val description: String? = null,
    @SerializedName("exam_system") val examSystem: String? = null,
    @SerializedName("exam_level") val examLevel: String? = null,
    val subject: String? = null,
    @SerializedName("creator_id") val creatorId: String,
    @SerializedName("member_count") val memberCount: Int = 1,
    @SerializedName("is_member") val isMember: Boolean = false
)

data class GroupMessageCreateDto(val content: String)

data class GroupMessageOutDto(
    val id: String,
    @SerializedName("group_id") val groupId: String,
    @SerializedName("user_id") val userId: String,
    val content: String,
    @SerializedName("created_at") val createdAt: String? = null,
    @SerializedName("user_name") val userName: String? = null
)

// --- Subscriptions & Payments ---

data class PlanOutDto(
    val id: String,
    val code: String,
    val name: String,
    val description: String? = null,
    val tier: String,
    @SerializedName("amount_minor") val amountMinor: Int,
    val currency: String,
    @SerializedName("billing_cycle") val billingCycle: String,
    val features: Map<String, Any?> = emptyMap(),
    @SerializedName("is_active") val isActive: Boolean = true
)

data class SubscriptionDetailDto(
    val id: String,
    val status: String,
    @SerializedName("current_period_end") val currentPeriodEnd: String? = null,
    val plan: PlanOutDto? = null
)

data class CheckoutRequestDto(
    @SerializedName("plan_code") val planCode: String
)

data class PaymentOutDto(
    val id: String,
    val status: String,
    @SerializedName("amount_minor") val amountMinor: Int,
    val currency: String,
    val reference: String
)

data class CheckoutResponseDto(
    val payment: PaymentOutDto,
    @SerializedName("checkout_url") val checkoutUrl: String,
    val provider: String
)

data class ConfirmRequestDto(val reference: String)

data class ConfirmResponseDto(
    val payment: PaymentOutDto,
    val subscription: SubscriptionDetailDto? = null,
    val status: String,
    val message: String
)

// --- Notifications & Support ---

data class NotificationOutDto(
    val id: String,
    val type: String,
    val title: String,
    val body: String,
    @SerializedName("read_at") val readAt: String? = null,
    @SerializedName("created_at") val createdAt: String? = null
)

data class NotificationPrefOutDto(
    val enabled: Boolean = true,
    @SerializedName("session_reminders") val sessionReminders: Boolean = true,
    @SerializedName("exam_countdown") val examCountdown: Boolean = true,
    @SerializedName("streak_reminders") val streakReminders: Boolean = true
)

data class NotificationPrefUpdateDto(
    val enabled: Boolean? = null,
    @SerializedName("session_reminders") val sessionReminders: Boolean? = null,
    @SerializedName("exam_countdown") val examCountdown: Boolean? = null,
    @SerializedName("streak_reminders") val streakReminders: Boolean? = null
)

data class TicketCreateDto(
    val subject: String,
    val description: String,
    val priority: String = "normal"
)

data class TicketRowDto(
    val id: String,
    val subject: String,
    val description: String,
    val status: String,
    val priority: String,
    @SerializedName("created_at") val createdAt: String? = null,
    @SerializedName("updated_at") val updatedAt: String? = null
)

data class SupportMessageOutDto(
    val id: String,
    @SerializedName("ticket_id") val ticketId: String,
    @SerializedName("author_email") val authorEmail: String? = null,
    val body: String,
    @SerializedName("is_admin") val isAdmin: Boolean = false,
    @SerializedName("created_at") val createdAt: String? = null
)

data class TicketDetailDto(
    val id: String,
    val subject: String,
    val description: String,
    val status: String,
    val priority: String,
    @SerializedName("created_at") val createdAt: String? = null,
    val messages: List<SupportMessageOutDto> = emptyList()
)

data class TicketRespondDto(val body: String)
