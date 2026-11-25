import React from "react";
import { useI18n } from "../i18n";

export function PrivacyPage() {
  const { dict } = useI18n();
  return (
    <div className="max-w-3xl mx-auto px-4 sm:px-6 py-14 space-y-8">
      <div>
        <h1 className="text-3xl font-extrabold">{dict.privacy.title}</h1>
        <p className="text-xs mt-2" style={{ color: "var(--text-muted)" }}>
          {dict.privacy.updated}
        </p>
      </div>
      <div className="space-y-6">
        {dict.privacy.sections.map((s) => (
          <section
            key={s.heading}
            className="p-5 rounded-2xl border space-y-2"
            style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
          >
            <h2 className="font-bold text-base">{s.heading}</h2>
            <p className="text-sm leading-relaxed" style={{ color: "var(--text-secondary)" }}>
              {s.body}
            </p>
          </section>
        ))}
      </div>
    </div>
  );
}

export function TermsPage() {
  const { dict } = useI18n();
  return (
    <div className="max-w-3xl mx-auto px-4 sm:px-6 py-14 space-y-8">
      <div>
        <h1 className="text-3xl font-extrabold">{dict.terms.title}</h1>
        <p className="text-xs mt-2" style={{ color: "var(--text-muted)" }}>
          {dict.terms.updated}
        </p>
      </div>
      <div className="space-y-6">
        {dict.terms.sections.map((s) => (
          <section
            key={s.heading}
            className="p-5 rounded-2xl border space-y-2"
            style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
          >
            <h2 className="font-bold text-base">{s.heading}</h2>
            <p className="text-sm leading-relaxed" style={{ color: "var(--text-secondary)" }}>
              {s.body}
            </p>
          </section>
        ))}
      </div>
    </div>
  );
}
