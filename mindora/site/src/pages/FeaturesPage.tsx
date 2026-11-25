import React from "react";
import { Bot, BookOpen, Calendar, Download, FileCheck2, Layers, Users } from "lucide-react";
import { useI18n } from "../i18n";

const icons = [Bot, BookOpen, FileCheck2, Layers, Calendar, Users];

export function FeaturesPage() {
  const { dict } = useI18n();
  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 py-14 space-y-12">
      <div className="max-w-3xl space-y-4">
        <h1 className="text-3xl sm:text-4xl font-extrabold">{dict.features.title}</h1>
        <p className="text-base" style={{ color: "var(--text-secondary)" }}>
          {dict.features.subtitle}
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {dict.features.items.map((item, idx) => {
          const Icon = icons[idx % icons.length];
          return (
            <div
              key={item.title}
              className="p-6 rounded-2xl border flex gap-4"
              style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
            >
              <div
                className="w-11 h-11 rounded-xl flex items-center justify-center shrink-0"
                style={{ backgroundColor: "var(--brand-soft)", color: "var(--brand)" }}
              >
                <Icon className="w-5 h-5" />
              </div>
              <div>
                <h2 className="font-bold text-lg">{item.title}</h2>
                <p className="text-sm mt-1.5 leading-relaxed" style={{ color: "var(--text-secondary)" }}>
                  {item.desc}
                </p>
              </div>
            </div>
          );
        })}
      </div>

      <div
        className="p-8 rounded-2xl border flex flex-wrap items-center justify-between gap-6"
        style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
      >
        <div>
          <h3 className="text-xl font-bold">{dict.hero.downloadCta}</h3>
          <p className="text-sm mt-1" style={{ color: "var(--text-secondary)" }}>
            {dict.hero.playStoreNote}
          </p>
        </div>
        <a
          href="/app-debug.apk"
          download="mindora-android.apk"
          className="inline-flex items-center gap-2 px-6 py-3 rounded-xl text-sm font-semibold"
          style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
        >
          <Download className="w-4 h-4" />
          <span>{dict.nav.downloadApk}</span>
        </a>
      </div>
    </div>
  );
}
