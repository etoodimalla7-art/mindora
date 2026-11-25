import React, { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  ArrowRight,
  BookOpen,
  Bot,
  Calendar,
  Download,
  FileCheck2,
  Layers,
  Smartphone,
  Users,
} from "lucide-react";
import { useI18n } from "../i18n";
import { fetchPublicSettings, PublicSettings } from "../lib/api";

const featureIcons = [Bot, BookOpen, FileCheck2, Layers, Calendar, Users];

export function HomePage() {
  const { dict } = useI18n();
  const [settings, setSettings] = useState<PublicSettings | null>(null);

  useEffect(() => {
    fetchPublicSettings().then(setSettings);
  }, []);

  return (
    <div>
      {/* Hero */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 pt-14 pb-16 lg:pt-24 lg:pb-20">
        <div className="max-w-3xl space-y-6">
          <div
            className="inline-block px-3 py-1 rounded-lg text-xs font-semibold border"
            style={{
              backgroundColor: "var(--brand-soft)",
              borderColor: "var(--border-subtle)",
              color: "var(--brand)",
            }}
          >
            {dict.hero.badge}
          </div>

          <h1 className="text-3xl sm:text-5xl font-extrabold tracking-tight leading-tight">
            {dict.hero.title}
          </h1>

          <p className="text-base sm:text-lg leading-relaxed" style={{ color: "var(--text-secondary)" }}>
            {dict.hero.subtitle}
          </p>

          <div className="flex flex-wrap items-center gap-3 pt-2">
            <a
              href="/app-debug.apk"
              download="mindora-android.apk"
              className="inline-flex items-center gap-2 px-6 py-3.5 rounded-xl text-sm font-semibold shadow-lg transition-transform hover:scale-[1.01]"
              style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
            >
              <Download className="w-4 h-4" />
              <span>{dict.hero.downloadCta}</span>
            </a>

            <span
              className="inline-flex items-center gap-2 px-5 py-3.5 rounded-xl text-sm font-semibold border"
              style={{
                backgroundColor: "var(--bg-surface)",
                borderColor: "var(--border-subtle)",
                color: "var(--text-secondary)",
              }}
            >
              <Smartphone className="w-4 h-4" />
              <span>{dict.hero.playStoreCta}</span>
            </span>

            <Link
              to="/features"
              className="inline-flex items-center gap-1.5 px-4 py-3 text-sm font-semibold"
              style={{ color: "var(--brand)" }}
            >
              <span>{dict.hero.exploreCta}</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>

          <p className="text-xs" style={{ color: "var(--text-muted)" }}>
            {dict.hero.playStoreNote}
          </p>

          {settings?.maintenance?.enabled && (
            <div
              className="p-3 rounded-xl border text-xs"
              style={{
                backgroundColor: "var(--accent-soft)",
                borderColor: "var(--accent)",
                color: "var(--accent)",
              }}
            >
              {settings.maintenance.message}
            </div>
          )}
        </div>

        {/* Metrics grid */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mt-14">
          {dict.stats.map((s) => (
            <div
              key={s.label}
              className="p-5 rounded-2xl border"
              style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
            >
              <div className="text-2xl sm:text-3xl font-extrabold" style={{ color: "var(--brand)" }}>
                {s.value}
              </div>
              <div className="text-xs sm:text-sm mt-1" style={{ color: "var(--text-secondary)" }}>
                {s.label}
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Features showcase */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
        <div className="max-w-2xl mb-10">
          <h2 className="text-2xl sm:text-3xl font-bold">{dict.features.title}</h2>
          <p className="text-sm sm:text-base mt-2" style={{ color: "var(--text-secondary)" }}>
            {dict.features.subtitle}
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {dict.features.items.map((item, idx) => {
            const Icon = featureIcons[idx % featureIcons.length];
            return (
              <div
                key={item.title}
                className="p-6 rounded-2xl border space-y-3"
                style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
              >
                <div
                  className="w-10 h-10 rounded-xl flex items-center justify-center"
                  style={{ backgroundColor: "var(--brand-soft)", color: "var(--brand)" }}
                >
                  <Icon className="w-5 h-5" />
                </div>
                <h3 className="font-bold text-base">{item.title}</h3>
                <p className="text-sm leading-relaxed" style={{ color: "var(--text-secondary)" }}>
                  {item.desc}
                </p>
              </div>
            );
          })}
        </div>
      </section>
    </div>
  );
}
