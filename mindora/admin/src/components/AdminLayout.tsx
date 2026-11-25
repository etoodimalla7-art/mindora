import React, { useEffect, useState } from "react";
import { Link, Outlet, useLocation } from "react-router-dom";
import {
  Activity,
  BarChart3,
  Bot,
  FileCheck2,
  FileText,
  Globe,
  KeyRound,
  LayoutDashboard,
  LifeBuoy,
  LogOut,
  Megaphone,
  Menu,
  Moon,
  Settings,
  ShieldAlert,
  Sun,
  Users,
  X,
} from "lucide-react";
import { useAuth } from "../lib/auth";
import { useI18n } from "../i18n";

export function AdminLayout() {
  const { session, hasPermission, logout } = useAuth();
  const { dict, locale, setLocale } = useI18n();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [theme, setTheme] = useState<"dark" | "light">(() =>
    localStorage.getItem("mindora_admin_theme") === "light" ? "light" : "dark"
  );

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", theme);
    localStorage.setItem("mindora_admin_theme", theme);
  }, [theme]);

  const navItems = [
    { to: "/dashboard", label: dict.nav.dashboard, icon: LayoutDashboard, perm: "" },
    { to: "/analytics", label: dict.nav.analytics, icon: BarChart3, perm: "analytics.read" },
    { to: "/users", label: dict.nav.users, icon: Users, perm: "users.read" },
    { to: "/papers", label: dict.nav.papers, icon: FileText, perm: "documents.read" },
    { to: "/moderation", label: dict.nav.moderation, icon: FileCheck2, perm: "documents.read" },
    { to: "/ai", label: dict.nav.ai, icon: Bot, perm: "ai.read" },
    { to: "/content", label: dict.nav.content, icon: Globe, perm: "content.manage" },
    { to: "/broadcasts", label: dict.nav.broadcasts, icon: Megaphone, perm: "notifications.manage" },
    { to: "/support", label: dict.nav.support, icon: LifeBuoy, perm: "support.read" },
    { to: "/security", label: dict.nav.security, icon: ShieldAlert, perm: "security.read" },
    { to: "/sessions", label: dict.nav.sessions, icon: KeyRound, perm: "users.read" },
    { to: "/settings", label: dict.nav.settings, icon: Settings, perm: "system.manage" },
  ].filter((item) => !item.perm || hasPermission(item.perm));

  return (
    <div
      className="min-h-screen flex"
      style={{ backgroundColor: "var(--bg-base)", color: "var(--text-primary)" }}
    >
      {/* Mobile overlay */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-30 lg:hidden"
          style={{ backgroundColor: "rgba(2, 6, 23, 0.7)" }}
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`fixed inset-y-0 left-0 z-40 w-64 transform transition-transform duration-200 lg:static lg:translate-x-0 flex flex-col border-r ${
          sidebarOpen ? "translate-x-0" : "-translate-x-full"
        }`}
        style={{
          backgroundColor: "var(--bg-surface)",
          borderColor: "var(--border-subtle)",
        }}
      >
        <div
          className="h-16 px-5 flex items-center justify-between border-b"
          style={{ borderColor: "var(--border-subtle)" }}
        >
          <div className="flex items-center gap-3">
            <div
              className="w-9 h-9 rounded-xl flex items-center justify-center font-bold text-sm"
              style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
            >
              M
            </div>
            <div>
              <div className="font-semibold text-sm leading-tight">{dict.appName}</div>
              <div className="text-xs" style={{ color: "var(--text-secondary)" }}>
                {dict.appSubtitle}
              </div>
            </div>
          </div>
          <button
            type="button"
            className="lg:hidden p-1 rounded"
            onClick={() => setSidebarOpen(false)}
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <nav className="flex-1 p-3 space-y-1 overflow-y-auto">
          {navItems.map((item) => {
            const Icon = item.icon;
            const active =
              location.pathname === item.to ||
              location.pathname.startsWith(`${item.to}/`);
            return (
              <Link
                key={item.to}
                to={item.to}
                onClick={() => setSidebarOpen(false)}
                className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-colors"
                style={{
                  backgroundColor: active ? "var(--brand-soft)" : "transparent",
                  color: active ? "var(--brand)" : "var(--text-secondary)",
                }}
              >
                <Icon className="w-4 h-4 shrink-0" />
                <span>{item.label}</span>
              </Link>
            );
          })}
        </nav>

        <div
          className="p-3 border-t space-y-2"
          style={{ borderColor: "var(--border-subtle)" }}
        >
          <a
            href="/"
            className="flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-medium transition-colors"
            style={{ color: "var(--text-secondary)" }}
          >
            <Activity className="w-4 h-4" />
            <span>{dict.nav.publicSite}</span>
          </a>
          <div className="px-3 py-1.5 text-xs truncate" style={{ color: "var(--text-muted)" }}>
            {session?.user.email}
          </div>
          <button
            type="button"
            onClick={() => logout()}
            className="w-full flex items-center gap-2 px-3 py-2 rounded-xl text-sm font-medium cursor-pointer"
            style={{ backgroundColor: "var(--danger-soft)", color: "var(--danger)" }}
          >
            <LogOut className="w-4 h-4" />
            <span>{dict.nav.logout}</span>
          </button>
        </div>
      </aside>

      {/* Main */}
      <div className="flex-1 flex flex-col min-w-0">
        <header
          className="h-16 px-4 sm:px-6 flex items-center justify-between border-b shrink-0"
          style={{
            backgroundColor: "var(--bg-surface)",
            borderColor: "var(--border-subtle)",
          }}
        >
          <button
            type="button"
            className="lg:hidden p-2 rounded-lg"
            style={{ backgroundColor: "var(--bg-elevated)" }}
            onClick={() => setSidebarOpen(true)}
          >
            <Menu className="w-5 h-5" />
          </button>

          <div className="hidden lg:flex items-center gap-2 text-xs" style={{ color: "var(--text-secondary)" }}>
            <span>{session?.roles?.join(" · ") || "admin"}</span>
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => setLocale(locale === "fr" ? "en" : "fr")}
              className="px-3 py-1.5 rounded-lg text-xs font-semibold border cursor-pointer"
              style={{
                backgroundColor: "var(--bg-elevated)",
                borderColor: "var(--border-subtle)",
                color: "var(--text-primary)",
              }}
            >
              {locale === "fr" ? dict.common.languageEn : dict.common.languageFr}
            </button>
            <button
              type="button"
              onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
              className="p-2 rounded-lg border cursor-pointer"
              title={theme === "dark" ? dict.common.lightTheme : dict.common.darkTheme}
              style={{
                backgroundColor: "var(--bg-elevated)",
                borderColor: "var(--border-subtle)",
                color: "var(--text-primary)",
              }}
            >
              {theme === "dark" ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
            </button>
          </div>
        </header>

        <main className="flex-1 p-4 sm:p-6 lg:p-8 overflow-y-auto">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
