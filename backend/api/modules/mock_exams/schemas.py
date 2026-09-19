from pydantic import BaseModel, Field

from api.modules.quizzes.schemas import QuestionOut, QuestionResultOut


class CreateMockExamIn(BaseModel):
    subject_names: list[str] = Field(min_length=1)
    num_questions_per_subject: int = Field(default=5, ge=1, le=20)
    difficulty: str = Field(default="medium", pattern="^(easy|medium|hard|advanced)$")
    duration_minutes: int = Field(default=60, ge=10, le=240)


class MockExamSectionOut(BaseModel):
    subject_name: str
    quiz_id: str
    questions: list[QuestionOut]


class MockExamOut(BaseModel):
    id: str
    subject_names: list[str]
    difficulty: str
    duration_minutes: int
    status: str
    sections: list[MockExamSectionOut]


class SubmitMockExamIn(BaseModel):
    answers: dict[str, str]  # {question_id: chosen_answer}, across all sections


class MockExamResultOut(BaseModel):
    attempt_id: str
    score: float
    section_scores: dict[str, float]
    results: list[QuestionResultOut]
