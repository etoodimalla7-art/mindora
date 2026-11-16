import React from 'react';
import {
  ChevronRight,
  Coins,
  FileText,
  FolderOpen,
  GraduationCap,
  HelpCircle,
  Layers,
  Upload,
} from 'lucide-react';
import { useMindora } from '../../context/MindoraContext';
import { t } from '../../lib/i18n';

export const LearnHubScreen: React.FC = () => {
  const { language, creditsBalance, activeSubscriptionCode, documents, decks, quizzes, mockExams, setSubView } =
    useMindora();

  const myDocsCount = documents.length;

  const studyTools = [
    {
      title: t(language, 'pastPapers'),
      subtitle: 'Filter by system, level, subject, and year — bookmark or download.',
      icon: FileText,
      action: () => setSubView({ type: 'past_papers' }),
    },
    {
      title: t(language, 'flashcards'),
      subtitle: `${decks.length} decks · SM-2 spaced repetition review.`,
      icon: Layers,
      action: () => setSubView({ type: 'flashcards' }),
    },
    {
      title: t(language, 'quickQuiz'),
      subtitle: `${quizzes.length} quizzes · Generate from course notes & get detailed corrections.`,
      icon: HelpCircle,
      action: () => setSubView({ type: 'quizzes' }),
    },
    {
      title: t(language, 'mockExams'),
      subtitle: `${mockExams.length} exams · Timed multi-subject simulations with breakdown.`,
      icon: GraduationCap,
      action: () => setSubView({ type: 'mock_exams' }),
    },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-display text-2xl font-bold text-slate-900 dark:text-white">Learn</h1>
        <p className="text-sm text-slate-500 dark:text-slate-400">
          Past papers, flashcards, quizzes, mock exams, and course contributions.
        </p>
      </div>

      {/* Credits Summary Banner */}
      <div className="bg-indigo-50/80 dark:bg-indigo-950/30 border border-indigo-200/70 dark:border-indigo-800/60 rounded-2xl p-5 flex items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-indigo-600 dark:bg-indigo-500 text-white font-mono tabular-nums font-bold text-xl flex items-center justify-center shrink-0">
            {activeSubscriptionCode ? '∞' : creditsBalance}
          </div>
          <div>
            <div className="font-display font-semibold text-base text-slate-900 dark:text-white">
              {activeSubscriptionCode ? 'Unlimited Downloads Active' : t(language, 'downloadCredits')}
            </div>
            <p className="text-xs text-slate-600 dark:text-slate-400">
              Earn +5 credits for every 5 approved course or past-paper contributions.
            </p>
          </div>
        </div>
        <button
          type="button"
          onClick={() => setSubView({ type: 'subscription' })}
          className="px-3.5 py-2 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 text-xs font-semibold text-slate-800 dark:text-slate-200 whitespace-nowrap shrink-0 flex items-center gap-1.5"
        >
          <Coins className="w-3.5 h-3.5 text-amber-500" />
          <span>Plans</span>
        </button>
      </div>

      {/* Study Tools Grid */}
      <div className="grid sm:grid-cols-2 gap-4">
        {studyTools.map((tool) => {
          const Icon = tool.icon;
          return (
            <button
              key={tool.title}
              type="button"
              onClick={tool.action}
              className="p-5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-indigo-300 dark:hover:border-indigo-700 text-left flex items-center justify-between gap-4 transition-colors"
            >
              <div className="flex items-center gap-4 min-w-0">
                <div className="w-11 h-11 rounded-xl bg-indigo-50 dark:bg-indigo-500/15 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shrink-0">
                  <Icon className="w-5 h-5" />
                </div>
                <div className="min-w-0">
                  <div className="font-display font-semibold text-base text-slate-900 dark:text-white">
                    {tool.title}
                  </div>
                  <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5 line-clamp-2">
                    {tool.subtitle}
                  </p>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-slate-400 shrink-0" />
            </button>
          );
        })}
      </div>

      {/* Document Contributions */}
      <div className="space-y-3">
        <h2 className="font-display text-base font-semibold text-slate-900 dark:text-white">
          Course Contributions
        </h2>
        <div className="grid sm:grid-cols-2 gap-4">
          <button
            type="button"
            onClick={() => setSubView({ type: 'upload_document' })}
            className="p-5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-indigo-300 dark:hover:border-indigo-700 text-left flex items-center justify-between gap-4 transition-colors"
          >
            <div className="flex items-center gap-4">
              <div className="w-11 h-11 rounded-xl bg-slate-100 dark:bg-slate-800 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shrink-0">
                <Upload className="w-5 h-5" />
              </div>
              <div>
                <div className="font-semibold text-sm text-slate-900 dark:text-white">
                  {t(language, 'contributeDocument')}
                </div>
                <div className="text-xs text-slate-500 dark:text-slate-400">
                  Upload course notes or past papers (500-word validation).
                </div>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-400 shrink-0" />
          </button>

          <button
            type="button"
            onClick={() => setSubView({ type: 'my_contributions' })}
            className="p-5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-indigo-300 dark:hover:border-indigo-700 text-left flex items-center justify-between gap-4 transition-colors"
          >
            <div className="flex items-center gap-4">
              <div className="w-11 h-11 rounded-xl bg-slate-100 dark:bg-slate-800 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shrink-0">
                <FolderOpen className="w-5 h-5" />
              </div>
              <div>
                <div className="font-semibold text-sm text-slate-900 dark:text-white">
                  {t(language, 'myContributions')}
                </div>
                <div className="text-xs text-slate-500 dark:text-slate-400 font-mono tabular-nums">
                  {myDocsCount} documents · Track validation & approval status
                </div>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-400 shrink-0" />
          </button>
        </div>
      </div>
    </div>
  );
};
