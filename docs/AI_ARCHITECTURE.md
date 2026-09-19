# MINDORA — AI Orchestration Architecture

## Pipeline

```
USER REQUEST (text / voice-transcript / image)
      │
      ▼
1. INTENT DETECTION        classify: chat | course-question | math |
                            flashcard-gen | quiz-gen | plan-gen |
                            document-question | general-knowledge
      │
      ▼
2. CONTEXT ANALYSIS         load: active course docs, study plan,
                            performance memory, conversation memory
      │
      ▼
3. TOOL SELECTION           orchestrator picks a subset of:
                            - course_retriever (RAG over student's docs)
                            - db_retriever (past papers / catalog)
                            - web_search
                            - math_solver (symbolic engine, e.g. SymPy)
                            - ocr / vision
                            - flashcard_engine
                            - quiz_engine
                            - planner_engine
      │
      ▼
4. EXECUTION                run selected tools, collect evidence
      │
      ▼
5. SOURCE VALIDATION        tag each piece of evidence: "from your course",
                            "general knowledge", "web result" — never merge
                            silently; never fabricate a citation
      │
      ▼
6. RESPONSE GENERATION      LLM composes structured answer (headings,
                            steps, formulas, source tags)
```

## Orchestrator contract (backend/ai/orchestrator.py)

```python
class Orchestrator:
    def handle(self, request: AIRequest) -> AIResponse:
        intent = self.intent_router.classify(request)
        context = self.context_builder.build(request, intent)
        tools = self.tool_selector.select(intent, context)
        evidence = self.executor.run(tools, request, context)
        validated = self.validator.validate(evidence)
        return self.responder.generate(request, validated)
```

Key rule: **the orchestrator must justify tool selection** — log which tools
were chosen and why, so behavior is debuggable and never "call everything."

## Course-aware answering

1. Query the student's course vector index (scoped to their uploaded docs).
2. If similarity above threshold → primary context, tagged "from your course".
3. If insufficient → supplement with general LLM knowledge, tagged "general
   explanation".
4. If the question needs current/external facts → web_search tool, tagged
   "external source" with a real link — never invented.

## Math engine

Symbolic solver (e.g. SymPy) handles algebra/calculus/matrices exactly;
the LLM explains steps in natural language around the solver's output rather
than computing itself, to avoid arithmetic hallucination.

## Memory layers

| Layer                | Scope                        | Storage                   |
|-----------------------|-------------------------------|----------------------------|
| Session memory         | current conversation           | in-memory / Redis (TTL)   |
| Learning memory        | topics studied                 | Postgres (Progress table) |
| Performance memory     | quiz/exam right-wrong history  | Postgres                  |
| Preference memory      | explanation style, language    | Postgres (Profile)        |
| Academic context       | subjects, exam, course outline | Postgres                  |

Only durable, non-sensitive data persists; raw conversation transcripts are
retained for a bounded window, not indefinitely, and never used to infer
attributes the student did not state.
