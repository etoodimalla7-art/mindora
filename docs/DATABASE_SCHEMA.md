# MINDORA — Database Schema (v1)

Relational, PostgreSQL. All tables have `id (uuid)`, `created_at`, `updated_at`.

## Identity & Profile
- **users**(id, email, password_hash, locale, role, status)
- **profiles**(user_id fk, display_name, avatar_url)
- **education_profiles**(user_id fk, country, education_system, level,
  program, target_exam, target_exam_date)

## Catalog
- **subjects**(id, name, education_system, level)
- **courses**(id, subject_id fk, owner_user_id fk nullable, title, outline_json)
- **topics**(id, course_id fk, title, order_index)

## Documents & Contribution
- **documents**(id, uploader_id fk, title, description, category, level,
  language, file_url, status[enum: Draft/Uploading/Processing/UnderReview/
  Approved/Rejected/NeedsRevision/Archived/Removed])
- **document_metadata**(document_id fk, is_exam, exam_system, exam_name,
  exam_level, exam_subject, exam_year, exam_session)
- **document_versions**(document_id fk, version_no, file_url, checksum)
- **document_analysis**(document_id fk, detected_language, detected_subject,
  detected_level, page_count, quality_score, duplicate_of_id nullable,
  similarity_score)
- **document_validations**(document_id fk, check_name, passed, detail)
- **contributions**(user_id fk, document_id fk, credits_awarded, status)

## Past Papers
- **examinations**(id, country, system, level, name)
- **past_papers**(id, examination_id fk, subject_id fk, year, session,
  document_id fk)

## Planner & Sessions
- **study_plans**(id, user_id fk, mode[exam|subject], target_exam_id nullable,
  subjects_json, start_date, end_date, status)
- **study_sessions**(id, plan_id fk, subject_id fk, topic_id fk, scheduled_at,
  duration_minutes, status[pending|completed|missed|rescheduled])

## Assessment
- **flashcards**(id, owner_id fk, topic_id fk, front, back, type, source)
- **flashcard_reviews**(flashcard_id fk, user_id fk, state[known|uncertain|
  forgotten], reviewed_at, next_due_at)
- **quizzes**(id, owner_id fk, topic_id fk, difficulty, source)
- **questions**(id, quiz_id fk, type, prompt, choices_json, correct_answer)
- **quiz_attempts**(id, quiz_id fk, user_id fk, score, started_at, ended_at)
- **mock_exams**(id, user_id fk, subject_ids_json, config_json, status)
- **mock_exam_results**(mock_exam_id fk, score, breakdown_json)

## Progress
- **progress**(id, user_id fk, subject_id fk, topic_id fk, mastery_score,
  last_studied_at)
- **achievements**(id, user_id fk, code, earned_at)
- **readiness_scores**(id, user_id fk, target_exam_id fk, knowledge, practice,
  retention, past_papers, weak_topics, consistency, overall, computed_at)

## AI
- **conversations**(id, user_id fk, title, started_at)
- **messages**(id, conversation_id fk, role, content, tool_trace_json,
  created_at)

## Commerce
- **credits**(user_id fk, balance, ledger — see credit_transactions)
- **credit_transactions**(user_id fk, delta, reason, ref_id)
- **subscriptions**(user_id fk, plan_code, status, current_period_end,
  provider_ref)
- **downloads**(user_id fk, document_id fk, downloaded_at)

## Platform
- **notifications**(user_id fk, type, payload_json, read_at, scheduled_for)
- **audit_logs**(actor_id fk, action, target_type, target_id, detail_json)

Indexes: FK columns, `documents.status`, `study_sessions.scheduled_at`,
`progress(user_id, subject_id)`. Vector embeddings for document chunks live in
a separate `document_chunks(id, document_id fk, chunk_text, embedding vector)`
table (pgvector).
