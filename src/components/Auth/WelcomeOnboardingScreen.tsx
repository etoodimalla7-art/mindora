import React, { useState } from 'react';
import { ArrowRight, Check, GraduationCap, Sparkles } from 'lucide-react';
import { useMindora } from '../../context/MindoraContext';
import type { EducationProfile, LanguageCode } from '../../types/mindora';

const AVAILABLE_SUBJECTS = [
  'Mathematics',
  'Physics',
  'Chemistry',
  'Biology',
  'Computer Science',
  'Mathématiques',
  'Economics',
  'Literature',
];

export const WelcomeOnboardingScreen: React.FC = () => {
  const { user, language, setLanguage, signInDemo, registerOrSignIn, completeOnboarding } = useMindora();
  const [authMode, setAuthMode] = useState<'welcome' | 'register'>('welcome');
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [step, setStep] = useState(0);

  const [selectedLang, setSelectedLang] = useState<LanguageCode>(language);
  const [country, setCountry] = useState('Cameroon');
  const [educationSystem, setEducationSystem] = useState('GCE');
  const [level, setLevel] = useState('Advanced Level');
  const [program, setProgram] = useState('Science');
  const [subjects, setSubjects] = useState<string[]>(['Mathematics', 'Physics']);
  const [goal, setGoal] = useState('Pass with distinction');
  const [targetExamName, setTargetExamName] = useState('GCE Advanced Level 2027');
  const [targetExamDate, setTargetExamDate] = useState('2027-06-05');
  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const [aiStyle, setAiStyle] = useState<EducationProfile['aiStyle']>('step_by_step');

  const toggleSubject = (s: string) => {
    setSubjects((prev) => (prev.includes(s) ? prev.filter((item) => item !== s) : [...prev, s]));
  };

  if (!user) {
    return (
      <div className="min-h-screen bg-slate-50 dark:bg-slate-950 flex items-center justify-center p-4">
        <div className="w-full max-w-4xl grid md:grid-cols-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl overflow-hidden">
          <div className="p-8 sm:p-10 bg-indigo-600 text-white flex flex-col justify-between">
            <div>
              <div className="flex items-center gap-3 mb-8">
                <img
                  src="/mindora-logo.png"
                  alt="MINDORA"
                  className="w-10 h-10 rounded-xl bg-white p-1 object-contain"
                  referrerPolicy="no-referrer"
                />
                <span className="font-display font-bold text-xl tracking-tight">MINDORA</span>
              </div>
              <h1 className="font-display text-3xl font-bold tracking-tight leading-tight text-balance">
                Learn smarter. Prepare better.
              </h1>
              <p className="mt-4 text-indigo-100 text-sm leading-relaxed">
                Course-grounded AI tutoring, personalized exam roadmaps, spaced-repetition flashcards, and timed mock exams built around your syllabus.
              </p>
            </div>
            <div className="mt-8 pt-6 border-t border-indigo-500/40 space-y-2 text-xs text-indigo-100">
              <div>01. Study with an AI tutor tuned to your course notes</div>
              <div>02. Build an exam roadmap with daily focus sessions</div>
              <div>03. Measure honest readiness across 6 dimensions</div>
            </div>
          </div>

          <div className="p-8 sm:p-10 flex flex-col justify-center">
            {authMode === 'welcome' ? (
              <div className="space-y-6">
                <div>
                  <h2 className="font-display text-2xl font-bold text-slate-900 dark:text-white">
                    Welcome to MINDORA
                  </h2>
                  <p className="mt-1.5 text-sm text-slate-600 dark:text-slate-400">
                    Enter immediately with a pre-configured student workspace or create a new account.
                  </p>
                </div>

                <div className="space-y-3">
                  <button
                    type="button"
                    onClick={signInDemo}
                    className="w-full py-3 px-4 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold transition-colors flex items-center justify-center gap-2"
                  >
                    <Sparkles className="w-4 h-4" />
                    <span>Continue to Student Workspace</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setAuthMode('register')}
                    className="w-full py-3 px-4 rounded-xl border border-slate-300 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-800 dark:text-slate-200 text-sm font-semibold transition-colors"
                  >
                    Create a new student profile
                  </button>
                </div>
              </div>
            ) : (
              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  if (!email.trim()) return;
                  registerOrSignIn({ fullName, email });
                }}
                className="space-y-4"
              >
                <div>
                  <h2 className="font-display text-xl font-bold text-slate-900 dark:text-white">
                    Create your account
                  </h2>
                  <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
                    This saves your study plan, flashcards, and readiness progress.
                  </p>
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Full name
                  </label>
                  <input
                    type="text"
                    required
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    placeholder="e.g. Jean Baptiste"
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Email address
                  </label>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="student@school.edu"
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
                  />
                </div>
                <div className="flex items-center gap-3 pt-2">
                  <button
                    type="button"
                    onClick={() => setAuthMode('welcome')}
                    className="px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 text-sm font-medium text-slate-700 dark:text-slate-300"
                  >
                    Back
                  </button>
                  <button
                    type="submit"
                    className="flex-1 py-2.5 px-4 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold transition-colors"
                  >
                    Continue to onboarding
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      </div>
    );
  }

  const steps = [
    {
      title: 'Choose your language',
      subtitle: 'You can change this later in settings.',
      body: (
        <div className="grid grid-cols-2 gap-3">
          {(['en', 'fr'] as const).map((code) => (
            <button
              key={code}
              type="button"
              onClick={() => {
                setSelectedLang(code);
                setLanguage(code);
              }}
              className={`p-4 rounded-xl border text-left transition-colors ${
                selectedLang === code
                  ? 'border-indigo-600 bg-indigo-50 dark:bg-indigo-500/15 dark:border-indigo-400'
                  : 'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800'
              }`}
            >
              <div className="font-semibold text-sm text-slate-900 dark:text-white">
                {code === 'en' ? 'English' : 'Français'}
              </div>
              <div className="text-xs text-slate-500 dark:text-slate-400 mt-1">
                {code === 'en' ? 'Interface & tutor in English' : 'Interface et tuteur en français'}
              </div>
            </button>
          ))}
        </div>
      ),
    },
    {
      title: 'Academic profile',
      subtitle: 'We use this to match your education system and calibrate explanations.',
      body: (
        <div className="grid sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-medium mb-1">Country</label>
            <input
              value={country}
              onChange={(e) => setCountry(e.target.value)}
              className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
            />
          </div>
          <div>
            <label className="block text-xs font-medium mb-1">Education system</label>
            <select
              value={educationSystem}
              onChange={(e) => setEducationSystem(e.target.value)}
              className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
            >
              <option value="GCE">GCE</option>
              <option value="Francophone">Francophone (BEPC / Bac)</option>
              <option value="IB">International Baccalaureate</option>
              <option value="University">University</option>
            </select>
          </div>
          <div>
            <label className="block text-xs font-medium mb-1">Level</label>
            <select
              value={level}
              onChange={(e) => setLevel(e.target.value)}
              className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
            >
              <option value="Ordinary Level">Ordinary Level</option>
              <option value="Advanced Level">Advanced Level</option>
              <option value="BEPC">BEPC</option>
              <option value="Bac">Baccalauréat</option>
              <option value="Licence">Licence</option>
              <option value="Master">Master</option>
            </select>
          </div>
          <div>
            <label className="block text-xs font-medium mb-1">Program / Track</label>
            <input
              value={program}
              onChange={(e) => setProgram(e.target.value)}
              placeholder="Science, Arts, Engineering..."
              className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
            />
          </div>
        </div>
      ),
    },
    {
      title: 'Your subjects & target exam',
      subtitle: 'Pick the subjects you will be examined on and your target date.',
      body: (
        <div className="space-y-4">
          <div className="flex flex-wrap gap-2">
            {AVAILABLE_SUBJECTS.map((subj) => {
              const active = subjects.includes(subj);
              return (
                <button
                  key={subj}
                  type="button"
                  onClick={() => toggleSubject(subj)}
                  className={`px-3 py-2 rounded-lg text-xs font-medium border transition-colors ${
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
          <div className="grid sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium mb-1">Target examination</label>
              <input
                value={targetExamName}
                onChange={(e) => setTargetExamName(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-medium mb-1">Target exam date</label>
              <input
                type="date"
                value={targetExamDate}
                onChange={(e) => setTargetExamDate(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
              />
            </div>
          </div>
        </div>
      ),
    },
    {
      title: 'Personalize your AI tutor',
      subtitle: 'Choose your preferred explanation style and study reminder preference.',
      body: (
        <div className="space-y-4">
          <div className="grid sm:grid-cols-2 gap-3">
            {[
              { id: 'step_by_step', label: 'Step-by-step', desc: 'Clear numbered derivations' },
              { id: 'socratic', label: 'Socratic guide', desc: 'Guiding questions before answers' },
              { id: 'example_rich', label: 'Worked examples', desc: 'Concrete problems first' },
              { id: 'concise', label: 'Concise', desc: 'Direct definitions and formulas' },
            ].map((item) => (
              <button
                key={item.id}
                type="button"
                onClick={() => setAiStyle(item.id as EducationProfile['aiStyle'])}
                className={`p-3.5 rounded-xl border text-left transition-colors ${
                  aiStyle === item.id
                    ? 'border-indigo-600 bg-indigo-50 dark:bg-indigo-500/15 dark:border-indigo-400'
                    : 'border-slate-200 dark:border-slate-700'
                }`}
              >
                <div className="text-sm font-semibold text-slate-900 dark:text-white">{item.label}</div>
                <div className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">{item.desc}</div>
              </button>
            ))}
          </div>
          <label className="flex items-center gap-3 p-3.5 rounded-xl border border-slate-200 dark:border-slate-700 cursor-pointer">
            <input
              type="checkbox"
              checked={notificationsEnabled}
              onChange={(e) => setNotificationsEnabled(e.target.checked)}
              className="rounded border-slate-300 text-indigo-600"
            />
            <span className="text-sm text-slate-700 dark:text-slate-300">
              Enable study session reminders and exam countdown alerts
            </span>
          </label>
        </div>
      ),
    },
  ];

  const current = steps[step];
  const isLast = step === steps.length - 1;

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 flex items-center justify-center p-4">
      <div className="w-full max-w-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-6 sm:p-8 space-y-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 text-xs font-medium text-slate-500 dark:text-slate-400">
            <GraduationCap className="w-4 h-4 text-indigo-600 dark:text-indigo-400" />
            <span>
              Step {step + 1} of {steps.length}
            </span>
          </div>
          <div className="flex gap-1.5">
            {steps.map((_, idx) => (
              <div
                key={idx}
                className={`h-1.5 w-8 rounded-full ${
                  idx <= step ? 'bg-indigo-600 dark:bg-indigo-400' : 'bg-slate-200 dark:bg-slate-800'
                }`}
              />
            ))}
          </div>
        </div>

        <div>
          <h2 className="font-display text-2xl font-bold text-slate-900 dark:text-white">{current.title}</h2>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">{current.subtitle}</p>
        </div>

        <div>{current.body}</div>

        <div className="flex items-center justify-between pt-4 border-t border-slate-200 dark:border-slate-800">
          <button
            type="button"
            disabled={step === 0}
            onClick={() => setStep((s) => Math.max(0, s - 1))}
            className="px-4 py-2 rounded-xl border border-slate-300 dark:border-slate-700 text-sm font-medium disabled:opacity-40"
          >
            Back
          </button>
          {!isLast ? (
            <button
              type="button"
              onClick={() => setStep((s) => s + 1)}
              className="px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold flex items-center gap-2"
            >
              <span>Next</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          ) : (
            <button
              type="button"
              onClick={() =>
                completeOnboarding(
                  {
                    country,
                    educationSystem,
                    level,
                    program,
                    subjects: subjects.length > 0 ? subjects : ['Mathematics'],
                    goal,
                    targetExamName,
                    targetExamDate,
                    preferredStudyTimes: ['Evening (19:00 - 21:00)'],
                    notificationsEnabled,
                    aiStyle,
                  },
                  selectedLang
                )
              }
              className="px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold flex items-center gap-2"
            >
              <Check className="w-4 h-4" />
              <span>Finish setup</span>
            </button>
          )}
        </div>
      </div>
    </div>
  );
};
