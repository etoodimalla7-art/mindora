import React, { useState } from "react";
import { HelpCircle, Search } from "lucide-react";
import { useI18n } from "../i18n";

export function HelpPage() {
  const { dict } = useI18n();
  const [query, setQuery] = useState("");

  const filtered = dict.help.faqs.filter(
    (f) =>
      f.q.toLowerCase().includes(query.toLowerCase()) ||
      f.a.toLowerCase().includes(query.toLowerCase())
  );

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 py-14 space-y-8">
      <div className="space-y-3">
        <h1 className="text-3xl sm:text-4xl font-extrabold">{dict.help.title}</h1>
        <p className="text-base" style={{ color: "var(--text-secondary)" }}>
          {dict.help.subtitle}
        </p>
      </div>

      <div className="relative">
        <Search className="w-4 h-4 absolute left-3.5 top-3.5" style={{ color: "var(--text-muted)" }} />
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="..."
          className="w-full pl-10 pr-4 py-3 rounded-xl border text-sm outline-none"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        />
      </div>

      <div className="space-y-4">
        {filtered.map((item) => (
          <div
            key={item.q}
            className="p-5 rounded-2xl border space-y-2"
            style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
          >
            <div className="flex items-start gap-2.5 font-bold text-base">
              <HelpCircle className="w-5 h-5 shrink-0 mt-0.5" style={{ color: "var(--brand)" }} />
              <span>{item.q}</span>
            </div>
            <p className="text-sm leading-relaxed pl-7" style={{ color: "var(--text-secondary)" }}>
              {item.a}
            </p>
          </div>
        ))}
      </div>
    </div>
  );
}
