# MINDORA — API Map (v1)

Base path: `/api/v1`

## Auth & Users
```
POST   /auth/register
POST   /auth/login
POST   /auth/refresh
POST   /auth/logout
POST   /auth/password/forgot
POST   /auth/password/reset
GET    /users/me
PATCH  /users/me
GET    /users/me/education-profile
PUT    /users/me/education-profile
```

## Documents
```
POST   /documents/upload            # file only, status=Draft
POST   /documents/{id}/metadata     # title/desc/category/level/language
POST   /documents/{id}/exam-metadata
POST   /documents/{id}/submit       # triggers analysis pipeline
GET    /documents/{id}/status
GET    /documents/{id}
GET    /documents                   # search/filter
GET    /documents/mine
```

## Past Papers
```
GET    /past-papers
GET    /past-papers/{id}
GET    /past-papers/filters         # countries/systems/levels/subjects/years
```

## Planner
```
POST   /planner/exam-plan
POST   /planner/subject-plan
GET    /planner/plans/{id}
PATCH  /planner/plans/{id}/reschedule
GET    /planner/plans/{id}/sessions
```

## Study Sessions
```
GET    /study-sessions/today
POST   /study-sessions/{id}/start
POST   /study-sessions/{id}/complete
POST   /study-sessions/{id}/skip
```

## AI
```
POST   /ai/chat                     # text
WS     /ai/chat/stream
POST   /ai/voice                    # audio in -> transcript + response + tts
POST   /ai/vision                   # image in -> extracted question + answer
GET    /ai/conversations
GET    /ai/conversations/{id}
```

## Learning
```
POST   /flashcards/generate
GET    /flashcards
POST   /flashcards/{id}/review
POST   /quizzes/generate
POST   /quizzes/{id}/attempt
GET    /quizzes/{id}/results/{attempt_id}
POST   /mock-exams
POST   /mock-exams/{id}/submit
GET    /mock-exams/{id}/results
```

## Progress
```
GET    /progress/overview
GET    /progress/subjects/{id}
GET    /progress/readiness/{exam_id}
GET    /achievements
```

## Notifications
```
GET    /notifications
PATCH  /notifications/{id}/read
PUT    /notifications/preferences
```

## Commerce
```
GET    /credits/balance
GET    /credits/history
GET    /subscriptions/plans
POST   /subscriptions/subscribe
POST   /subscriptions/cancel
GET    /downloads
```

## Admin
```
GET    /admin/documents/queue
POST   /admin/documents/{id}/approve
POST   /admin/documents/{id}/reject
GET    /admin/analytics/overview
```

All endpoints require `Authorization: Bearer <jwt>` except `/auth/*`.
Responses use a consistent envelope: `{ "data": ..., "error": null }` or
`{ "data": null, "error": { "code": "...", "message": "<safe user message>" } }`.
