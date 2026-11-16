import React, { useMemo, useState } from 'react';
import { AlertTriangle, ArrowLeft, CheckCircle2, FileText, Upload } from 'lucide-react';
import { useMindora } from '../../context/MindoraContext';
import { countWords, hasExcessiveRepetition, MIN_DESCRIPTION_WORDS } from '../../lib/mindoraEngine';
import type { DocumentItem, LanguageCode } from '../../types/mindora';

const SAMPLE_500_WORD_DESCRIPTION = Array.from({ length: 14 })
  .map(
    (_, idx) =>
      `Section ${idx + 1} examines foundational principles, derivations, boundary conditions, and problem-solving frameworks required for examination mastery across algebraic manipulation, differential equations, physical conservation laws, experimental uncertainty evaluation, and structured past-paper response strategies.`
  )
  .join(' ');

export const DocumentUploadScreen: React.FC<{ initialView?: 'upload' | 'mine' }> = ({
  initialView = 'upload',
}) => {
  const { documents, submitDocument, setSubView } = useMindora();
  const [view, setView] = useState<'upload' | 'mine'>(initialView);

  const [title, setTitle] = useState('');
  const [subject, setSubject] = useState('Mathematics');
  const [educationSystem, setEducationSystem] = useState('GCE');
  const [level, setLevel] = useState('Advanced Level');
  const [language, setLanguage] = useState<LanguageCode>('en');
  const [fileName, setFileName] = useState('course_notes.pdf');
  const [isExamPaper, setIsExamPaper] = useState(false);
  const [examYear, setExamYear] = useState(2025);
  const [examSession, setExamSession] = useState('June');
  const [description, setDescription] = useState('');
  const [contentText, setContentText] = useState('');
  const [submittedDoc, setSubmittedDoc] = useState<DocumentItem | null>(null);

  const wc = useMemo(() => countWords(description), [description]);
  const spamFlag = useMemo(() => hasExcessiveRepetition(description), [description]);
  const wordValid = wc >= MIN_DESCRIPTION_WORDS && !spamFlag;

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setFileName(file.name);
    if (file.type.startsWith('text/') || file.name.endsWith('.txt') || file.name.endsWith('.md')) {
      const reader = new FileReader();
      reader.onload = () => setContentText(String(reader.result || '').slice(0, 15000));
      reader.readAsText(file);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const doc = submitDocument({
      title: title.trim() || 'Untitled Course Document',
      subject,
      educationSystem,
      level,
      language,
      fileName,
      isExamPaper,
      examYear: isExamPaper ? examYear : undefined,
      examSession: isExamPaper ? examSession : undefined,
      description,
      contentText: contentText.trim() || description,
    });
    setSubmittedDoc(doc);
  };

  const statusLabel = (s: DocumentItem['status']) => {
    switch (s) {
      case 'approved':
        return { text: 'Approved', cls: 'text-emerald-600 dark:text-emerald-400' };
      case 'under_review':
        return { text: 'Under review', cls: 'text-indigo-600 dark:text-indigo-400' };
      case 'needs_revision':
        return { text: 'Needs revision', cls: 'text-amber-600 dark:text-amber-400' };
      case 'rejected':
        return { text: 'Rejected', cls: 'text-rose-600 dark:text-rose-400' };
      default:
        return { text: 'Draft', cls: 'text-slate-500' };
    }
  };

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
            <h1 className="font-display text-2xl font-bold text-slate-900 dark:text-white">
              {view === 'upload' ? 'Contribute Document' : 'My Contributions'}
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              Phase 4–5 validation pipeline: 500-word description, language check, and duplicate detection.
            </p>
          </div>
        </div>

        <div className="flex items-center gap-1 p-1 bg-slate-100 dark:bg-slate-800 rounded-lg">
          <button
            type="button"
            onClick={() => setView('upload')}
            className={`px-3 py-1.5 text-xs font-medium rounded-md ${
              view === 'upload'
                ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white shadow-sm'
                : 'text-slate-600 dark:text-slate-400'
            }`}
          >
            Upload new
          </button>
          <button
            type="button"
            onClick={() => setView('mine')}
            className={`px-3 py-1.5 text-xs font-medium rounded-md ${
              view === 'mine'
                ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white shadow-sm'
                : 'text-slate-600 dark:text-slate-400'
            }`}
          >
            My contributions ({documents.length})
          </button>
        </div>
      </div>

      {view === 'mine' ? (
        <div className="space-y-3">
          {documents.map((doc) => {
            const st = statusLabel(doc.status);
            return (
              <div
                key={doc.id}
                className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 space-y-2"
              >
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <div className="text-xs text-slate-500 dark:text-slate-400">
                      {doc.subject} · {doc.educationSystem} · {doc.level} · {doc.language.toUpperCase()}
                    </div>
                    <h2 className="font-display font-semibold text-base text-slate-900 dark:text-white">
                      {doc.title}
                    </h2>
                  </div>
                  <span className={`text-xs font-semibold shrink-0 ${st.cls}`}>{st.text}</span>
                </div>
                <p className="text-xs text-slate-600 dark:text-slate-400 line-clamp-2">{doc.description}</p>
                {doc.rejectionReason && (
                  <p className="text-xs text-rose-600 dark:text-rose-400">
                    Moderator note: {doc.rejectionReason}
                  </p>
                )}
              </div>
            );
          })}
        </div>
      ) : (
        <form
          onSubmit={handleSubmit}
          className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-6 space-y-5"
        >
          {submittedDoc && (
            <div
              className={`p-4 rounded-xl border space-y-2 ${
                submittedDoc.status === 'under_review'
                  ? 'bg-emerald-50 dark:bg-emerald-950/30 border-emerald-200 dark:border-emerald-800'
                  : 'bg-amber-50 dark:bg-amber-950/30 border-amber-200 dark:border-amber-800'
              }`}
            >
              <div className="flex items-center gap-2 text-sm font-semibold">
                {submittedDoc.status === 'under_review' ? (
                  <>
                    <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                    <span className="text-emerald-900 dark:text-emerald-200">
                      Submitted and passed automated checks — now Under Review
                    </span>
                  </>
                ) : (
                  <>
                    <AlertTriangle className="w-4 h-4 text-amber-600" />
                    <span className="text-amber-900 dark:text-amber-200">
                      Routed to Needs Revision — address the problems below
                    </span>
                  </>
                )}
              </div>
              {submittedDoc.analysis?.problems.map((p) => (
                <div key={p} className="text-xs text-rose-700 dark:text-rose-300">
                  Blocking issue: {p}
                </div>
              ))}
              {submittedDoc.analysis?.warnings.map((w) => (
                <div key={w} className="text-xs text-amber-800 dark:text-amber-300">
                  Moderator warning: {w}
                </div>
              ))}
            </div>
          )}

          <div className="grid sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium mb-1">Document title</label>
              <input
                required
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g. GCE A-Level Thermodynamics Notes"
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-medium mb-1">Course file (PDF, DOCX, TXT)</label>
              <label className="flex items-center gap-2 px-3.5 py-2.5 rounded-xl border border-dashed border-slate-300 dark:border-slate-700 cursor-pointer text-sm text-slate-600 dark:text-slate-300">
                <Upload className="w-4 h-4 text-indigo-600" />
                <span className="truncate">{fileName}</span>
                <input type="file" onChange={handleFileChange} className="hidden" />
              </label>
            </div>

            <div>
              <label className="block text-xs font-medium mb-1">Subject</label>
              <select
                value={subject}
                onChange={(e) => setSubject(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
              >
                <option>Mathematics</option>
                <option>Physics</option>
                <option>Chemistry</option>
                <option>Biology</option>
                <option>Computer Science</option>
                <option>Mathématiques</option>
              </select>
            </div>

            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-xs font-medium mb-1">System</label>
                <select
                  value={educationSystem}
                  onChange={(e) => setEducationSystem(e.target.value)}
                  className="w-full px-3 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
                >
                  <option value="GCE">GCE</option>
                  <option value="Francophone">Francophone</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-medium mb-1">Language</label>
                <select
                  value={language}
                  onChange={(e) => setLanguage(e.target.value as LanguageCode)}
                  className="w-full px-3 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
                >
                  <option value="en">English</option>
                  <option value="fr">Français</option>
                </select>
              </div>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-4">
            <label className="flex items-center gap-2 text-sm text-slate-700 dark:text-slate-300 cursor-pointer">
              <input
                type="checkbox"
                checked={isExamPaper}
                onChange={(e) => setIsExamPaper(e.target.checked)}
                className="rounded border-slate-300 text-indigo-600"
              />
              <span>This is an official past exam paper</span>
            </label>
            {isExamPaper && (
              <div className="flex items-center gap-2">
                <input
                  type="number"
                  value={examYear}
                  onChange={(e) => setExamYear(Number(e.target.value) || 2025)}
                  className="w-24 px-3 py-1.5 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm font-mono tabular-nums"
                />
                <input
                  value={examSession}
                  onChange={(e) => setExamSession(e.target.value)}
                  placeholder="June"
                  className="w-28 px-3 py-1.5 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
                />
              </div>
            )}
          </div>

          <div className="space-y-1.5">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <label className="text-xs font-medium">
                Academic description (minimum {MIN_DESCRIPTION_WORDS} words)
              </label>
              <div className="flex items-center gap-3">
                <button
                  type="button"
                  onClick={() => setDescription(SAMPLE_500_WORD_DESCRIPTION)}
                  className="text-xs text-indigo-600 dark:text-indigo-400 hover:underline"
                >
                  Fill sample 500+ word summary
                </button>
                <span
                  className={`text-xs font-mono tabular-nums font-semibold ${
                    wordValid ? 'text-emerald-600 dark:text-emerald-400' : 'text-amber-600 dark:text-amber-400'
                  }`}
                >
                  {wc} / {MIN_DESCRIPTION_WORDS} words
                </span>
              </div>
            </div>
            <textarea
              required
              rows={6}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Write a thorough summary of the concepts, theorems, and chapters covered in this document..."
              className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
            />
            {spamFlag && (
              <p className="text-xs text-rose-600 dark:text-rose-400">
                Repeated-word spam ratio exceeded. Please provide genuine academic prose.
              </p>
            )}
          </div>

          <div>
            <label className="block text-xs font-medium mb-1">
              Extracted / Course Text Preview (used for AI Tutor & Quiz generation)
            </label>
            <textarea
              rows={3}
              value={contentText}
              onChange={(e) => setContentText(e.target.value)}
              placeholder="Optional: paste key definitions or excerpts from the document..."
              className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
            />
          </div>

          <div className="flex justify-end gap-3">
            <button
              type="submit"
              className="px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold inline-flex items-center gap-2"
            >
              <FileText className="w-4 h-4" />
              <span>Run validation & submit</span>
            </button>
          </div>
        </form>
      )}
    </div>
  );
};
