from datetime import datetime, timezone

from api.core.errors import NotFoundError
from api.modules.quizzes.generation import generate_quiz_from_text
from api.modules.quizzes.repository import QuizzesRepository
from api.modules.quizzes.schemas import GenerateQuizIn


class QuizzesService:
    def __init__(self, repo: QuizzesRepository, documents_repo):
        self.repo = repo
        self.documents_repo = documents_repo

    async def generate(self, owner_id: str, payload: GenerateQuizIn):
        text = ""
        if payload.source_document_id:
            texts = await self.documents_repo.list_extracted_texts_for_user(owner_id)
            match = next((t for doc_id, t in texts if doc_id == payload.source_document_id), None)
            text = match or ""
        questions_data = generate_quiz_from_text(text, payload.topic_title, payload.num_questions, payload.difficulty)
        return await self.repo.create_quiz_with_questions(
            owner_id, payload.topic_title, payload.difficulty, payload.source_document_id, questions_data,
        )

    async def get_quiz_for_taking(self, quiz_id: str, owner_id: str):
        quiz = await self.repo.get_owned_quiz(quiz_id, owner_id)
        if not quiz:
            raise NotFoundError("We couldn't find this quiz.")
        questions = await self.repo.list_questions(quiz_id)
        return quiz, questions

    async def submit_attempt(self, quiz_id: str, owner_id: str, answers: dict[str, str], started_at: datetime | None = None):
        quiz, questions = await self.get_quiz_for_taking(quiz_id, owner_id)
        results = []
        correct_count = 0
        for question in questions:
            chosen = answers.get(str(question.id))
            is_correct = chosen is not None and chosen == question.correct_answer
            if is_correct:
                correct_count += 1
            results.append({
                "question_id": str(question.id),
                "prompt": question.prompt,
                "chosen_answer": chosen,
                "correct_answer": question.correct_answer,
                "is_correct": is_correct,
            })
        score = round((correct_count / len(questions)) * 100, 1) if questions else 0.0
        now = datetime.now(timezone.utc)
        attempt = await self.repo.create_attempt(
            quiz_id, owner_id, score, answers, started_at or now, now,
        )
        return attempt, results

    async def get_attempt_results(self, attempt_id: str, owner_id: str):
        attempt = await self.repo.get_owned_attempt(attempt_id, owner_id)
        if not attempt:
            raise NotFoundError("We couldn't find this quiz attempt.")
        questions = await self.repo.list_questions(str(attempt.quiz_id))
        results = []
        for question in questions:
            chosen = attempt.answers.get(str(question.id))
            results.append({
                "question_id": str(question.id),
                "prompt": question.prompt,
                "chosen_answer": chosen,
                "correct_answer": question.correct_answer,
                "is_correct": chosen == question.correct_answer,
            })
        return attempt, results
