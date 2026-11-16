import React, { useState } from 'react';
import { CalendarDays, CheckCircle2, Clock, Play, Plus, RefreshCw } from 'lucide-react';
import { useMindora } from '../../context/MindoraContext';

const SUBJECT_OPTIONS = ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'Computer Science', 'Mathématiques'];

export const PlannerScreen: React.FC = () => {
  const { plans, sessions, createStudyPlan, reschedulePlan, setSubView } = useMindora();
  const [selectedPlanId, setSelectedPlanId] = useState<string>(plans[0]?.id ?? '');
  const [showCreate, setShowCreate] = useState(false);

  const [planType, setPlanType] = useState<'exam' | 'subject'>('exam');
  const [title, setTitle] = useState('');
  const [targetExamName, setTargetExamName] = useState('GCE Advanced Level');
  const [targetDate, setTargetDate] = useState(() => {
    const d = new Date();
    d.setDate(d.getDate() + 30);
    return d.toISOString().slice(0, 10);
  });
  const [subjects, setSubjects] = useState<string[]>(['Mathematics', 'Physics']);
  const [dailyMinutes, setDailyMinutes] = useState(45);

  const activePlan = plans.find((p) => p.id === selectedPlanId) ?? plans[0] ?? null;
  const planSessions = activePlan ? sessions.filter((s) => s.planId === activePlan.id) : [];

  const toggleSubject = (s: string) => {
    setSubjects((prev) => (prev.includes(s) ? prev.filter((i) => i !== s) : [...prev, s]));
  };

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    if (subjects.length === 0) return;
    const created = createStudyPlan({
      planType,
      title: title.trim() || (planType === 'exam' ? `${targetExamName} Roadmap` : `${subjects[0]} Deep Dive`),
      targetExamName: planType === 'exam' ? targetExamName : undefined,
      targetDate,
      subjects,
      dailyMinutes,
    });
    setSelectedPlanId(created.id);
    setShowCreate(false);
    setTitle('');
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="font-display text-2xl font-bold text-slate-900 dark:text-white">Study Planner</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Generate exam or subject roadmaps and launch focused study sessions.
          </p>
        </div>
        <button
          type="button"
          onClick={() => setShowCreate((v) => !v)}
          className="px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold inline-flex items-center gap-2 transition-colors whitespace-nowrap"
        >
          <Plus className="w-4 h-4" />
          <span>New study plan</span>
        </button>
      </div>

      {showCreate && (
        <form
          onSubmit={handleCreate}
          className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-6 space-y-5"
        >
          <div className="flex items-center justify-between">
            <h2 className="font-display text-lg font-semibold text-slate-900 dark:text-white">
              Create personalized study plan
            </h2>
            <div className="flex items-center gap-1 p-1 bg-slate-100 dark:bg-slate-800 rounded-lg">
              {(['exam', 'subject'] as const).map((mode) => (
                <button
                  key={mode}
                  type="button"
                  onClick={() => setPlanType(mode)}
                  className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${
                    planType === mode
                      ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white shadow-sm'
                      : 'text-slate-600 dark:text-slate-400'
                  }`}
                >
                  {mode === 'exam' ? 'Exam mode' : 'Subject mode'}
                </button>
              ))}
            </div>
          </div>

          <div className="grid sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium mb-1">Plan title</label>
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder={planType === 'exam' ? 'GCE Science Prep' : 'Calculus Mastery'}
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
              />
            </div>
            {planType === 'exam' && (
              <div>
                <label className="block text-xs font-medium mb-1">Target examination</label>
                <input
                  value={targetExamName}
                  onChange={(e) => setTargetExamName(e.target.value)}
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
                />
              </div>
            )}
            <div>
              <label className="block text-xs font-medium mb-1">Target date</label>
              <input
                type="date"
                required
                value={targetDate}
                onChange={(e) => setTargetDate(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-medium mb-1">Daily session duration (minutes)</label>
              <input
                type="number"
                min={15}
                max={180}
                value={dailyMinutes}
                onChange={(e) => setDailyMinutes(Number(e.target.value) || 45)}
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm font-mono tabular-nums"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-medium mb-2">Select subjects</label>
            <div className="flex flex-wrap gap-2">
              {SUBJECT_OPTIONS.map((subj) => {
                const active = subjects.includes(subj);
                return (
                  <button
                    key={subj}
                    type="button"
                    onClick={() => toggleSubject(subj)}
                    className={`px-3 py-1.5 rounded-lg text-xs font-medium border transition-colors ${
                      active
                        ? 'border-indigo-600 bg-indigo-50 text-indigo-700 dark:bg-indigo-500/20 dark:border-indigo-400 dark:text-indigo-200'
                        : 'border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300'
                    }`}
                  >
                    {subj}
                  </button>
                );
              })}
            </div>
          </div>

          <div className="flex justify-end gap-3">
            <button
              type="button"
              onClick={() => setShowCreate(false)}
              className="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-700 text-sm font-medium"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={subjects.length === 0}
              className="px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 disabled:opacity-40 text-white text-sm font-semibold"
            >
              Generate roadmap
            </button>
          </div>
        </form>
      )}

      {plans.length === 0 ? (
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-10 text-center space-y-3">
          <CalendarDays className="w-10 h-10 text-indigo-500 mx-auto" />
          <h2 className="font-display text-lg font-semibold text-slate-900 dark:text-white">
            No study plan yet
          </h2>
          <p className="text-sm text-slate-500 dark:text-slate-400 max-w-md mx-auto">
            Create an exam-mode or subject-mode study plan to generate daily topic sessions.
          </p>
          <button
            type="button"
            onClick={() => setShowCreate(true)}
            className="px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold"
          >
            Create study plan
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Plans Selector */}
          <div className="space-y-3">
            {plans.map((plan) => {
              const selected = activePlan?.id === plan.id;
              const daysLeft = plan.targetDate
                ? Math.max(0, Math.ceil((new Date(`${plan.targetDate}T00:00:00`).getTime() - Date.now()) / 86400000))
                : null;
              return (
                <button
                  key={plan.id}
                  type="button"
                  onClick={() => setSelectedPlanId(plan.id)}
                  className={`w-full text-left p-4 rounded-2xl border transition-colors space-y-2 ${
                    selected
                      ? 'bg-indigo-50/70 dark:bg-indigo-950/30 border-indigo-400 dark:border-indigo-700'
                      : 'bg-white dark:bg-slate-900 border-slate-200 dark:border-slate-800 hover:border-slate-300 dark:hover:border-slate-700'
                  }`}
                >
                  <div className="text-xs font-medium text-indigo-600 dark:text-indigo-400">
                    {plan.planType === 'exam' ? 'Exam roadmap' : 'Subject roadmap'}
                  </div>
                  <div className="font-display font-semibold text-base text-slate-900 dark:text-white">
                    {plan.title}
                  </div>
                  <div className="text-xs text-slate-500 dark:text-slate-400 font-mono tabular-nums">
                    {daysLeft !== null ? `${daysLeft} days left · ` : ''}
                    {plan.subjects.join(', ')}
                  </div>
                </button>
              );
            })}
          </div>

          {/* Sessions List */}
          {activePlan && (
            <div className="lg:col-span-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 space-y-4">
              <div className="flex flex-wrap items-center justify-between gap-3 pb-3 border-b border-slate-100 dark:border-slate-800">
                <div>
                  <h2 className="font-display text-lg font-semibold text-slate-900 dark:text-white">
                    {activePlan.title}
                  </h2>
                  <p className="text-xs text-slate-500 dark:text-slate-400">
                    {planSessions.filter((s) => s.status === 'completed').length} of {planSessions.length} sessions completed
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => reschedulePlan(activePlan.id)}
                  className="px-3 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 text-xs font-medium inline-flex items-center gap-1.5"
                >
                  <RefreshCw className="w-3.5 h-3.5" />
                  <span>Reschedule pending from today</span>
                </button>
              </div>

              <div className="divide-y divide-slate-100 dark:divide-slate-800">
                {planSessions.map((session) => {
                  const done = session.status === 'completed';
                  const skipped = session.status === 'skipped';
                  return (
                    <div key={session.id} className="py-3.5 flex flex-wrap items-center justify-between gap-3">
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center gap-2 text-xs text-slate-500 dark:text-slate-400 font-mono tabular-nums">
                          <span>{session.scheduledDate}</span>
                          <span aria-hidden="true">·</span>
                          <span>{session.subject}</span>
                          <span aria-hidden="true">·</span>
                          <span>{session.durationMinutes} min</span>
                        </div>
                        <div className="font-medium text-sm text-slate-900 dark:text-white mt-0.5">
                          {session.title}
                        </div>
                      </div>

                      {done ? (
                        <span className="inline-flex items-center gap-1 text-xs font-semibold text-emerald-600 dark:text-emerald-400">
                          <CheckCircle2 className="w-4 h-4" />
                          Completed
                        </span>
                      ) : skipped ? (
                        <span className="text-xs font-medium text-slate-400">Skipped</span>
                      ) : (
                        <button
                          type="button"
                          onClick={() => setSubView({ type: 'study_session', sessionId: session.id })}
                          className="px-3 py-1.5 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold inline-flex items-center gap-1.5 transition-colors"
                        >
                          <Play className="w-3.5 h-3.5" />
                          <span>Start</span>
                        </button>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
