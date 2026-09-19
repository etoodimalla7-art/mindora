from pydantic import BaseModel, Field


class GenerateQuizIn(BaseModel):
    topic_title: str = Field(min_length=1)
    source_document_id: str | None = None
    num_questions: int = Field(default=5, ge=1, le=20)
    difficulty: str = Field(default="medium", pattern="^(easy|medium|hard|advanced)$")


class QuestionOut(BaseModel):
    """Never includes correct_answer — that only appears in the
    post-submission results (section 40's 'detailed corrections')."""
    id: str
    q_type: str
    prompt: str
    choices: list[str]


class QuizOut(BaseModel):
    id: str
    topic_title: str
    difficulty: str
    questions: list[QuestionOut]


class SubmitAttemptIn(BaseModel):
    answers: dict[str, str]  # {question_id: chosen_answer}


class QuestionResultOut(BaseModel):
    question_id: str
    prompt: str
    chosen_answer: str | None
    correct_answer: str
    is_correct: bool


class AttemptResultOut(BaseModel):
    attempt_id: str
    score: float
    results: list[QuestionResultOut]
