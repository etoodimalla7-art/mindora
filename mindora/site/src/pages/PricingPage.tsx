import React, { useEffect, useState } from "react";
import { Check, Download } from "lucide-react";
import { useI18n } from "../i18n";
import { fetchPublicPlans, PublicPlan } from "../lib/api";

export function PricingPage() {
  const { dict } = useI18n();
  const [livePlans, setLivePlans] = useState<PublicPlan[]>([]);

  useEffect(() => {
    fetchPublicPlans().then(setLivePlans);
  }, []);

  const paidPlans =
    livePlans.length > 0
      ? livePlans.map((p) => ({
          code: p.code,
          name: p.name,
          priceLabel: `${p.amount_minor.toLocaleString()} ${p.currency}`,
          cycleLabel: p.billing_cycle,
          features: Array.isArray(p.features)
            ? p.features
            : Object.entries(p.features || {}).map(([k, v]) => `${k}: ${String(v)}`),
        }))
      : dict.pricing.fallbackPlans.map((p) => ({
          code: p.code,
          name: p.name,
          priceLabel: `${p.price_xaf.toLocaleString()} XAF`,
          cycleLabel: `${p.duration_days}d`,
          features: p.features,
        }));

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 py-14 space-y-12">
      <div className="max-w-2xl space-y-3">
        <h1 className="text-3xl sm:text-4xl font-extrabold">{dict.pricing.title}</h1>
        <p className="text-base" style={{ color: "var(--text-secondary)" }}>
          {dict.pricing.subtitle}
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Free Tier */}
        <div
          className="p-6 rounded-2xl border flex flex-col justify-between space-y-6"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          <div className="space-y-4">
            <h2 className="font-bold text-lg">{dict.pricing.freeTitle}</h2>
            <div className="flex items-baseline gap-1">
              <span className="text-3xl font-extrabold">{dict.pricing.freePrice}</span>
              <span className="text-sm" style={{ color: "var(--text-secondary)" }}>
                {dict.pricing.freePeriod}
              </span>
            </div>
            <ul className="space-y-2.5 text-sm">
              {dict.pricing.freeFeatures.map((f) => (
                <li key={f} className="flex items-start gap-2">
                  <Check className="w-4 h-4 shrink-0 mt-0.5" style={{ color: "var(--success)" }} />
                  <span style={{ color: "var(--text-secondary)" }}>{f}</span>
                </li>
              ))}
            </ul>
          </div>
          <a
            href="/app-debug.apk"
            download="mindora-android.apk"
            className="w-full inline-flex items-center justify-center gap-2 px-4 py-3 rounded-xl text-xs font-semibold border"
            style={{ borderColor: "var(--border-strong)" }}
          >
            <Download className="w-3.5 h-3.5" />
            <span>{dict.nav.downloadApk}</span>
          </a>
        </div>

        {/* Paid Tiers */}
        {paidPlans.map((plan, idx) => (
          <div
            key={plan.code}
            className="p-6 rounded-2xl border flex flex-col justify-between space-y-6"
            style={{
              backgroundColor: "var(--bg-surface)",
              borderColor: idx === 0 ? "var(--brand)" : "var(--border-subtle)",
            }}
          >
            <div className="space-y-4">
              <div className="flex items-center justify-between gap-2">
                <h2 className="font-bold text-lg">{plan.name}</h2>
                {idx === 0 && (
                  <span
                    className="px-2.5 py-0.5 rounded-lg text-[11px] font-semibold"
                    style={{ backgroundColor: "var(--brand-soft)", color: "var(--brand)" }}
                  >
                    {dict.pricing.popularBadge}
                  </span>
                )}
              </div>
              <div className="flex items-baseline gap-1">
                <span className="text-3xl font-extrabold">{plan.priceLabel}</span>
                <span className="text-sm" style={{ color: "var(--text-secondary)" }}>
                  / {plan.cycleLabel}
                </span>
              </div>
              <ul className="space-y-2.5 text-sm">
                {plan.features.map((f) => (
                  <li key={String(f)} className="flex items-start gap-2">
                    <Check className="w-4 h-4 shrink-0 mt-0.5" style={{ color: "var(--brand)" }} />
                    <span style={{ color: "var(--text-secondary)" }}>{String(f)}</span>
                  </li>
                ))}
              </ul>
            </div>
            <a
              href="/app-debug.apk"
              download="mindora-android.apk"
              className="w-full inline-flex items-center justify-center gap-2 px-4 py-3 rounded-xl text-xs font-semibold"
              style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
            >
              <Download className="w-3.5 h-3.5" />
              <span>{dict.pricing.proCta}</span>
            </a>
          </div>
        ))}
      </div>
    </div>
  );
}
