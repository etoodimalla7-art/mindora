import React, { useEffect, useMemo, useState } from 'react';
import { ArrowLeft, CheckCircle2, Clock, GraduationCap, HelpCircle, Plus, Sparkles, XCircle } from 'lucide-react';
import { useMindora } from '../../context/MindoraContext';
import type { MockExamAttempt, QuizAttempt } from '../../types/mindora';

export const QuizzesScreen: React.FC = () => {
  const { quizzes, quizAttempts, documents, createQuiz, submitQuizAttempt, setSubView } = useMindora();
  const [activeQuizId, setActiveQuizId] = useState<string | null>(null);
  const [answers, setAnswers] = useState<Record<string, number>>({});
  const [latestAttempt, setLatestAttempt] = useState<QuizAttempt | null>(null);

  const [showCreate, setShowCreate] = useState(false);
  const [title, setTitle] = useState('');
  const [subject, setSubject] = useState('Mathematics');
  const [difficulty, setDifficulty] = useState<'easy' | 'medium' | 'hard'>('medium');
  const [selectedDocId, setSelectedDocId] = useState(documents[0]?.id ?? '');
  const [useAi, setUseAi] = useState(false);
  const [generating, setGenerating] = useState(false);
  const [genError, setGenError] = useState<string | null>(null);

  const activeQuiz = quizzes.find((q) => q.id === activeQuizId) ?? null;

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    setGenError(null);
    const doc = documents.find((d) => d.id === selectedDocId);
    const sourceText = doc ? `${doc.description}\n${doc.contentText}` : '';

    if (useAi) {
      setGenerating(true);
      try {
        const res = await fetch('/api/ai/generate-study', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ mode: 'quiz', subject, difficulty, sourceText, count: 5 }),
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'AI quiz generation failed.');
        const created = createQuiz({
          title: title.trim() || `${subject} AI Quiz`,
          subject,
          difficulty,
          sourceText,
          questions: data.items,
        });
        setShowCreate(false);
        setActiveQuizId(created.id);
        setAnswers({});
        setLatestAttempt(null);
      } catch (err) {
        setGenError(err instanceof Error ? err.message : 'Unable to generate quiz.');
      } finally {
        setGenerating(false);
      }
      return;
    }

    const created = createQuiz({
      title: title.trim() || `${subject} Practice Quiz`,
      subject,
      difficulty,
      sourceText,
    });
    setShowCreate(false);
    setActiveQuizId(created.id);
    setAnswers({});
    setLatestAttempt(null);
  };

  if (activeQuiz) {
    return (
      <div className="max-w-3xl mx-auto space-y-6">
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={() => {
                setActiveQuizId(null);
                setLatestAttempt(null);
              }}
              className="p-2 rounded-lg border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800"
            >
              <ArrowLeft className="w-4 h-4" />
            </button>
            <div>
              <h1 className="font-display text-xl font-bold text-slate-900 dark:text-white">
                {activeQuiz.title}
              </h1>
              <div className="text-xs text-slate-500 dark:text-slate-400">
                {activeQuiz.subject} · {activeQuiz.difficulty} · {activeQuiz.questions.length} questions
              </div>
            </div>
          </div>
          {latestAttempt && (
            <div className="font-mono tabular-nums text-xl font-bold text-indigo-600 dark:text-indigo-400">
              {latestAttempt.score}%
            </div>
          )}
        </div>

        <div className="space-y-4">
          {activeQuiz.questions.map((q, idx) => {
            const chosen = answers[q.id];
            const graded = Boolean(latestAttempt);
            return (
              <div
                key={q.id}
                className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 space-y-3"
              >
                <div className="font-medium text-sm text-slate-900 dark:text-white">
                  {idx + 1}. {q.prompt}
                </div>
                <div className="space-y-2">
                  {q.options.map((opt, optIdx) => {
                    const isSelected = chosen === optIdx;
                    const isCorrect = q.correctIndex === optIdx;
                    let cls =
                      'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-800 dark:text-slate-200';
                    if (graded) {
                      if (isCorrect) {
                        cls = 'border-emerald-500 bg-emerald-50 dark:bg-emerald-950/30 text-emerald-900 dark:text-emerald-200';
                      } else if (isSelected && !isCorrect) {
                        cls = 'border-rose-500 bg-rose-50 dark:bg-rose-950/30 text-rose-900 dark:text-rose-200';
                      }
                    } else if (isSelected) {
                      cls = 'border-indigo-600 bg-indigo-50 dark:bg-indigo-500/15 text-indigo-900 dark:text-indigo-200';
                    }
                    return (
                      <button
                        key={optIdx}
                        type="button"
                        disabled={graded}
                        onClick={() => setAnswers((prev) => ({ ...prev, [q.id]: optIdx }))}
                        className={`w-full text-left px-4 py-3 rounded-xl border text-sm flex items-center justify-between gap-2 transition-colors ${cls}`}
                      >
                        <span>{opt}</span>
                        {graded && isCorrect && <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />}
                        {graded && isSelected && !isCorrect && <XCircle className="w-4 h-4 text-rose-600 shrink-0" />}
                      </button>
                    );
                  })}
                </div>
                {graded && (
                  <div className="pt-2 text-xs text-slate-600 dark:text-slate-400">
                    <span className="font-semibold">Correction:</span> {q.explanation}
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {!latestAttempt && (
          <button
            type="button"
            onClick={() => setLatestAttempt(submitQuizAttempt(activeQuiz.id, answers))}
            className="w-full py-3 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold"
          >
            Submit quiz for corrections
          </button>
        )}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => setSubView({ type: 'none' })}
            className="p-2 rounded-lg border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            <ArrowLeft className="w-4 h-4" />
          </button>
          <div>
            <h1 className="font-display text-2xl font-bold text-slate-900 dark:text-white">Quizzes</h1>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              Practice questions with withheld answers until submission.
            </p>
          </div>
        </div>
        <button
          type="button"
          onClick={() => setShowCreate((v) => !v)}
          className="px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold inline-flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          <span>Generate quiz</span>
        </button>
      </div>

      {showCreate && (
        <form
          onSubmit={handleCreate}
          className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-6 space-y-4"
        >
          <div className="grid sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-medium mb-1">Quiz title</label>
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g. Calculus Drill"
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-medium mb-1">Subject</label>
              <input
                value={subject}
                onChange={(e) => setSubject(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-medium mb-1">Difficulty</label>
              <select
                value={difficulty}
                onChange={(e) => setDifficulty(e.target.value as 'easy' | 'medium' | 'hard')}
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
              >
                <option value="easy">Easy</option>
                <option value="medium">Medium</option>
                <option value="hard">Hard</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-xs font-medium mb-1">Source course document</label>
            <select
              value={selectedDocId}
              onChange={(e) => setSelectedDocId(e.target.value)}
              className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
            >
              {documents.map((d) => (
                <option key={d.id} value={d.id}>
                  {d.title} ({d.subject})
                </option>
              ))}
            </select>
          </div>

          <label className="flex items-center gap-2 text-xs font-medium text-slate-700 dark:text-slate-300 cursor-pointer">
            <input
              type="checkbox"
              checked={useAi}
              onChange={(e) => setUseAi(e.target.checked)}
              className="rounded border-slate-300 text-indigo-600"
            />
            <Sparkles className="w-3.5 h-3.5 text-indigo-500" />
            <span>Generate questions using Gemini AI</span>
          </label>

          {genError && <p className="text-xs text-rose-600 dark:text-rose-400">{genError}</p>}

          <div className="flex justify-end gap-2">
            <button
              type="button"
              onClick={() => setShowCreate(false)}
              className="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-700 text-sm"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={generating}
              className="px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold"
            >
              {generating ? 'Generating...' : 'Start quiz'}
            </button>
          </div>
        </form>
      )}

      <div className="grid sm:grid-cols-2 gap-4">
        {quizzes.map((quiz) => {
          const best = quizAttempts
            .filter((a) => a.quizId === quiz.id)
            .sort((a, b) => b.score - a.score)[0];
          return (
            <button
              key={quiz.id}
              type="button"
              onClick={() => {
                setActiveQuizId(quiz.id);
                setAnswers({});
                setLatestAttempt(null);
              }}
              className="p-5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-indigo-300 dark:hover:border-indigo-700 text-left space-y-2 transition-colors"
            >
              <div className="flex items-center justify-between">
                <HelpCircle className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
                {best && (
                  <span className="font-mono tabular-nums text-xs font-semibold text-emerald-600 dark:text-emerald-400">
                    Best: {best.score}%
                  </span>
                )}
              </div>
              <div className="font-display font-semibold text-base text-slate-900 dark:text-white">
                {quiz.title}
              </div>
              <div className="text-xs text-slate-500 dark:text-slate-400">
                {quiz.subject} · {quiz.difficulty} · {quiz.questions.length} questions
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
};

export const MockExamsScreen: React.FC = () => {
  const { mockExams, mockExamAttempts, createMockExam, startMockExam, submitMockExam, setSubView } = useMindora();
  const [activeExamId, setActiveExamId] = useState<string | null>(null);
  const [answers, setAnswers] = useState<Record<string, number>>({});
  const [secondsLeft, setSecondsLeft] = useState(0);
  const [latestAttempt, setLatestAttempt] = useState<MockExamAttempt | null>(null);

  const [showCreate, setShowCreate] = useState(false);
  const [title, setTitle] = useState('GCE Science Combined Mock');
  const [subjects, setSubjects] = useState<string[]>(['Mathematics', 'Physics']);
  const [questionsPerSubject, setQuestionsPerSubject] = useState(3);
  const [durationMinutes, setDurationMinutes] = useState(30);
  const [difficulty, setDifficulty] = useState<'easy' | 'medium' | 'hard'>('medium');

  const activeExam = mockExams.find((e) => e.id === activeExamId) ?? null;

  const flatQuestions = useMemo(() => {
    if (!activeExam) return [];
    return activeExam.sections.flatMap((sec) =>
      sec.questions.map((q) => ({ ...q, sectionSubject: sec.subject }))
    );
  }, [activeExam]);

  useEffect(() => {
    if (!activeExam || activeExam.status !== 'in_progress' || latestAttempt) return;
    if (secondsLeft <= 0) {
      const attempt = submitMockExam(activeExam.id, answers);
      setLatestAttempt(attempt);
      return;
    }
    const timer = window.setInterval(() => setSecondsLeft((s) => s - 1), 1000);
    return () => window.clearInterval(timer);
  }, [activeExam, latestAttempt, secondsLeft, answers, submitMockExam]);

  const toggleSubject = (s: string) => {
    setSubjects((prev) => (prev.includes(s) ? prev.filter((x) => x !== s) : [...prev, s]));
  };

  if (activeExam) {
    const attempt =
      latestAttempt ?? mockExamAttempts.find((a) => a.examId === activeExam.id) ?? null;
    const mins = Math.floor(secondsLeft / 60);
    const secs = secondsLeft % 60;

    return (
      <div className="max-w-3xl mx-auto space-y-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={() => {
                setActiveExamId(null);
                setLatestAttempt(null);
              }}
              className="p-2 rounded-lg border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800"
            >
              <ArrowLeft className="w-4 h-4" />
            </button>
            <div>
              <h1 className="font-display text-xl font-bold text-slate-900 dark:text-white">
                {activeExam.title}
              </h1>
              <div className="text-xs text-slate-500 dark:text-slate-400">
                {activeExam.subjects.join(' · ')}
              </div>
            </div>
          </div>

          {!attempt ? (
            <div className="px-3.5 py-2 rounded-xl bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-800 text-amber-800 dark:text-amber-200 font-mono tabular-nums text-sm font-bold flex items-center gap-2">
              <Clock className="w-4 h-4" />
              <span>
                {String(mins).padStart(2, '0')}:{String(secs).padStart(2, '0')}
              </span>
            </div>
          ) : (
            <div className="font-mono tabular-nums text-2xl font-bold text-indigo-600 dark:text-indigo-400">
              {attempt.overallScore}%
            </div>
          )}
        </div>

        {attempt && (
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 space-y-3">
            <h2 className="font-display text-base font-semibold text-slate-900 dark:text-white">
              Weighted Subject Breakdown
            </h2>
            <div className="grid sm:grid-cols-2 gap-3">
              {Object.entries(attempt.sectionScores).map(([subj, info]) => (
                <div key={subj} className="p-3.5 rounded-xl border border-slate-200 dark:border-slate-800 flex items-center justify-between">
                  <div>
                    <div className="font-medium text-sm text-slate-900 dark:text-white">{subj}</div>
                    <div className="text-xs text-slate-500 font-mono tabular-nums">
                      {info.correct} / {info.total} correct
                    </div>
                  </div>
                  <div className="font-mono tabular-nums text-lg font-bold text-indigo-600 dark:text-indigo-400">
                    {info.score}%
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="space-y-4">
          {flatQuestions.map((q, idx) => {
            const chosen = attempt ? attempt.answers[q.id] : answers[q.id];
            const graded = Boolean(attempt);
            return (
              <div
                key={q.id}
                className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 space-y-3"
              >
                <div className="text-xs font-semibold text-indigo-600 dark:text-indigo-400">
                  {q.sectionSubject} · Question {idx + 1}
                </div>
                <div className="font-medium text-sm text-slate-900 dark:text-white">{q.prompt}</div>
                <div className="space-y-2">
                  {q.options.map((opt, optIdx) => {
                    const isSelected = chosen === optIdx;
                    const isCorrect = q.correctIndex === optIdx;
                    let cls =
                      'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800';
                    if (graded) {
                      if (isCorrect) cls = 'border-emerald-500 bg-emerald-50 dark:bg-emerald-950/30';
                      else if (isSelected) cls = 'border-rose-500 bg-rose-50 dark:bg-rose-950/30';
                    } else if (isSelected) {
                      cls = 'border-indigo-600 bg-indigo-50 dark:bg-indigo-500/15';
                    }
                    return (
                      <button
                        key={optIdx}
                        type="button"
                        disabled={graded}
                        onClick={() => setAnswers((prev) => ({ ...prev, [q.id]: optIdx }))}
                        className={`w-full text-left px-4 py-3 rounded-xl border text-sm ${cls}`}
                      >
                        {opt}
                      </button>
                    );
                  })}
                </div>
                {graded && (
                  <p className="text-xs text-slate-600 dark:text-slate-400">
                    <span className="font-semibold">Correction:</span> {q.explanation}
                  </p>
                )}
              </div>
            );
          })}
        </div>

        {!attempt && (
          <button
            type="button"
            onClick={() => setLatestAttempt(submitMockExam(activeExam.id, answers))}
            className="w-full py-3 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold"
          >
            Submit mock exam
          </button>
        )}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => setSubView({ type: 'none' })}
            className="p-2 rounded-lg border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            <ArrowLeft className="w-4 h-4" />
          </button>
          <div>
            <h1 className="font-display text-2xl font-bold text-slate-900 dark:text-white">Mock Exams</h1>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              Timed multi-subject simulations grounded in your approved documents.
            </p>
          </div>
        </div>
        <button
          type="button"
          onClick={() => setShowCreate((v) => !v)}
          className="px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold inline-flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          <span>New mock exam</span>
        </button>
      </div>

      {showCreate && (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            if (subjects.length === 0) return;
            const exam = createMockExam({
              title: title.trim() || 'Combined Mock Exam',
              subjects,
              questionsPerSubject,
              durationMinutes,
              difficulty,
            });
            startMockExam(exam.id);
            setSecondsLeft(exam.durationMinutes * 60);
            setAnswers({});
            setLatestAttempt(null);
            setActiveExamId(exam.id);
            setShowCreate(false);
          }}
          className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-6 space-y-4"
        >
          <div className="grid sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-medium mb-1">Exam title</label>
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-medium mb-1">Questions per subject</label>
              <input
                type="number"
                min={2}
                max={10}
                value={questionsPerSubject}
                onChange={(e) => setQuestionsPerSubject(Number(e.target.value) || 3)}
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm font-mono tabular-nums"
              />
            </div>
            <div>
              <label className="block text-xs font-medium mb-1">Duration (minutes)</label>
              <input
                type="number"
                min={5}
                max={180}
                value={durationMinutes}
                onChange={(e) => setDurationMinutes(Number(e.target.value) || 30)}
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm font-mono tabular-nums"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-medium mb-2">Subjects included</label>
            <div className="flex flex-wrap gap-2">
              {['Mathematics', 'Physics', 'Chemistry', 'Biology'].map((subj) => {
                const active = subjects.includes(subj);
                return (
                  <button
                    key={subj}
                    type="button"
                    onClick={() => toggleSubject(subj)}
                    className={`px-3 py-1.5 rounded-lg text-xs font-medium border ${
                      active
                        ? 'border-indigo-600 bg-indigo-50 text-indigo-700 dark:bg-indigo-500/20 dark:border-indigo-400 dark:text-indigo-200'
                        : 'border-slate-200 dark:border-slate-700'
                    }`}
                  >
                    {subj}
                  </button>
                );
              })}
            </div>
          </div>

          <div className="flex items-center justify-between">
            <select
              value={difficulty}
              onChange={(e) => setDifficulty(e.target.value as 'easy' | 'medium' | 'hard')}
              className="px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
            >
              <option value="easy">Easy difficulty</option>
              <option value="medium">Medium difficulty</option>
              <option value="hard">Hard difficulty</option>
            </select>

            <button
              type="submit"
              disabled={subjects.length === 0}
              className="px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold"
            >
              Start timed exam
            </button>
          </div>
        </form>
      )}

      {mockExams.length === 0 ? (
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-10 text-center space-y-3">
          <GraduationCap className="w-10 h-10 text-indigo-500 mx-auto" />
          <div className="font-display text-lg font-semibold text-slate-900 dark:text-white">
            No mock exams yet
          </div>
          <p className="text-sm text-slate-500 dark:text-slate-400 max-w-md mx-auto">
            Create a multi-subject timed mock exam to test your readiness under real countdown pressure.
          </p>
        </div>
      ) : (
        <div className="grid sm:grid-cols-2 gap-4">
          {mockExams.map((exam) => {
            const attempt = mockExamAttempts.find((a) => a.examId === exam.id);
            return (
              <button
                key={exam.id}
                type="button"
                onClick={() => {
                  if (exam.status === 'ready') {
                    startMockExam(exam.id);
                    setSecondsLeft(exam.durationMinutes * 60);
                  }
                  setLatestAttempt(attempt ?? null);
                  setActiveExamId(exam.id);
                }}
                className="p-5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-indigo-300 dark:hover:border-indigo-700 text-left space-y-2 transition-colors"
              >
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-indigo-600 dark:text-indigo-400">
                    {exam.status.toUpperCase()}
                  </span>
                  {attempt && (
                    <span className="font-mono tabular-nums text-sm font-bold text-emerald-600 dark:text-emerald-400">
                      {attempt.overallScore}%
                    </span>
                  )}
                </div>
                <div className="font-display font-semibold text-base text-slate-900 dark:text-white">
                  {exam.title}
                </div>
                <div className="text-xs text-slate-500 dark:text-slate-400 font-mono tabular-nums">
                  {exam.subjects.join(', ')} · {exam.durationMinutes} min
                </div>
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
};
