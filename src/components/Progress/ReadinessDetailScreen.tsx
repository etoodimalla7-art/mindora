import React, { useMemo } from 'react';
import { AlertCircle, ArrowLeft } from 'lucide-react';
import { useMindora } from '../../context/MindoraContext';
import { computeReadinessAnalytics } from '../../lib/mindoraEngine';

export const ReadinessDetailScreen: React.FC = () => {
  const { user, sessions, quizAttempts, mockExamAttempts, flashcards, setSubView } = useMindora();

  const streakDays = useMemo(() => {
    const completed = sessions.filter((s) => s.status === 'completed');
    return new Set(completed.map((s) => (s.completedAt || s.scheduledDate).slice(0, 10))).size;
  }, [sessions]);

  const { dimensions, masteryBySubject } = useMemo(
    () =>
      computeReadinessAnalytics({
        quizAttempts,
        mockExamAttempts,
        flashcards,
        streakDays,
      }),
    [quizAttempts, mockExamAttempts, flashcards, streakDays]
  );

  const hasActivity = quizAttempts.length > 0 || mockExamAttempts.length > 0 || flashcards.some((f) => f.lastState);

  const dimensionRows = [
    { label: 'Knowledge (Quiz Accuracy)', value: dimensions.knowledge, desc: 'Average score across completed quizzes.' },
    { label: 'Practice Volume', value: dimensions.practice, desc: 'Quizzes completed and flashcards reviewed.' },
    { label: 'Retention (Spaced Repetition)', value: dimensions.retention, desc: 'Share of reviewed cards rated Known.' },
    { label: 'Past Papers / Mock Exams', value: dimensions.pastPapers, desc: 'Average weighted score on timed mock exams.' },
    { label: 'Weak Topic Coverage', value: dimensions.weakTopics, desc: 'Share of subjects above the 50% mastery floor.' },
    { label: 'Study Consistency', value: dimensions.consistency, desc: 'Active study days relative to a 14-day benchmark.' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={() => setSubView({ type: 'none' })}
          className="p-2 rounded-lg border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800"
        >
          <ArrowLeft className="w-4 h-4" />
        </button>
        <div>
          <h1 className="font-display text-2xl font-bold text-slate-900 dark:text-white">
            Exam Readiness Analysis
          </h1>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            {user?.educationProfile.targetExamName || 'Target Exam'}
          </p>
        </div>
      </div>

      {/* Honest estimate notice (Phase 12 requirement) */}
      <div className="bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800/60 rounded-2xl p-4 flex items-start gap-3">
        <AlertCircle className="w-5 h-5 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
        <div className="text-sm text-amber-900 dark:text-amber-200">
          <span className="font-semibold">Honest estimate notice:</span> This readiness score is an analytical estimate derived strictly from your recorded quizzes, flashcards, mock exams, and study consistency — not a guarantee of exam outcome.
        </div>
      </div>

      {!hasActivity ? (
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-8 text-center space-y-2">
          <div className="font-display text-lg font-semibold text-slate-900 dark:text-white">
            Not enough study data yet
          </div>
          <p className="text-sm text-slate-500 dark:text-slate-400 max-w-md mx-auto">
            Complete a quiz, review flashcards, or take a mock exam to compute your 6-dimension readiness profile.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-6 flex flex-col items-center justify-center text-center">
            <div className="font-mono tabular-nums text-5xl font-bold text-indigo-600 dark:text-indigo-400">
              {dimensions.overall}%
            </div>
            <div className="mt-2 font-display text-base font-semibold text-slate-900 dark:text-white">
              Overall Readiness
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
              Equal-weighted average across 6 readiness dimensions
            </p>
          </div>

          <div className="lg:col-span-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-6 space-y-4">
            <h2 className="font-display text-base font-semibold text-slate-900 dark:text-white">
              6-Dimension Breakdown
            </h2>
            <div className="space-y-4">
              {dimensionRows.map((row) => (
                <div key={row.label} className="space-y-1.5">
                  <div className="flex items-center justify-between text-sm">
                    <span className="font-medium text-slate-800 dark:text-slate-200">{row.label}</span>
                    <span className="font-mono tabular-nums font-semibold text-indigo-600 dark:text-indigo-400">
                      {row.value}%
                    </span>
                  </div>
                  <div className="h-2 w-full rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                    <div
                      className="h-full rounded-full bg-indigo-600 dark:bg-indigo-400"
                      style={{ width: `${row.value}%` }}
                    />
                  </div>
                  <p className="text-xs text-slate-500 dark:text-slate-400">{row.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {Object.keys(masteryBySubject).length > 0 && (
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-6 space-y-4">
          <h2 className="font-display text-base font-semibold text-slate-900 dark:text-white">
            Subject Mastery
          </h2>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {Object.entries(masteryBySubject).map(([subject, score]) => (
              <div key={subject} className="p-4 rounded-xl border border-slate-200 dark:border-slate-800 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="font-medium text-sm text-slate-900 dark:text-white">{subject}</span>
                  <span className="font-mono tabular-nums text-sm font-bold text-indigo-600 dark:text-indigo-400">
                    {score}%
                  </span>
                </div>
                <div className="h-1.5 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                  <div
                    className={`h-full rounded-full ${score >= 70 ? 'bg-emerald-500' : score >= 50 ? 'bg-amber-500' : 'bg-rose-500'}`}
                    style={{ width: `${score}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
