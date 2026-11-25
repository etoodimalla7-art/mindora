import React, { useEffect, useState } from "react";
import { Link, Outlet, useLocation } from "react-router-dom";
import { Download, Menu, Moon, Sun, X } from "lucide-react";
import { useI18n } from "../i18n";

export function SiteLayout() {
  const { dict, locale, setLocale } = useI18n();
  const location = useLocation();
  const [menuOpen, setMenuOpen] = useState(false);
  const [theme, setTheme] = useState<"dark" | "light">(() =>
    localStorage.getItem("mindora_site_theme") === "light" ? "light" : "dark"
  );

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", theme);
    localStorage.setItem("mindora_site_theme", theme);
  }, [theme]);

  const navLinks = [
    { to: "/", label: dict.nav.home },
    { to: "/features", label: dict.nav.features },
    { to: "/pricing", label: dict.nav.pricing },
    { to: "/help", label: dict.nav.help },
    { to: "/contact", label: dict.nav.contact },
  ];

  return (
    <div
      className="min-h-screen flex flex-col"
      style={{ backgroundColor: "var(--bg-base)", color: "var(--text-primary)" }}
    >
      <header
        className="sticky top-0 z-40 border-b backdrop-blur-md"
        style={{
          backgroundColor: "var(--bg-surface)",
          borderColor: "var(--border-subtle)",
        }}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between gap-4">
          <Link to="/" className="flex items-center gap-3">
            <img src="/logo.png" alt="MINDORA" className="w-9 h-9 rounded-xl object-cover" />
            <div>
              <div className="font-bold text-base tracking-tight">{dict.brand}</div>
              <div className="text-[11px] hidden sm:block" style={{ color: "var(--text-secondary)" }}>
                {dict.tagline}
              </div>
            </div>
          </Link>

          <nav className="hidden md:flex items-center gap-1">
            {navLinks.map((n) => {
              const active = location.pathname === n.to;
              return (
                <Link
                  key={n.to}
                  to={n.to}
                  className="px-3 py-2 rounded-xl text-sm font-medium transition-colors"
                  style={{
                    backgroundColor: active ? "var(--brand-soft)" : "transparent",
                    color: active ? "var(--brand)" : "var(--text-secondary)",
                  }}
                >
                  {n.label}
                </Link>
              );
            })}
          </nav>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => setLocale(locale === "fr" ? "en" : "fr")}
              className="px-2.5 py-1.5 rounded-xl text-xs font-semibold border cursor-pointer"
              style={{
                backgroundColor: "var(--bg-elevated)",
                borderColor: "var(--border-subtle)",
              }}
            >
              {locale.toUpperCase()}
            </button>
            <button
              type="button"
              onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
              className="p-2 rounded-xl border cursor-pointer"
              style={{
                backgroundColor: "var(--bg-elevated)",
                borderColor: "var(--border-subtle)",
              }}
              aria-label="Theme"
            >
              {theme === "dark" ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
            </button>
            <a
              href="/app-debug.apk"
              download="mindora-android.apk"
              className="hidden sm:inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold"
              style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
            >
              <Download className="w-3.5 h-3.5" />
              <span>{dict.nav.downloadApk}</span>
            </a>
            <button
              type="button"
              onClick={() => setMenuOpen((v) => !v)}
              className="md:hidden p-2 rounded-xl border"
              style={{ borderColor: "var(--border-subtle)" }}
            >
              {menuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>
        </div>

        {menuOpen && (
          <div
            className="md:hidden px-4 pb-4 space-y-1 border-t"
            style={{ borderColor: "var(--border-subtle)" }}
          >
            {navLinks.map((n) => (
              <Link
                key={n.to}
                to={n.to}
                onClick={() => setMenuOpen(false)}
                className="block px-3 py-2 rounded-xl text-sm font-medium"
                style={{ color: "var(--text-secondary)" }}
              >
                {n.label}
              </Link>
            ))}
            <a
              href="/app-debug.apk"
              download="mindora-android.apk"
              className="mt-2 w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-xs font-semibold"
              style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
            >
              <Download className="w-3.5 h-3.5" />
              <span>{dict.nav.downloadApk}</span>
            </a>
          </div>
        )}
      </header>

      <main className="flex-1">
        <Outlet />
      </main>

      <footer
        className="border-t py-10 mt-16"
        style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6">
          <div>
            <div className="font-bold text-sm">{dict.brand}</div>
            <div className="text-xs mt-1" style={{ color: "var(--text-muted)" }}>
              {dict.footer.rights}
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-4 text-xs" style={{ color: "var(--text-secondary)" }}>
            <Link to="/features">{dict.nav.features}</Link>
            <Link to="/pricing">{dict.nav.pricing}</Link>
            <Link to="/help">{dict.nav.help}</Link>
            <Link to="/privacy">{dict.nav.privacy}</Link>
            <Link to="/terms">{dict.nav.terms}</Link>
            <Link to="/contact">{dict.nav.contact}</Link>
            <a
              href="/admin/"
              className="opacity-70 hover:opacity-100 transition-opacity"
              style={{ color: "var(--text-muted)" }}
            >
              {dict.nav.admin}
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}
