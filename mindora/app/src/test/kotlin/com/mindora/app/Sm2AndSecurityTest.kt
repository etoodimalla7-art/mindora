package com.mindora.app

import com.mindora.app.core.network.AnswerResultDto
import com.mindora.app.core.network.ApiModelsMapper
import com.mindora.app.core.network.MockExamDetailDto
import com.mindora.app.core.network.MockExamResultsDto
import com.mindora.app.core.network.MockQuestionOptionDto
import com.mindora.app.core.network.MockQuestionOutDto
import com.mindora.app.data.Flashcard
import com.mindora.app.data.Sm2Engine
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class Sm2AndSecurityTest {

    @Test
    fun `sm2 engine advances interval on good and easy reviews and resets on failure`() {
        val baseTime = 1_700_000_000_000L
        val card0 = Flashcard(
            id = "c1",
            deckId = "d1",
            front = "Derivative of sin(x)?",
            back = "cos(x)",
            easeFactor = 2.5,
            intervalDays = 0,
            repetitions = 0,
            nextReviewAtMillis = baseTime
        )

        val card1 = Sm2Engine.update(card0, quality = 5, nowMillis = baseTime)
        assertEquals(1, card1.repetitions)
        assertEquals(1, card1.intervalDays)
        assertTrue(card1.easeFactor >= 2.5)

        val card2 = Sm2Engine.update(card1, quality = 4, nowMillis = baseTime)
        assertEquals(2, card2.repetitions)
        assertEquals(6, card2.intervalDays)

        val card3 = Sm2Engine.update(card2, quality = 4, nowMillis = baseTime)
        assertEquals(3, card3.repetitions)
        assertTrue(card3.intervalDays >= 10)

        // Fail reset (< 3)
        val reset = Sm2Engine.update(card3, quality = 1, nowMillis = baseTime)
        assertEquals(0, reset.repetitions)
        assertEquals(1, reset.intervalDays)
        assertTrue(reset.easeFactor >= 1.3)
    }

    @Test
    fun `mock exam mapper never populates answers before server submission`() {
        val detailDto = MockExamDetailDto(
            id = "exam-1",
            title = "GCE A-Level Physics",
            subject = "Physics",
            academicLevel = "GCE_AL",
            difficulty = "medium",
            questionCount = 2,
            durationMinutes = 15,
            status = "ready",
            questions = listOf(
                MockQuestionOutDto(
                    id = "q1",
                    position = 1,
                    questionType = "mcq",
                    prompt = "Unit of force?",
                    options = listOf(
                        MockQuestionOptionDto("A", "Newton"),
                        MockQuestionOptionDto("B", "Joule")
                    ),
                    difficulty = "easy",
                    points = 1
                )
            )
        )

        val preSubmit = ApiModelsMapper.toMockExamDetail(detailDto)
        assertEquals(1, preSubmit.questions.size)
        assertNull(preSubmit.questions.first().correctAnswer)
        assertNull(preSubmit.questions.first().explanation)
        assertFalse(preSubmit.isGraded)

        val serverResults = MockExamResultsDto(
            id = "exam-1",
            title = "GCE A-Level Physics",
            subject = "Physics",
            academicLevel = "GCE_AL",
            questionCount = 2,
            durationMinutes = 15,
            difficulty = "medium",
            status = "graded",
            score = 100.0,
            correctCount = 1,
            wrongCount = 0,
            skippedCount = 0,
            answers = listOf(
                AnswerResultDto(
                    questionId = "q1",
                    userAnswer = "A",
                    isCorrect = true,
                    pointsAwarded = 1,
                    correctAnswer = "A",
                    explanation = "Force is measured in Newtons (kg·m/s²)."
                )
            ),
            feedbackSummary = "Great work"
        )

        val postSubmit = ApiModelsMapper.applyResults(preSubmit, serverResults)
        assertTrue(postSubmit.isGraded)
        assertEquals("A", postSubmit.questions.first().correctAnswer)
        assertNotNull(postSubmit.questions.first().explanation)
    }

    @Test
    fun `parseIsoMillis parses standard UTC and offset timestamps safely`() {
        val t1 = ApiModelsMapper.parseIsoMillis("2026-05-01T12:30:00Z")
        val t2 = ApiModelsMapper.parseIsoMillis("2026-05-01T12:30:00.123456+00:00")
        assertTrue(t1 > 1_700_000_000_000L)
        assertTrue(t2 > 1_700_000_000_000L)
    }
}
