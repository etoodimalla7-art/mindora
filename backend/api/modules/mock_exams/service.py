from datetime import datetime, timezone

from api.core.errors import NotFoundError, ValidationFailedError
from api.modules.mock_exams.repository import MockExamsRepository
from api.modules.mock_exams.scoring import score_sections
from api.modules.mock_exams.schemas import CreateMockExamIn
from api.modules.quizzes.generation import generate_quiz_from_text
from api.modules.quizzes.repository import QuizzesRepository


class MockExamsService:
    def __init__(self, repo: MockExamsRepository, quizzes_repo: QuizzesRepository, documents_repo):
        self.repo = repo
        self.quizzes_repo = quizzes_repo
        self.documents_repo = documents_repo

    async def create(self, owner_id: str, payload: CreateMockExamIn):
        # One Quiz per subject (Phase 10's engine), built from ALL of the
        # student's own documents tagged with that subject — not just
        # one, unlike a standalone quiz's single-document scope.
        mock_exam = await self.repo.create_mock_exam(
            owner_id, payload.subject_names, payload.difficulty, payload.duration_minutes,
        )
        sections = []
        for subject in payload.subject_names:
            texts = await self.documents_repo.list_extracted_texts_by_category(owner_id, subject)
            combined_text = " ".join(text for _, text in texts)
            questions_data = generate_quiz_from_text(
                combined_text, subject, payload.num_questions_per_subject, payload.difficulty,
            )
            quiz, questions = await self.quizzes_repo.create_quiz_with_questions(
                owner_id, subject, payload.difficulty, None, questions_data,
            )
            await self.repo.add_section(str(mock_exam.id), subject, str(quiz.id))
            sections.append((subject, quiz, questions))
        return mock_exam, sections

    async def get_for_taking(self, mock_exam_id: str, owner_id: str):
        mock_exam = await self.repo.get_owned(mock_exam_id, owner_id)
        if not mock_exam:
            raise NotFoundError("We couldn't find this mock exam.")
        sections = await self.repo.list_sections(mock_exam_id)
        resolved = []
        for section in sections:
            questions = await self.quizzes_repo.list_questions(str(section.quiz_id))
            resolved.append((section.subject_name, str(section.quiz_id), questions))
        return mock_exam, resolved

    async def submit(self, mock_exam_id: str, owner_id: str, answers: dict[str, str]):
        mock_exam, resolved_sections = await self.get_for_taking(mock_exam_id, owner_id)
        if not resolved_sections:
            raise ValidationFailedError("This mock exam has no sections to submit.")

        counts: dict[str, tuple[int, int]] = {}
        all_results = []
        for subject_name, _quiz_id, questions in resolved_sections:
            correct = 0
            for question in questions:
                chosen = answers.get(str(question.id))
                is_correct = chosen is not None and chosen == question.correct_answer
                if is_correct:
                    correct += 1
                all_results.append({
                    "question_id": str(question.id),
                    "prompt": question.prompt,
                    "chosen_answer": chosen,
                    "correct_answer": question.correct_answer,
                    "is_correct": is_correct,
                })
            counts[subject_name] = (correct, len(questions))

        overall_score, section_scores = score_sections(counts)
        now = datetime.now(timezone.utc)
        attempt = await self.repo.create_attempt(
            mock_exam_id, owner_id, overall_score, section_scores, answers, now, now,
        )
        return attempt, section_scores, all_results

    async def get_latest_results(self, mock_exam_id: str, owner_id: str):
        mock_exam = await self.repo.get_owned(mock_exam_id, owner_id)
        if not mock_exam:
            raise NotFoundError("We couldn't find this mock exam.")
        attempt = await self.repo.get_latest_attempt(mock_exam_id, owner_id)
        if not attempt:
            raise NotFoundError("This mock exam hasn't been attempted yet.")
        _, resolved_sections = await self.get_for_taking(mock_exam_id, owner_id)
        results = []
        for _subject_name, _quiz_id, questions in resolved_sections:
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
