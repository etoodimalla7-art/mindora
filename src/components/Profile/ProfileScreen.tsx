import React, { useState } from 'react';
import {
  ArrowLeft,
  Bell,
  CalendarCheck,
  Check,
  CheckCircle2,
  Clock,
  Coins,
  CreditCard,
  Flame,
  Globe,
  LogOut,
  Moon,
  Play,
  RotateCcw,
  Shield,
  Sun,
  Trophy,
  XCircle,
} from 'lucide-react';
import { useMindora } from '../../context/MindoraContext';
import { SUBSCRIPTION_PLANS } from '../../data/seedData';
import { t } from '../../lib/i18n';

export const ProfileScreen: React.FC = () => {
  const {
    user,
    theme,
    setTheme,
    language,
    setLanguage,
    toggleRole,
    creditsBalance,
    creditHistory,
    activeSubscriptionCode,
    notifications,
    xpEvents,
    xpLevel,
    studyStreak,
    claimDailyCheckIn,
    navigate,
    subView,
    setSubView,
    signOut,
    resetDemoWorkspace,
  } = useMindora();

  if (!user) return null;

  if (subView.type === 'notifications') {
    return <NotificationsSubView />;
  }
  if (subView.type === 'subscription') {
    return <SubscriptionSubView />;
  }
  if (subView.type === 'admin_moderation') {
    return <AdminModerationSubView />;
  }

  const unreadCount = notifications.filter((n) => !n.read).length;

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      {/* Header */}
      <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-6 flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-full bg-indigo-100 dark:bg-indigo-500/20 text-indigo-700 dark:text-indigo-300 font-display font-bold text-2xl flex items-center justify-center">
            {user.fullName.charAt(0).toUpperCase()}
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="font-display text-xl font-bold text-slate-900 dark:text-white">
                {user.fullName}
              </h1>
              <span className="text-xs font-medium text-indigo-600 dark:text-indigo-400">
                {user.role === 'admin' ? 'Moderator' : 'Student'}
              </span>
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400">{user.email}</p>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              {user.educationProfile.country} · {user.educationProfile.educationSystem} ·{' '}
              {user.educationProfile.level}
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={() => toggleRole(user.role === 'admin' ? 'student' : 'admin')}
          className="px-3.5 py-2 rounded-xl border border-slate-200 dark:border-slate-700 text-xs font-semibold hover:bg-slate-50 dark:hover:bg-slate-800 inline-flex items-center gap-1.5"
        >
          <Shield className="w-3.5 h-3.5 text-indigo-600 dark:text-indigo-400" />
          <span>{user.role === 'admin' ? 'Switch to Student view' : 'Enable Moderator view'}</span>
        </button>
      </div>

      {/* Study Streak & XP Level */}
      <div className="grid md:grid-cols-2 gap-4">
        {/* XP Level & Progression */}
        <section className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 flex flex-col justify-between space-y-4">
          <div className="space-y-4">
            <div className="flex items-start justify-between gap-3">
              <div className="flex items-center gap-3">
                <div className="w-11 h-11 rounded-xl bg-indigo-50 dark:bg-indigo-500/15 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shrink-0">
                  <Trophy className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-xs text-slate-500 dark:text-slate-400">
                    {t(language, 'xpLevelTitle')}
                  </div>
                  <h2 className="font-display text-lg font-bold text-slate-900 dark:text-white">
                    {t(language, 'levelLabel')} {xpLevel.level} ·{' '}
                    {language === 'fr' ? xpLevel.titleFr : xpLevel.titleEn}
                  </h2>
                </div>
              </div>
              <div className="text-right shrink-0">
                <div className="font-mono tabular-nums text-lg font-bold text-indigo-600 dark:text-indigo-400">
                  {xpLevel.totalXp.toLocaleString()} XP
                </div>
                <div className="text-xs text-slate-500 dark:text-slate-400">
                  {t(language, 'totalXp')}
                </div>
              </div>
            </div>

            <div className="space-y-2">
              <div className="flex items-center justify-between text-xs">
                <span className="font-mono tabular-nums font-medium text-slate-700 dark:text-slate-300">
                  {xpLevel.xpIntoLevel} / {xpLevel.xpForNextLevel} XP
                </span>
                <span className="font-mono tabular-nums text-slate-500 dark:text-slate-400">
                  {xpLevel.xpRemaining} {t(language, 'xpToNextLevel')}
                </span>
              </div>
              <div
                className="h-2.5 w-full rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden"
                role="progressbar"
                aria-valuenow={xpLevel.progressPercent}
                aria-valuemin={0}
                aria-valuemax={100}
                aria-label={t(language, 'xpLevelTitle')}
              >
                <div
                  className="h-full rounded-full bg-indigo-600 dark:bg-indigo-400 transition-all duration-300"
                  style={{ width: `${Math.max(4, xpLevel.progressPercent)}%` }}
                />
              </div>
            </div>

            {xpEvents.length > 0 && (
              <div className="pt-3 border-t border-slate-100 dark:border-slate-800 space-y-2">
                <div className="text-xs font-semibold text-slate-700 dark:text-slate-300">
                  {t(language, 'recentXpActivity')}
                </div>
                <div className="space-y-1.5">
                  {xpEvents.slice(0, 3).map((evt) => (
                    <div key={evt.id} className="flex items-center justify-between gap-2 text-xs">
                      <span className="text-slate-600 dark:text-slate-400 truncate">{evt.reason}</span>
                      <span className="font-mono tabular-nums font-semibold text-emerald-600 dark:text-emerald-400 shrink-0">
                        +{evt.amount} XP
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          <p className="text-xs text-slate-500 dark:text-slate-400 pt-2 border-t border-slate-100 dark:border-slate-800">
            {t(language, 'howToEarnXp')}
          </p>
        </section>

        {/* Study Streak & 7-Day Consistency */}
        <section className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 flex flex-col justify-between space-y-4">
          <div className="space-y-4">
            <div className="flex items-start justify-between gap-3">
              <div className="flex items-center gap-3">
                <div
                  className={`w-11 h-11 rounded-xl flex items-center justify-center shrink-0 ${
                    studyStreak.currentStreak > 0
                      ? 'bg-amber-500/15 text-amber-600 dark:text-amber-400'
                      : 'bg-slate-100 dark:bg-slate-800 text-slate-400'
                  }`}
                >
                  <Flame className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-xs text-slate-500 dark:text-slate-400">
                    {t(language, 'studyStreak')}
                  </div>
                  <h2 className="font-display text-lg font-bold font-mono tabular-nums text-slate-900 dark:text-white">
                    {studyStreak.currentStreak}{' '}
                    {studyStreak.currentStreak === 1 ? t(language, 'dayLabel') : t(language, 'daysLabel')}
                  </h2>
                </div>
              </div>

              <div className="text-right text-xs text-slate-500 dark:text-slate-400 space-y-0.5 shrink-0">
                <div className="font-mono tabular-nums">
                  {t(language, 'longestStreak')}: <span className="font-semibold text-slate-900 dark:text-white">{studyStreak.longestStreak}</span>
                </div>
                <div className="font-mono tabular-nums">
                  {t(language, 'activeDays')}: <span className="font-semibold text-slate-900 dark:text-white">{studyStreak.totalActiveDays}</span>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2 text-xs">
              {studyStreak.activeToday ? (
                <>
                  <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                  <span className="font-medium text-emerald-700 dark:text-emerald-300">
                    {t(language, 'checkedInToday')}
                  </span>
                </>
              ) : (
                <>
                  <Clock className="w-4 h-4 text-amber-600 dark:text-amber-400 shrink-0" />
                  <span className="text-slate-600 dark:text-slate-300">
                    {studyStreak.atRisk ? t(language, 'keepStreakAlive') : t(language, 'startStreakToday')}
                  </span>
                </>
              )}
            </div>

            <div className="space-y-2 pt-1">
              <div className="text-xs font-medium text-slate-500 dark:text-slate-400">
                {t(language, 'last7Days')}
              </div>
              <div className="grid grid-cols-7 gap-1.5">
                {studyStreak.last7Days.map((day) => (
                  <div key={day.date} className="flex flex-col items-center gap-1.5">
                    <div
                      title={day.date}
                      className={`w-full h-9 rounded-lg flex items-center justify-center transition-colors ${
                        day.active
                          ? 'bg-amber-500/15 text-amber-600 dark:text-amber-400 border border-amber-500/30'
                          : day.isToday
                            ? 'bg-slate-50 dark:bg-slate-800/80 border border-dashed border-indigo-400 dark:border-indigo-500 text-indigo-500'
                            : 'bg-slate-100 dark:bg-slate-800/60 text-slate-400 dark:text-slate-500'
                      }`}
                    >
                      {day.active ? (
                        <Check className="w-4 h-4" />
                      ) : (
                        <span className="text-[11px] font-mono tabular-nums">
                          {day.date.slice(8)}
                        </span>
                      )}
                    </div>
                    <span
                      className={`text-[11px] ${
                        day.isToday
                          ? 'font-semibold text-indigo-600 dark:text-indigo-400'
                          : 'text-slate-500 dark:text-slate-400'
                      }`}
                    >
                      {language === 'fr' ? day.labelFr : day.labelEn}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {!studyStreak.activeToday ? (
            <button
              type="button"
              onClick={() => {
                claimDailyCheckIn();
              }}
              className="w-full py-2.5 px-4 rounded-xl bg-indigo-600 hover:bg-indigo-700 dark:bg-indigo-500 dark:hover:bg-indigo-600 text-white text-xs font-semibold inline-flex items-center justify-center gap-2 transition-colors whitespace-nowrap"
            >
              <CalendarCheck className="w-4 h-4 shrink-0" />
              <span>{t(language, 'dailyCheckIn')}</span>
            </button>
          ) : (
            <button
              type="button"
              onClick={() => navigate('planner')}
              className="w-full py-2.5 px-4 rounded-xl border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-200 text-xs font-semibold inline-flex items-center justify-center gap-2 transition-colors whitespace-nowrap"
            >
              <Play className="w-3.5 h-3.5 shrink-0 text-indigo-600 dark:text-indigo-400" />
              <span>{t(language, 'practiceToday')}</span>
            </button>
          )}
        </section>
      </div>

      {/* Credits & Subscription */}
      <div className="grid sm:grid-cols-2 gap-4">
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-xl bg-amber-500/15 text-amber-600 dark:text-amber-400 flex items-center justify-center">
              <Coins className="w-5 h-5" />
            </div>
            <div>
              <div className="font-display font-bold text-lg font-mono tabular-nums text-slate-900 dark:text-white">
                {creditsBalance} credits
              </div>
              <div className="text-xs text-slate-500 dark:text-slate-400">
                Available for past paper downloads
              </div>
            </div>
          </div>
        </div>

        <button
          type="button"
          onClick={() => setSubView({ type: 'subscription' })}
          className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-indigo-300 dark:hover:border-indigo-700 rounded-2xl p-5 flex items-center justify-between text-left transition-colors"
        >
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-xl bg-indigo-50 dark:bg-indigo-500/15 text-indigo-600 dark:text-indigo-400 flex items-center justify-center">
              <CreditCard className="w-5 h-5" />
            </div>
            <div>
              <div className="font-display font-semibold text-base text-slate-900 dark:text-white">
                {activeSubscriptionCode ? 'Active Subscription' : 'Plans & Pricing'}
              </div>
              <div className="text-xs text-slate-500 dark:text-slate-400">
                {activeSubscriptionCode ? activeSubscriptionCode : 'Manage subscription options'}
              </div>
            </div>
          </div>
        </button>
      </div>

      {/* Moderator Queue (when admin role enabled) */}
      {user.role === 'admin' && (
        <button
          type="button"
          onClick={() => setSubView({ type: 'admin_moderation' })}
          className="w-full p-5 rounded-2xl bg-indigo-50/70 dark:bg-indigo-950/30 border border-indigo-200 dark:border-indigo-800 text-left flex items-center justify-between"
        >
          <div className="flex items-center gap-3">
            <Shield className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
            <div>
              <div className="font-display font-semibold text-base text-slate-900 dark:text-white">
                {t(language, 'moderationQueue')}
              </div>
              <div className="text-xs text-slate-600 dark:text-slate-400">
                Approve, request revision, or reject contributed documents and past papers.
              </div>
            </div>
          </div>
          <span className="text-xs font-semibold text-indigo-600 dark:text-indigo-400">Open queue</span>
        </button>
      )}

      {/* Preferences & Settings */}
      <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl divide-y divide-slate-100 dark:divide-slate-800">
        <button
          type="button"
          onClick={() => setSubView({ type: 'notifications' })}
          className="w-full px-5 py-4 flex items-center justify-between text-left hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors"
        >
          <div className="flex items-center gap-3">
            <Bell className="w-4 h-4 text-slate-500" />
            <div>
              <div className="text-sm font-medium text-slate-900 dark:text-white">Notifications & Quiet Hours</div>
              <div className="text-xs text-slate-500 dark:text-slate-400">
                {unreadCount} unread reminders
              </div>
            </div>
          </div>
          <span className="text-xs text-indigo-600 dark:text-indigo-400 font-medium">Manage</span>
        </button>

        <div className="px-5 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Globe className="w-4 h-4 text-slate-500" />
            <div>
              <div className="text-sm font-medium text-slate-900 dark:text-white">Language</div>
              <div className="text-xs text-slate-500 dark:text-slate-400">Interface and AI tutor language</div>
            </div>
          </div>
          <div className="flex items-center gap-1 p-1 bg-slate-100 dark:bg-slate-800 rounded-lg">
            {(['en', 'fr'] as const).map((code) => (
              <button
                key={code}
                type="button"
                onClick={() => setLanguage(code)}
                className={`px-3 py-1 text-xs font-semibold rounded-md ${
                  language === code
                    ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white shadow-sm'
                    : 'text-slate-500'
                }`}
              >
                {code.toUpperCase()}
              </button>
            ))}
          </div>
        </div>

        <div className="px-5 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            {theme === 'dark' ? <Moon className="w-4 h-4 text-slate-500" /> : <Sun className="w-4 h-4 text-slate-500" />}
            <div>
              <div className="text-sm font-medium text-slate-900 dark:text-white">Appearance</div>
              <div className="text-xs text-slate-500 dark:text-slate-400">Light or dark workspace</div>
            </div>
          </div>
          <button
            type="button"
            onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
            className="px-3.5 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700 text-xs font-semibold"
          >
            {theme === 'dark' ? 'Dark' : 'Light'}
          </button>
        </div>
      </div>

      {/* Credit Ledger */}
      <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 space-y-3">
        <h2 className="font-display text-base font-semibold text-slate-900 dark:text-white">
          Credit History
        </h2>
        <div className="divide-y divide-slate-100 dark:divide-slate-800">
          {creditHistory.slice(0, 6).map((item) => (
            <div key={item.id} className="py-2.5 flex items-center justify-between text-xs">
              <span className="text-slate-700 dark:text-slate-300">{item.reason}</span>
              <span
                className={`font-mono tabular-nums font-semibold ${
                  item.delta >= 0 ? 'text-emerald-600 dark:text-emerald-400' : 'text-slate-500'
                }`}
              >
                {item.delta >= 0 ? `+${item.delta}` : item.delta}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* Account Actions */}
      <div className="flex flex-wrap items-center gap-3">
        <button
          type="button"
          onClick={resetDemoWorkspace}
          className="px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 text-xs font-semibold inline-flex items-center gap-2 hover:bg-slate-50 dark:hover:bg-slate-800"
        >
          <RotateCcw className="w-4 h-4" />
          <span>Reset sample workspace</span>
        </button>
        <button
          type="button"
          onClick={signOut}
          className="px-4 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-semibold inline-flex items-center gap-2"
        >
          <LogOut className="w-4 h-4" />
          <span>{t(language, 'signOut')}</span>
        </button>
      </div>
    </div>
  );
};

const NotificationsSubView: React.FC = () => {
  const {
    notifications,
    notificationPrefs,
    markNotificationRead,
    markAllNotificationsRead,
    updateNotificationPrefs,
    setSubView,
  } = useMindora();

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => setSubView({ type: 'none' })}
            className="p-2 rounded-lg border border-slate-200 dark:border-slate-800"
          >
            <ArrowLeft className="w-4 h-4" />
          </button>
          <h1 className="font-display text-2xl font-bold text-slate-900 dark:text-white">Notifications</h1>
        </div>
        <button
          type="button"
          onClick={markAllNotificationsRead}
          className="text-xs font-semibold text-indigo-600 dark:text-indigo-400 hover:underline"
        >
          Mark all read
        </button>
      </div>

      <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 space-y-4">
        <label className="flex items-center justify-between text-sm font-medium cursor-pointer">
          <span>Enable study & exam notifications</span>
          <input
            type="checkbox"
            checked={notificationPrefs.enabled}
            onChange={(e) =>
              updateNotificationPrefs({ ...notificationPrefs, enabled: e.target.checked })
            }
          />
        </label>
        <div className="grid grid-cols-2 gap-4 text-xs">
          <div>
            <label className="block text-slate-500 mb-1">Quiet hours start (0–23)</label>
            <input
              type="number"
              min={0}
              max={23}
              value={notificationPrefs.quietStartHour}
              onChange={(e) =>
                updateNotificationPrefs({
                  ...notificationPrefs,
                  quietStartHour: Number(e.target.value),
                })
              }
              className="w-full px-3 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 font-mono tabular-nums"
            />
          </div>
          <div>
            <label className="block text-slate-500 mb-1">Quiet hours end (0–23)</label>
            <input
              type="number"
              min={0}
              max={23}
              value={notificationPrefs.quietEndHour}
              onChange={(e) =>
                updateNotificationPrefs({
                  ...notificationPrefs,
                  quietEndHour: Number(e.target.value),
                })
              }
              className="w-full px-3 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 font-mono tabular-nums"
            />
          </div>
        </div>
      </div>

      <div className="space-y-3">
        {notifications.map((n) => (
          <button
            key={n.id}
            type="button"
            onClick={() => markNotificationRead(n.id)}
            className={`w-full text-left p-4 rounded-2xl border transition-colors ${
              n.read
                ? 'bg-white dark:bg-slate-900 border-slate-200 dark:border-slate-800 opacity-75'
                : 'bg-indigo-50/50 dark:bg-indigo-950/20 border-indigo-200 dark:border-indigo-800'
            }`}
          >
            <div className="flex items-center justify-between">
              <span className="font-semibold text-sm text-slate-900 dark:text-white">{n.title}</span>
              {!n.read && <span className="text-xs font-semibold text-indigo-600 dark:text-indigo-400">Unread</span>}
            </div>
            <p className="text-xs text-slate-600 dark:text-slate-400 mt-1">{n.body}</p>
          </button>
        ))}
      </div>
    </div>
  );
};

const SubscriptionSubView: React.FC = () => {
  const { activeSubscriptionCode, subscribeToPlan, cancelSubscription, setSubView } = useMindora();

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={() => setSubView({ type: 'none' })}
          className="p-2 rounded-lg border border-slate-200 dark:border-slate-800"
        >
          <ArrowLeft className="w-4 h-4" />
        </button>
        <div>
          <h1 className="font-display text-2xl font-bold text-slate-900 dark:text-white">
            Subscription Plans
          </h1>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            TODO: Connect live Flutterwave / Stripe checkout in production. Currently uses local preview activation.
          </p>
        </div>
      </div>

      <div className="grid md:grid-cols-3 gap-4">
        {SUBSCRIPTION_PLANS.map((plan) => {
          const isCurrent = activeSubscriptionCode === plan.code;
          return (
            <div
              key={plan.code}
              className={`p-6 rounded-2xl border flex flex-col justify-between space-y-5 ${
                isCurrent
                  ? 'border-indigo-600 bg-indigo-50/40 dark:bg-indigo-950/20 dark:border-indigo-400'
                  : 'bg-white dark:bg-slate-900 border-slate-200 dark:border-slate-800'
              }`}
            >
              <div className="space-y-3">
                <div className="font-display font-bold text-lg text-slate-900 dark:text-white">
                  {plan.name}
                </div>
                <div className="font-mono tabular-nums text-2xl font-bold text-indigo-600 dark:text-indigo-400">
                  {plan.amountMinor.toLocaleString()} {plan.currency}
                  <span className="text-xs font-normal text-slate-500"> / {plan.billingCycle}</span>
                </div>
                <p className="text-xs text-slate-600 dark:text-slate-400">{plan.description}</p>
                <ul className="space-y-2 pt-2">
                  {plan.features.map((f) => (
                    <li key={f} className="text-xs text-slate-700 dark:text-slate-300 flex items-center gap-2">
                      <Check className="w-3.5 h-3.5 text-emerald-500 shrink-0" />
                      <span>{f}</span>
                    </li>
                  ))}
                </ul>
              </div>

              {isCurrent ? (
                <button
                  type="button"
                  onClick={cancelSubscription}
                  className="w-full py-2.5 rounded-xl border border-rose-300 text-rose-600 text-xs font-semibold hover:bg-rose-50 dark:hover:bg-rose-950/30"
                >
                  Cancel subscription
                </button>
              ) : (
                <button
                  type="button"
                  onClick={() => subscribeToPlan(plan.code)}
                  className="w-full py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold"
                >
                  Activate plan
                </button>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};

const AdminModerationSubView: React.FC = () => {
  const { documents, moderateDocument, setSubView } = useMindora();
  const [reasonByDoc, setReasonByDoc] = useState<Record<string, string>>({});

  const queue = documents.filter((d) => d.status === 'under_review' || d.status === 'needs_revision');

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={() => setSubView({ type: 'none' })}
          className="p-2 rounded-lg border border-slate-200 dark:border-slate-800"
        >
          <ArrowLeft className="w-4 h-4" />
        </button>
        <div>
          <h1 className="font-display text-2xl font-bold text-slate-900 dark:text-white">
            Moderation Review Queue
          </h1>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Approving awards +5 credits every 5 approved contributions and publishes exam papers to Past Papers.
          </p>
        </div>
      </div>

      {queue.length === 0 ? (
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-8 text-center text-sm text-slate-500">
          All submitted documents have been reviewed.
        </div>
      ) : (
        <div className="space-y-4">
          {queue.map((doc) => (
            <div
              key={doc.id}
              className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-5 space-y-3"
            >
              <div className="flex items-start justify-between gap-4">
                <div>
                  <div className="text-xs text-slate-500 dark:text-slate-400">
                    {doc.subject} · {doc.educationSystem} · Uploaded by {doc.uploaderName}
                  </div>
                  <h2 className="font-display font-semibold text-base text-slate-900 dark:text-white">
                    {doc.title}
                  </h2>
                </div>
                <span className="text-xs font-semibold text-indigo-600 dark:text-indigo-400">
                  {doc.status.replace('_', ' ')}
                </span>
              </div>

              <p className="text-xs text-slate-600 dark:text-slate-400">{doc.description}</p>

              {doc.analysis && (
                <div className="text-xs text-slate-500 dark:text-slate-400 font-mono tabular-nums">
                  Words: {doc.analysis.wordCount} · Detected Lang: {doc.analysis.detectedLanguage.toUpperCase()} ·
                  Duplicate similarity: {Math.round(doc.analysis.duplicateSimilarity * 100)}%
                </div>
              )}

              <div className="flex flex-wrap items-center gap-2 pt-2">
                <input
                  value={reasonByDoc[doc.id] || ''}
                  onChange={(e) => setReasonByDoc((prev) => ({ ...prev, [doc.id]: e.target.value }))}
                  placeholder="Optional rejection/revision note..."
                  className="flex-1 min-w-[200px] px-3 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 text-xs"
                />
                <button
                  type="button"
                  onClick={() => moderateDocument(doc.id, 'approved')}
                  className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-semibold inline-flex items-center gap-1.5"
                >
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  <span>Approve</span>
                </button>
                <button
                  type="button"
                  onClick={() =>
                    moderateDocument(
                      doc.id,
                      'rejected',
                      reasonByDoc[doc.id] || 'Does not meet academic quality criteria.'
                    )
                  }
                  className="px-4 py-2 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-semibold inline-flex items-center gap-1.5"
                >
                  <XCircle className="w-3.5 h-3.5" />
                  <span>Reject</span>
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
