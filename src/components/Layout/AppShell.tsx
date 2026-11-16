import React from 'react';
import {
  Bell,
  BookOpen,
  CalendarDays,
  Home,
  Moon,
  Sparkles,
  Sun,
  User,
} from 'lucide-react';
import { useMindora } from '../../context/MindoraContext';
import { t } from '../../lib/i18n';
import type { AppTab } from '../../types/mindora';

interface AppShellProps {
  children: React.ReactNode;
}

export const AppShell: React.FC<AppShellProps> = ({ children }) => {
  const { activeTab, setActiveTab, navigate, theme, setTheme, language, notifications, user } =
    useMindora();

  const unreadCount = notifications.filter((n) => !n.read).length;

  const navItems: Array<{ id: AppTab; label: string; icon: React.ComponentType<{ className?: string }> }> = [
    { id: 'home', label: t(language, 'navHome'), icon: Home },
    { id: 'ai', label: t(language, 'navAi'), icon: Sparkles },
    { id: 'planner', label: t(language, 'navPlanner'), icon: CalendarDays },
    { id: 'learn', label: t(language, 'navLearn'), icon: BookOpen },
    { id: 'profile', label: t(language, 'navProfile'), icon: User },
  ];

  return (
    <div className="min-h-screen flex flex-col md:flex-row bg-slate-50 text-slate-900 dark:bg-slate-950 dark:text-slate-50">
      {/* Desktop Left Navigation Rail */}
      <aside className="hidden md:flex md:w-60 md:shrink-0 md:flex-col border-r border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900">
        <div className="h-16 px-5 flex items-center gap-3 border-b border-slate-200 dark:border-slate-800">
          <img
            src="/mindora-logo.png"
            alt="MINDORA"
            className="w-8 h-8 rounded-lg object-contain shrink-0"
            referrerPolicy="no-referrer"
          />
          <span className="font-display font-bold text-lg tracking-tight text-slate-900 dark:text-white whitespace-nowrap">
            MINDORA
          </span>
        </div>

        <nav className="flex-1 p-3 space-y-1" aria-label="Primary Navigation">
          {navItems.map((item) => {
            const Icon = item.icon;
            const active = activeTab === item.id;
            return (
              <button
                key={item.id}
                type="button"
                onClick={() => setActiveTab(item.id)}
                className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-colors whitespace-nowrap ${
                  active
                    ? 'bg-indigo-50 text-indigo-700 dark:bg-indigo-500/15 dark:text-indigo-300'
                    : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-slate-100'
                }`}
              >
                <Icon className="w-5 h-5 shrink-0" />
                <span>{item.label}</span>
              </button>
            );
          })}
        </nav>

        <div className="p-4 border-t border-slate-200 dark:border-slate-800 space-y-2">
          <button
            type="button"
            onClick={() => navigate('profile', { type: 'notifications' })}
            className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800 transition-colors"
          >
            <span className="flex items-center gap-2">
              <Bell className="w-4 h-4" />
              Notifications
            </span>
            {unreadCount > 0 && (
              <span className="font-mono tabular-nums text-xs font-semibold text-indigo-600 dark:text-indigo-400">
                {unreadCount}
              </span>
            )}
          </button>
          <button
            type="button"
            onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
            className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800 transition-colors"
          >
            <span className="flex items-center gap-2">
              {theme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
              {theme === 'dark' ? 'Light theme' : 'Dark theme'}
            </span>
          </button>
        </div>
      </aside>

      {/* Main Content Column */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Top Bar (3-zone contract) */}
        <header className="h-16 px-4 sm:px-6 bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between gap-4 shrink-0">
          <div className="flex items-center gap-2.5 md:hidden">
            <img
              src="/mindora-logo.png"
              alt="MINDORA"
              className="w-7 h-7 rounded-md object-contain shrink-0"
              referrerPolicy="no-referrer"
            />
            <span className="font-display font-bold text-base tracking-tight text-slate-900 dark:text-white whitespace-nowrap shrink-0">
              MINDORA
            </span>
          </div>

          <div className="hidden md:flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400 truncate">
            <span className="font-medium text-slate-900 dark:text-slate-100">
              {user?.educationProfile.targetExamName || 'Exam Preparation'}
            </span>
            <span aria-hidden="true">·</span>
            <span className="truncate">
              {user?.educationProfile.educationSystem} {user?.educationProfile.level}
            </span>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            <button
              type="button"
              onClick={() => navigate('profile', { type: 'notifications' })}
              aria-label="Open notifications"
              className="md:hidden relative p-2 rounded-lg text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800"
            >
              <Bell className="w-5 h-5" />
              {unreadCount > 0 && (
                <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-indigo-600" />
              )}
            </button>
            <button
              type="button"
              onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
              aria-label="Toggle theme"
              className="md:hidden p-2 rounded-lg text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800"
            >
              {theme === 'dark' ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('ai')}
              className="px-3.5 py-2 rounded-lg bg-indigo-600 hover:bg-indigo-700 dark:bg-indigo-500 dark:hover:bg-indigo-600 text-white text-xs font-semibold transition-colors whitespace-nowrap shrink-0 flex items-center gap-1.5"
            >
              <Sparkles className="w-3.5 h-3.5" />
              <span>{t(language, 'askAi')}</span>
            </button>
          </div>
        </header>

        {/* Scrollable Workspace Viewport */}
        <main className="flex-1 overflow-y-auto pb-20 md:pb-8">
          <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-6">{children}</div>
        </main>
      </div>

      {/* Mobile Bottom Navigation */}
      <nav
        className="md:hidden fixed bottom-0 inset-x-0 z-30 bg-white dark:bg-slate-900 border-t border-slate-200 dark:border-slate-800 flex items-center justify-around h-16 px-1"
        aria-label="Mobile Navigation"
      >
        {navItems.map((item) => {
          const Icon = item.icon;
          const active = activeTab === item.id;
          return (
            <button
              key={item.id}
              type="button"
              onClick={() => setActiveTab(item.id)}
              className={`flex flex-col items-center justify-center gap-1 px-2 py-1.5 rounded-lg min-w-[56px] text-[11px] font-medium transition-colors ${
                active
                  ? 'text-indigo-600 dark:text-indigo-400'
                  : 'text-slate-500 dark:text-slate-400'
              }`}
            >
              <Icon className="w-5 h-5" />
              <span className="truncate">{item.label}</span>
            </button>
          );
        })}
      </nav>
    </div>
  );
};
