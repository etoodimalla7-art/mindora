import React, { useEffect, useState } from "react";
import { Download } from "lucide-react";
import { apiDownloadBlob, apiRequest } from "../lib/api";
import { useI18n } from "../i18n";

interface SeriesPoint {
  date?: string;
  day?: string;
  count: number;
}

interface BreakdownItem {
  subject?: string;
  exam_system?: string;
  label?: string;
  count: number;
}

export function AnalyticsPage() {
  const { dict } = useI18n();
  const [usersSeries, setUsersSeries] = useState<SeriesPoint[]>([]);
  const [docsSeries, setDocsSeries] = useState<SeriesPoint[]>([]);
  const [subjects, setSubjects] = useState<BreakdownItem[]>([]);
  const [systems, setSystems] = useState<BreakdownItem[]>([]);
  const [funnel, setFunnel] = useState<Record<string, unknown> | null>(null);
  const [cohorts, setCohorts] = useState<Array<Record<string, unknown>>>([]);

  useEffect(() => {
    Promise.all([
      apiRequest<SeriesPoint[]>("/admin/analytics/users-timeseries?days=14").catch(() => []),
      apiRequest<SeriesPoint[]>("/admin/analytics/documents-timeseries?days=14").catch(() => []),
      apiRequest<BreakdownItem[]>("/admin/analytics/subjects-breakdown").catch(() => []),
      apiRequest<BreakdownItem[]>("/admin/analytics/exam-systems-breakdown").catch(() => []),
      apiRequest<Record<string, unknown>>("/admin/analytics/funnel?days=30").catch(() => null),
      apiRequest<{ cohorts: Array<Record<string, unknown>> }>("/admin/analytics/retention?weeks=6").catch(() => ({
        cohorts: [],
      })),
    ]).then(([u, d, s, sy, f, r]) => {
      setUsersSeries(u);
      setDocsSeries(d);
      setSubjects(s);
      setSystems(sy);
      setFunnel(f);
      setCohorts(r?.cohorts || []);
    });
  }, []);

  const exportCsv = async () => {
    const blob = await apiDownloadBlob("/admin/analytics/export/users.csv");
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "mindora-users.csv";
    a.click();
    URL.revokeObjectURL(url);
  };

  const renderBars = (points: SeriesPoint[]) => {
    const maxVal = Math.max(1, ...points.map((p) => p.count || 0));
    return (
      <div className="flex items-end gap-1.5 h-32 pt-4">
        {points.map((p, idx) => (
          <div key={idx} className="flex-1 flex flex-col items-center gap-1">
            <div
              className="w-full rounded-t-md transition-all"
              style={{
                height: `${Math.max(8, Math.round(((p.count || 0) / maxVal) * 100))}%`,
                backgroundColor: "var(--brand)",
              }}
              title={`${p.date || p.day || ""}: ${p.count}`}
            />
            <span className="text-[10px] truncate w-full text-center" style={{ color: "var(--text-muted)" }}>
              {(p.date || p.day || "").slice(5)}
            </span>
          </div>
        ))}
      </div>
    );
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">{dict.analytics.title}</h1>
          <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
            {dict.analytics.subtitle}
          </p>
        </div>
        <button
          type="button"
          onClick={exportCsv}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold cursor-pointer"
          style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
        >
          <Download className="w-4 h-4" />
          <span>{dict.common.exportCsv}</span>
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div
          className="p-5 rounded-2xl border"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          <h2 className="font-semibold mb-2">{dict.analytics.usersSeries}</h2>
          {usersSeries.length ? renderBars(usersSeries) : <div className="text-sm py-8">{dict.common.noData}</div>}
        </div>
        <div
          className="p-5 rounded-2xl border"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          <h2 className="font-semibold mb-2">{dict.analytics.docsSeries}</h2>
          {docsSeries.length ? renderBars(docsSeries) : <div className="text-sm py-8">{dict.common.noData}</div>}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div
          className="p-5 rounded-2xl border"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          <h2 className="font-semibold mb-3">{dict.analytics.subjectsBreakdown}</h2>
          <div className="space-y-2">
            {subjects.map((s, idx) => (
              <div key={idx} className="flex items-center justify-between text-sm">
                <span>{s.subject || s.label || "Other"}</span>
                <span className="font-semibold font-mono-code">{s.count}</span>
              </div>
            ))}
          </div>
        </div>
        <div
          className="p-5 rounded-2xl border"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          <h2 className="font-semibold mb-3">{dict.analytics.systemsBreakdown}</h2>
          <div className="space-y-2">
            {systems.map((s, idx) => (
              <div key={idx} className="flex items-center justify-between text-sm">
                <span>{s.exam_system || s.label || "Other"}</span>
                <span className="font-semibold font-mono-code">{s.count}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {funnel && (
        <div
          className="p-5 rounded-2xl border"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          <h2 className="font-semibold mb-3">{dict.analytics.funnel}</h2>
          <pre className="text-xs font-mono-code overflow-x-auto" style={{ color: "var(--text-secondary)" }}>
            {JSON.stringify(funnel, null, 2)}
          </pre>
        </div>
      )}

      <div
        className="p-5 rounded-2xl border overflow-x-auto"
        style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
      >
        <h2 className="font-semibold mb-3">{dict.analytics.retention}</h2>
        <table className="w-full text-sm text-left">
          <thead>
            <tr style={{ color: "var(--text-secondary)" }}>
              <th className="py-2 pr-4">{dict.analytics.cohortWeek}</th>
              <th className="py-2 pr-4">{dict.analytics.cohortSize}</th>
            </tr>
          </thead>
          <tbody>
            {cohorts.map((c, idx) => (
              <tr key={idx} className="border-t" style={{ borderColor: "var(--border-subtle)" }}>
                <td className="py-2 pr-4 font-mono-code">{String(c.cohort || c.week || idx)}</td>
                <td className="py-2 pr-4">{String(c.size || c.signups || 0)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
