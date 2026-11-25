package com.mindora.app.core.network

import okhttp3.MultipartBody
import okhttp3.RequestBody
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.Multipart
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Part
import retrofit2.http.Path
import retrofit2.http.Query
import retrofit2.http.Streaming

interface MindoraApiService {

    // --- Public Settings & Maintenance ---
    @GET("settings/maintenance")
    suspend fun getMaintenance(): MaintenancePublicDto

    @GET("settings/public")
    suspend fun getPublicSettings(): PublicSettingsDto

    // --- Auth & OTP ---
    @POST("auth/login")
    suspend fun login(@Body req: LoginRequestDto): AuthResponseDto

    @POST("auth/register")
    suspend fun register(@Body req: RegisterRequestDto): AuthResponseDto

    @POST("auth/refresh")
    suspend fun refresh(@Body req: RefreshRequestDto): AuthResponseDto

    @POST("auth/logout")
    suspend fun logout(@Body req: RefreshRequestDto): Response<Unit>

    @POST("auth/send-otp")
    suspend fun sendOtp(@Body req: SendOtpRequestDto): SendOtpResponseDto

    @POST("auth/verify-otp")
    suspend fun verifyOtp(@Body req: VerifyOtpRequestDto): VerifyOtpResponseDto

    // --- User Profile ---
    @GET("users/me")
    suspend fun getMe(): UserOutDto

    @PUT("users/me/education")
    suspend fun updateEducation(@Body payload: EducationUpdateDto): UserOutDto

    // --- Dashboard & Progress ---
    @GET("dashboard")
    suspend fun getDashboard(): DashboardResponseDto

    @GET("progress/overview")
    suspend fun getProgressOverview(): ProgressOverviewDto

    // --- Planner ---
    @GET("planner/plans")
    suspend fun listPlans(): List<StudyPlanOutDto>

    @GET("planner/plans/{planId}")
    suspend fun getPlan(@Path("planId") planId: String): StudyPlanOutDto

    @POST("planner/exam")
    suspend fun createExamPlan(@Body payload: ExamPlanCreateDto): StudyPlanOutDto

    @POST("planner/subject")
    suspend fun createSubjectPlan(@Body payload: SubjectPlanCreateDto): StudyPlanOutDto

    @GET("planner/sessions")
    suspend fun upcomingSessions(): List<StudySessionOutDto>

    @POST("planner/sessions/{sessionId}/start")
    suspend fun startSession(@Path("sessionId") sessionId: String): StudySessionOutDto

    @POST("planner/sessions/{sessionId}/complete")
    suspend fun completeSession(
        @Path("sessionId") sessionId: String,
        @Body payload: SessionCompleteDto = SessionCompleteDto()
    ): StudySessionOutDto

    // --- Past Papers & Documents & Credits ---
    @GET("papers")
    suspend fun listPapers(
        @Query("exam_system") examSystem: String? = null,
        @Query("exam_level") examLevel: String? = null,
        @Query("subject") subject: String? = null,
        @Query("search") search: String? = null
    ): List<PaperRowDto>

    @Streaming
    @GET("papers/{paperId}/download")
    suspend fun downloadPaper(@Path("paperId") paperId: String): ResponseBody

    @GET("credits")
    suspend fun getCreditsBalance(): CreditBalanceOutDto

    @GET("documents")
    suspend fun listMyDocuments(): List<DocumentOutDto>

    @GET("documents/library")
    suspend fun listDocumentLibrary(): List<DocumentOutDto>

    @Multipart
    @POST("documents/upload")
    suspend fun uploadDocument(
        @Part file: MultipartBody.Part,
        @Part("title") title: RequestBody,
        @Part("description") description: RequestBody
    ): DocumentOutDto

    @POST("documents/{docId}/submit")
    suspend fun submitDocumentMetadata(
        @Path("docId") docId: String,
        @Body payload: SubmitDocumentDto
    ): DocumentOutDto

    // --- Flashcards ---
    @GET("flashcards/decks")
    suspend fun listDecks(): List<DeckOutDto>

    @POST("flashcards/decks")
    suspend fun createDeck(@Body payload: DeckCreateDto): DeckOutDto

    @GET("flashcards/decks/{deckId}/cards/due")
    suspend fun getDueCards(
        @Path("deckId") deckId: String,
        @Query("limit") limit: Int = 50
    ): List<FlashcardOutDto>

    @POST("flashcards/decks/{deckId}/cards")
    suspend fun addCard(
        @Path("deckId") deckId: String,
        @Body payload: FlashcardCreateDto
    ): FlashcardOutDto

    @POST("flashcards/cards/{cardId}/review")
    suspend fun reviewCard(
        @Path("cardId") cardId: String,
        @Body payload: ReviewCardRequestDto
    ): ReviewCardResponseDto

    // --- Mock Exams (server-side grading) ---
    @GET("mock-exams")
    suspend fun listMockExams(): List<MockExamOutDto>

    @POST("mock-exams")
    suspend fun createMockExam(@Body payload: CreateMockExamDto): MockExamDetailDto

    @GET("mock-exams/{examId}")
    suspend fun getMockExam(@Path("examId") examId: String): MockExamDetailDto

    @POST("mock-exams/{examId}/start")
    suspend fun startMockExam(@Path("examId") examId: String): MockExamDetailDto

    @POST("mock-exams/{examId}/answer")
    suspend fun submitExamAnswer(
        @Path("examId") examId: String,
        @Body payload: SubmitAnswerDto
    ): MockExamDetailDto

    @POST("mock-exams/{examId}/submit")
    suspend fun submitMockExam(@Path("examId") examId: String): MockExamResultsDto

    @GET("mock-exams/{examId}/results")
    suspend fun getMockExamResults(@Path("examId") examId: String): MockExamResultsDto

    // --- AI Tutor ---
    @POST("ai/chat")
    suspend fun sendAiChat(@Body payload: ChatRequestDto): ChatResponseDto

    @POST("ai/vision")
    suspend fun sendAiVision(@Body payload: VisionAnalyzeRequestDto): ChatResponseDto

    @POST("ai/voice")
    suspend fun sendAiVoice(@Body payload: VoiceAnalyzeRequestDto): VoiceResponseDto

    @GET("ai/conversations")
    suspend fun listAiConversations(): List<ConversationOutDto>

    @GET("ai/conversations/{conversationId}")
    suspend fun getAiConversation(@Path("conversationId") id: String): ConversationDetailDto

    @DELETE("ai/conversations/{conversationId}")
    suspend fun deleteAiConversation(@Path("conversationId") id: String): Response<Unit>

    // --- Study Groups ---
    @GET("study-groups")
    suspend fun listStudyGroups(): List<StudyGroupOutDto>

    @POST("study-groups")
    suspend fun createStudyGroup(@Body payload: StudyGroupCreateDto): StudyGroupOutDto

    @POST("study-groups/{groupId}/join")
    suspend fun joinStudyGroup(@Path("groupId") groupId: String): StudyGroupOutDto

    @POST("study-groups/{groupId}/leave")
    suspend fun leaveStudyGroup(@Path("groupId") groupId: String): Response<Unit>

    @GET("study-groups/{groupId}/messages")
    suspend fun listGroupMessages(@Path("groupId") groupId: String): List<GroupMessageOutDto>

    @POST("study-groups/{groupId}/messages")
    suspend fun postGroupMessage(
        @Path("groupId") groupId: String,
        @Body payload: GroupMessageCreateDto
    ): GroupMessageOutDto

    // --- Subscriptions ---
    @GET("subscriptions/plans/public")
    suspend fun listPublicPlans(): List<PlanOutDto>

    @GET("subscriptions/me")
    suspend fun getMySubscription(): SubscriptionDetailDto?

    @POST("subscriptions/checkout")
    suspend fun startCheckout(@Body payload: CheckoutRequestDto): CheckoutResponseDto

    @POST("subscriptions/confirm")
    suspend fun confirmPayment(@Body payload: ConfirmRequestDto): ConfirmResponseDto

    @POST("subscriptions/cancel")
    suspend fun cancelSubscription(): Response<Unit>

    // --- Notifications ---
    @GET("notifications")
    suspend fun listNotifications(): List<NotificationOutDto>

    @POST("notifications/{notificationId}/read")
    suspend fun markNotificationRead(@Path("notificationId") id: String): NotificationOutDto

    @GET("notifications/preferences")
    suspend fun getNotificationPrefs(): NotificationPrefOutDto

    @PATCH("notifications/preferences")
    suspend fun updateNotificationPrefs(@Body payload: NotificationPrefUpdateDto): NotificationPrefOutDto

    // --- Support Tickets ---
    @GET("support/tickets/mine")
    suspend fun listMyTickets(): List<TicketRowDto>

    @POST("support/tickets")
    suspend fun createTicket(@Body payload: TicketCreateDto): TicketRowDto

    @GET("support/tickets/{ticketId}")
    suspend fun getTicketDetail(@Path("ticketId") ticketId: String): TicketDetailDto

    @POST("support/tickets/{ticketId}/messages")
    suspend fun replyTicket(
        @Path("ticketId") ticketId: String,
        @Body payload: TicketRespondDto
    ): SupportMessageOutDto
}
