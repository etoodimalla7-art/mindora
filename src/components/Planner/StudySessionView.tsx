import React, { useEffect, useState } from 'react';
import { ArrowLeft, CheckCircle2, Pause, Play, SkipForward, Sparkles } from 'lucide-react';
import { useMindora } from '../../context/MindoraContext';

export const StudySessionView: React.FC<{ sessionId: string }> = ({ sessionId }) => {
  const { sessions, completeSession, skipSession, handoffToAiTutor, setSubView } = useMindora();
  const session = sessions.find((s) => s.id === sessionId);

  const [secondsLeft, setSecondsLeft] = useState((session?.durationMinutes ?? 45) * 60);
  const [running, setRunning] = useState(true);

  useEffect(() => {
    if (!running || secondsLeft <= 0) return;
    const timer = window.setInterval(() => {
      setSecondsLeft((s) => Math.max(0, s - 1));
    }, 1000);
    return () => window.clearInterval(timer);
  }, [running, secondsLeft]);

  if (!session) {
    return (
      <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-8 text-center space-y-3">
        <p className="text-sm text-slate-500">Study session not found.</p>
        <button
          type="button"
          onClick={() => setSubView({ type: 'none' })}
          className="px-4 py-2 rounded-xl bg-indigo-600 text-white text-sm font-semibold"
        >
          Back to planner
        </button>
      </div>
    );
  }

  const mins = Math.floor(secondsLeft / 60);
  const secs = secondsLeft % 60;
  const formatted = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={() => setSubView({ type: 'none' })}
          className="p-2 rounded-lg border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800"
        >
          <ArrowLeft className="w-4 h-4" />
        </button>
        <div>
          <div className="text-xs text-slate-500 dark:text-slate-400">
            Focused Study Session · {session.subject}
          </div>
          <h1 className="font-display text-xl font-bold text-slate-900 dark:text-white">
            {session.title}
          </h1>
        </div>
      </div>

      <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-8 text-center space-y-6">
        <div className="text-xs font-medium text-indigo-600 dark:text-indigo-400">
          Topic: {session.topic}
        </div>

        <div className="font-mono tabular-nums text-6xl font-bold tracking-tight text-slate-900 dark:text-white">
          {formatted}
        </div>

        <p className="text-sm text-slate-600 dark:text-slate-400 max-w-md mx-auto">
          {session.objective}
        </p>

        <div className="flex flex-wrap items-center justify-center gap-3">
          <button
            type="button"
            onClick={() => setRunning((r) => !r)}
            className="px-5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 text-sm font-semibold inline-flex items-center gap-2 hover:bg-slate-50 dark:hover:bg-slate-800"
          >
            {running ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
            <span>{running ? 'Pause timer' : 'Resume timer'}</span>
          </button>

          <button
            type="button"
            onClick={() => {
              completeSession(session.id);
              setSubView({ type: 'none' });
            }}
            className="px-5 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-sm font-semibold inline-flex items-center gap-2"
          >
            <CheckCircle2 className="w-4 h-4" />
            <span>Mark complete</span>
          </button>

          <button
            type="button"
            onClick={() => {
              skipSession(session.id);
              setSubView({ type: 'none' });
            }}
            className="px-4 py-2.5 rounded-xl text-sm font-medium text-slate-500 hover:text-slate-800 dark:hover:text-slate-200 inline-flex items-center gap-1.5"
          >
            <SkipForward className="w-4 h-4" />
            <span>Skip</span>
          </button>
        </div>

        <div className="pt-6 border-t border-slate-100 dark:border-slate-800">
          <button
            type="button"
            onClick={() =>
              handoffToAiTutor(
                `I am studying "${session.topic}" in ${session.subject}. Can you walk me through the core concepts and give me a practice problem?`
              )
            }
            className="px-4 py-2.5 rounded-xl bg-indigo-50 dark:bg-indigo-500/15 text-indigo-700 dark:text-indigo-300 hover:bg-indigo-100 dark:hover:bg-indigo-500/25 text-sm font-semibold inline-flex items-center gap-2 transition-colors"
          >
            <Sparkles className="w-4 h-4" />
            <span>Ask AI Tutor about this topic</span>
          </button>
        </div>
      </div>
    </div>
  );
};
