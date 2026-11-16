import React, { useMemo } from 'react';
import {
  ArrowRight,
  BookOpen,
  CalendarDays,
  CheckCircle2,
  Clock,
  FileText,
  Flame,
  GraduationCap,
  HelpCircle,
  Layers,
  Play,
  Sparkles,
  TrendingDown,
} from 'lucide-react';
import { useMindora } from '../../context/MindoraContext';
import { t } from '../../lib/i18n';
import { computeReadinessAnalytics } from '../../lib/mindoraEngine';

export const HomeDashboard: React.FC = () => {
  const {
    user,
    language,
    plans,
    sessions,
    quizAttempts,
    mockExamAttempts,
    flashcards,
    studyStreak,
    navigate,
    setActiveTab,
  } = useMindora();

  const hour = new Date().getHours();
  const greeting =
    hour < 12 ? t(language, 'goodMorning') : hour < 18 ? t(language, 'goodAfternoon') : t(language, 'goodEvening');
  const firstName = user?.fullName?.split(' ')[0] || 'Student';

  const completedSessions = useMemo(
    () => sessions.filter((s) => s.status === 'completed'),
    [sessions]
  );

  const streakDays = studyStreak.currentStreak;

  const todayFocus = useMemo(() => {
    const pending = sessions.filter((s) => s.status === 'pending');
    pending.sort((a, b) => a.scheduledDate.localeCompare(b.scheduledDate));
    return pending[0] ?? null;
  }, [sessions]);

  const countdown = useMemo(() => {
    const targetDate = plans[0]?.targetDate || user?.educationProfile.targetExamDate;
    const examName = plans[0]?.targetExamName || user?.educationProfile.targetExamName;
    if (!targetDate || !examName) return null;
    const diffMs = new Date(`${targetDate}T00:00:00`).getTime() - Date.now();
    const daysRemaining = Math.max(0, Math.ceil(diffMs / (1000 * 60 * 60 * 24)));
    return { examName, daysRemaining };
  }, [plans, user]);

  const { dimensions, weakTopics } = useMemo(
    () =>
      computeReadinessAnalytics({
        quizAttempts,
        mockExamAttempts,
        flashcards,
        streakDays,
      }),
    [quizAttempts, mockExamAttempts, flashcards, streakDays]
  );

  const hasAnyPlanOrActivity =
    plans.length > 0 || sessions.length > 0 || quizAttempts.length > 0 || mockExamAttempts.length > 0;

  return (
    <div className="space-y-6">
      {/* Greeting Header */}
      <div className="flex items-center justify-between gap-4">
        <div>
          <p className="text-sm text-slate-500 dark:text-slate-400">{greeting}</p>
          <h1 className="font-display text-2xl sm:text-3xl font-bold text-slate-900 dark:text-white tracking-tight">
            {t(language, 'welcome')}, {firstName}
          </h1>
        </div>
        <div className="w-11 h-11 rounded-full bg-indigo-100 dark:bg-indigo-500/20 text-indigo-700 dark:text-indigo-300 font-display font-bold flex items-center justify-center text-base shrink-0">
          {firstName.charAt(0).toUpperCase()}
        </div>
      </div>

      {/* Top Row: Exam Countdown + Streak */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {countdown && (
          <div className="md:col-span-2 bg-indigo-50/70 dark:bg-indigo-950/30 border border-indigo-200/70 dark:border-indigo-800/60 rounded-2xl p-5 flex items-center gap-4">
            <div className="w-14 h-14 rounded-xl bg-indigo-600 dark:bg-indigo-500 text-white flex items-center justify-center font-mono tabular-nums text-xl font-bold shrink-0">
              {countdown.daysRemaining}
            </div>
            <div className="min-w-0">
              <div className="text-xs font-medium text-slate-500 dark:text-slate-400">
                {t(language, 'nextExam')}
              </div>
              <div className="font-display text-lg font-semibold text-slate-900 dark:text-white truncate">
                {countdown.examName}
              </div>
              <div className="text-xs font-semibold text-indigo-600 dark:text-indigo-400 font-mono tabular-nums mt-0.5">
                {countdown.daysRemaining} {t(language, 'daysRemaining')}
              </div>
            </div>
          </div>
        )}

        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 flex items-center gap-4">
          <div
            className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 ${
              streakDays > 0
                ? 'bg-amber-500/15 text-amber-500'
                : 'bg-slate-100 dark:bg-slate-800 text-slate-400'
            }`}
          >
            <Flame className="w-6 h-6" />
          </div>
          <div>
            <div className="font-display text-lg font-bold text-slate-900 dark:text-white font-mono tabular-nums">
              {streakDays} {streakDays === 1 ? 'day' : 'days'}
            </div>
            <div className="text-xs text-slate-500 dark:text-slate-400">{t(language, 'studyStreak')}</div>
          </div>
        </div>
      </div>

      {!hasAnyPlanOrActivity ? (
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-6 space-y-4">
          <h2 className="font-display text-lg font-semibold text-slate-900 dark:text-white">
            Get started with your study plan
          </h2>
          <p className="text-sm text-slate-600 dark:text-slate-400 max-w-xl">
            Tell us your target examination and subjects. MINDORA will build a daily study roadmap and track your honest exam readiness.
          </p>
          <button
            type="button"
            onClick={() => setActiveTab('planner')}
            className="px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold inline-flex items-center gap-2 transition-colors"
          >
            <Sparkles className="w-4 h-4" />
            <span>{t(language, 'createStudyPlan')}</span>
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left 2 Columns: Today's Focus + Quick Actions + Recent Activity */}
          <div className="lg:col-span-2 space-y-6">
            <section className="space-y-3">
              <h2 className="font-display text-base font-semibold text-slate-900 dark:text-white">
                {t(language, 'todaysFocus')}
              </h2>
              {todayFocus ? (
                <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 space-y-4">
                  <div className="flex items-start justify-between gap-4">
                    <div className="min-w-0">
                      <div className="text-xs text-slate-500 dark:text-slate-400">
                        {todayFocus.subject} · {todayFocus.topic}
                      </div>
                      <h3 className="font-display text-lg font-semibold text-slate-900 dark:text-white mt-0.5">
                        {todayFocus.title}
                      </h3>
                    </div>
                    <div className="flex items-center gap-1.5 text-xs font-mono tabular-nums font-medium text-indigo-600 dark:text-indigo-400 shrink-0">
                      <Clock className="w-3.5 h-3.5" />
                      <span>{todayFocus.durationMinutes} min</span>
                    </div>
                  </div>
                  <p className="text-sm text-slate-600 dark:text-slate-400">{todayFocus.objective}</p>
                  <div className="flex flex-wrap items-center gap-3">
                    <button
                      type="button"
                      onClick={() => navigate('planner', { type: 'study_session', sessionId: todayFocus.id })}
                      className="px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 dark:bg-indigo-500 dark:hover:bg-indigo-600 text-white text-sm font-semibold inline-flex items-center gap-2 transition-colors"
                    >
                      <Play className="w-4 h-4" />
                      <span>{t(language, 'startSession')}</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => setActiveTab('planner')}
                      className="px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
                    >
                      View schedule
                    </button>
                  </div>
                </div>
              ) : (
                <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-6 text-center space-y-2">
                  <CheckCircle2 className="w-8 h-8 text-emerald-500 mx-auto" />
                  <div className="font-semibold text-sm text-slate-900 dark:text-white">
                    {t(language, 'nothingScheduled')}
                  </div>
                  <p className="text-xs text-slate-500 dark:text-slate-400">
                    {t(language, 'nothingScheduledBody')}
                  </p>
                </div>
              )}
            </section>

            {/* Quick Actions */}
            <section className="space-y-3">
              <h2 className="font-display text-base font-semibold text-slate-900 dark:text-white">
                {t(language, 'quickActions')}
              </h2>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                {[
                  { label: t(language, 'askAi'), icon: Sparkles, action: () => setActiveTab('ai') },
                  { label: t(language, 'flashcards'), icon: Layers, action: () => navigate('learn', { type: 'flashcards' }) },
                  { label: t(language, 'quickQuiz'), icon: HelpCircle, action: () => navigate('learn', { type: 'quizzes' }) },
                  { label: t(language, 'mockExams'), icon: GraduationCap, action: () => navigate('learn', { type: 'mock_exams' }) },
                  { label: t(language, 'pastPapers'), icon: FileText, action: () => navigate('learn', { type: 'past_papers' }) },
                  { label: t(language, 'openPlanner'), icon: CalendarDays, action: () => setActiveTab('planner') },
                ].map((item) => {
                  const Icon = item.icon;
                  return (
                    <button
                      key={item.label}
                      type="button"
                      onClick={item.action}
                      className="p-4 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-indigo-300 dark:hover:border-indigo-700 text-left transition-colors flex items-center gap-3"
                    >
                      <Icon className="w-5 h-5 text-indigo-600 dark:text-indigo-400 shrink-0" />
                      <span className="text-sm font-medium text-slate-900 dark:text-slate-100 truncate">
                        {item.label}
                      </span>
                    </button>
                  );
                })}
              </div>
            </section>

            {/* Recent Activity */}
            {completedSessions.length > 0 && (
              <section className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 space-y-3">
                <h2 className="font-display text-base font-semibold text-slate-900 dark:text-white">
                  {t(language, 'recentActivity')}
                </h2>
                <div className="divide-y divide-slate-100 dark:divide-slate-800">
                  {completedSessions.slice(0, 4).map((s) => (
                    <div key={s.id} className="py-3 flex items-center justify-between gap-3">
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="w-8 h-8 rounded-lg bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center shrink-0">
                          <CheckCircle2 className="w-4 h-4" />
                        </div>
                        <div className="min-w-0">
                          <div className="text-sm font-medium text-slate-900 dark:text-white truncate">
                            {s.title}
                          </div>
                          <div className="text-xs text-slate-500 dark:text-slate-400">{s.subject}</div>
                        </div>
                      </div>
                      <span className="text-xs font-mono tabular-nums text-slate-500 dark:text-slate-400 shrink-0">
                        {s.durationMinutes} min
                      </span>
                    </div>
                  ))}
                </div>
              </section>
            )}
          </div>

          {/* Right Column: Exam Readiness + Weak Topics */}
          <div className="space-y-6">
            <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 space-y-4">
              <div className="flex items-start justify-between gap-2">
                <div>
                  <h2 className="font-display text-base font-semibold text-slate-900 dark:text-white">
                    {t(language, 'examReadiness')}
                  </h2>
                  <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                    {t(language, 'readinessDisclaimer')}
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-5">
                <div className="relative w-24 h-24 shrink-0 flex items-center justify-center">
                  <svg className="w-24 h-24 -rotate-90" viewBox="0 0 100 100">
                    <circle
                      cx="50"
                      cy="50"
                      r="42"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="9"
                      className="text-slate-100 dark:text-slate-800"
                    />
                    <circle
                      cx="50"
                      cy="50"
                      r="42"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="9"
                      strokeLinecap="round"
                      strokeDasharray={2 * Math.PI * 42}
                      strokeDashoffset={2 * Math.PI * 42 * (1 - dimensions.overall / 100)}
                      className="text-indigo-600 dark:text-indigo-400 transition-all duration-300"
                    />
                  </svg>
                  <span className="absolute font-display text-xl font-bold font-mono tabular-nums text-slate-900 dark:text-white">
                    {dimensions.overall}%
                  </span>
                </div>

                <div className="flex-1 space-y-2 text-xs">
                  {[
                    ['Knowledge', dimensions.knowledge],
                    ['Practice', dimensions.practice],
                    ['Retention', dimensions.retention],
                    ['Consistency', dimensions.consistency],
                  ].map(([label, val]) => (
                    <div key={String(label)} className="flex items-center justify-between">
                      <span className="text-slate-500 dark:text-slate-400">{label}</span>
                      <span className="font-mono tabular-nums font-semibold text-indigo-600 dark:text-indigo-400">
                        {val}%
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              <button
                type="button"
                onClick={() => navigate('home', { type: 'readiness' })}
                className="w-full py-2 px-3 rounded-xl border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 text-xs font-semibold text-slate-700 dark:text-slate-200 flex items-center justify-center gap-1.5 transition-colors"
              >
                <span>View full readiness breakdown</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>

            {weakTopics.length > 0 && (
              <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 space-y-3">
                <div className="flex items-center gap-2">
                  <TrendingDown className="w-4 h-4 text-rose-500" />
                  <h2 className="font-display text-base font-semibold text-slate-900 dark:text-white">
                    {t(language, 'weakTopics')}
                  </h2>
                </div>
                <div className="space-y-3">
                  {weakTopics.map((topic) => (
                    <div key={topic.subject} className="space-y-1">
                      <div className="flex items-center justify-between text-xs">
                        <span className="font-medium text-slate-800 dark:text-slate-200">{topic.topic}</span>
                        <span className="font-mono tabular-nums text-slate-500 dark:text-slate-400">
                          {Math.round(topic.mastery * 100)}%
                        </span>
                      </div>
                      <div className="h-1.5 w-full rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                        <div
                          className="h-full rounded-full bg-rose-500"
                          style={{ width: `${Math.max(6, Math.round(topic.mastery * 100))}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
