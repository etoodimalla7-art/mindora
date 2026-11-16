import React, { useMemo, useState } from 'react';
import { ArrowLeft, Bookmark, Check, Download, Search } from 'lucide-react';
import { useMindora } from '../../context/MindoraContext';

export const PastPapersScreen: React.FC = () => {
  const { pastPapers, toggleBookmarkPaper, downloadPastPaper, setSubView } = useMindora();
  const [system, setSystem] = useState<string>('ALL');
  const [level, setLevel] = useState<string>('ALL');
  const [search, setSearch] = useState('');
  const [feedback, setFeedback] = useState<{ ok: boolean; message: string } | null>(null);

  const filtered = useMemo(() => {
    return pastPapers.filter((p) => {
      if (system !== 'ALL' && p.system !== system) return false;
      if (level !== 'ALL' && p.level !== level) return false;
      if (search.trim()) {
        const q = search.toLowerCase();
        const hay = `${p.title} ${p.subject} ${p.year} ${p.summary}`.toLowerCase();
        if (!hay.includes(q)) return false;
      }
      return true;
    });
  }, [pastPapers, system, level, search]);

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
          <h1 className="font-display text-2xl font-bold text-slate-900 dark:text-white">Past Papers Library</h1>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Browse examination papers by system and level. Downloads cost 1 credit unless subscribed.
          </p>
        </div>
      </div>

      {feedback && (
        <div
          className={`p-3.5 rounded-xl border text-xs font-medium ${
            feedback.ok
              ? 'bg-emerald-50 dark:bg-emerald-950/30 border-emerald-200 dark:border-emerald-800 text-emerald-800 dark:text-emerald-200'
              : 'bg-rose-50 dark:bg-rose-950/30 border-rose-200 dark:border-rose-800 text-rose-800 dark:text-rose-200'
          }`}
        >
          {feedback.message}
        </div>
      )}

      {/* Filters */}
      <div className="grid sm:grid-cols-4 gap-3 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-4">
        <div className="sm:col-span-2 relative">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by subject, exam, or year..."
            className="w-full pl-9 pr-3 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 text-sm"
          />
        </div>
        <select
          value={system}
          onChange={(e) => setSystem(e.target.value)}
          className="px-3 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 text-sm"
        >
          <option value="ALL">All systems</option>
          <option value="GCE">GCE</option>
          <option value="Francophone">Francophone</option>
        </select>
        <select
          value={level}
          onChange={(e) => setLevel(e.target.value)}
          className="px-3 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 text-sm"
        >
          <option value="ALL">All levels</option>
          <option value="O-Level">O-Level</option>
          <option value="A-Level">A-Level</option>
          <option value="BEPC">BEPC</option>
          <option value="Bac">Baccalauréat</option>
          <option value="Licence">Licence</option>
          <option value="Master">Master</option>
        </select>
      </div>

      {/* Results */}
      {filtered.length === 0 ? (
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-8 text-center text-sm text-slate-500">
          No past papers match these filters.
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map((paper) => (
            <div
              key={paper.id}
              className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4"
            >
              <div className="space-y-1 min-w-0">
                <div className="text-xs text-slate-500 dark:text-slate-400">
                  {paper.country} · {paper.system} · {paper.level} · {paper.year}
                  {paper.session ? ` (${paper.session})` : ''}
                </div>
                <h2 className="font-display font-semibold text-base text-slate-900 dark:text-white">
                  {paper.title}
                </h2>
                <p className="text-xs text-slate-600 dark:text-slate-400">{paper.summary}</p>
              </div>

              <div className="flex items-center gap-2 shrink-0">
                <button
                  type="button"
                  onClick={() => toggleBookmarkPaper(paper.id)}
                  className={`p-2.5 rounded-xl border transition-colors ${
                    paper.bookmarked
                      ? 'border-amber-400 bg-amber-50 text-amber-600 dark:bg-amber-500/15 dark:text-amber-300'
                      : 'border-slate-200 dark:border-slate-700 text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800'
                  }`}
                  title={paper.bookmarked ? 'Remove bookmark' : 'Bookmark paper'}
                >
                  <Bookmark className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={() => setFeedback(downloadPastPaper(paper.id))}
                  className="px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold inline-flex items-center gap-1.5 whitespace-nowrap"
                >
                  {paper.downloaded ? <Check className="w-4 h-4" /> : <Download className="w-4 h-4" />}
                  <span>{paper.downloaded ? 'Downloaded' : 'Download'}</span>
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
