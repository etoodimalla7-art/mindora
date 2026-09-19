"""
Section 39: quiz generation, v1 — same extractive philosophy and same
upgrade path as flashcards/generation.py. Turns "X is Y" pairs found in
a document's text into multiple-choice questions, using OTHER
definitions from the same text as distractors (so wrong answers are at
least topically plausible, not random noise).
"""
import random

from api.modules.flashcards.generation import extract_definition_pairs

MIN_PAIRS_FOR_MULTIPLE_CHOICE = 2


def generate_quiz_from_text(
    text: str, topic_title: str, num_questions: int = 5, difficulty: str = "medium"
) -> list[dict]:
    pairs = extract_definition_pairs(text)

    if len(pairs) < MIN_PAIRS_FOR_MULTIPLE_CHOICE:
        # Not enough material for real distractors -> one true/false
        # review question rather than a broken or empty quiz.
        return [{
            "type": "true_false",
            "prompt": f"{topic_title} is worth reviewing before your exam.",
            "choices": ["True", "False"],
            "correct_answer": "True",
        }]

    questions = []
    for i, (term, definition) in enumerate(pairs[:num_questions]):
        distractor_pool = [d for j, (_, d) in enumerate(pairs) if j != i]
        distractors = distractor_pool[:3]
        choices = distractors + [definition]
        # Seeded per-term (not globally) so results are reproducible in
        # tests while still varying the correct answer's position across
        # different questions in the same quiz.
        random.Random(term).shuffle(choices)
        questions.append({
            "type": "multiple_choice",
            "prompt": f"What is {term}?",
            "choices": choices,
            "correct_answer": definition,
            "difficulty": difficulty,
        })
    return questions
