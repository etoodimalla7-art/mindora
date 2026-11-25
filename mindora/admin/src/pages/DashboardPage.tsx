import React, { useEffect, useState } from "react";
import { Activity, Database, FileText, Radio, RefreshCw, Server, Users } from "lucide-react";
import { apiRequest, getWsBaseUrl, loadSession } from "../lib/api";
import { useI18n } from "../i18n";

interface AdminStats {
  users: { total: number; active: number; admins: number; new_this_week: number };
  documents: { total: number; pending: number; approved: number };
  papers: { total: number; published: number; draft: number };
  activity: { sessions_today: number; uploads_today: number };
}

interface HealthOut {
  overall: string;
  services: Array<{ name: string; status: string; latency_ms?: number; detail?: string }>;
  version?: string;
}

interface LiveEvent {
  type: string;
  payload: unknown;
  at: string;
}

export function DashboardPage() {
  const { dict } = useI18n();
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [health, setHealth] = useState<HealthOut | null>(null);
  const [wsOk, setWsOk] = useState(false);
  const [events, setEvents] = useState<LiveEvent[]>([]);
  const [error, setError] = useState<string | null>(null);

  const loadData = async () => {
    setError(null);
    try {
      const [s, h] = await Promise.all([
        apiRequest<AdminStats>("/admin/stats"),
        apiRequest<HealthOut>("/admin/system/health").catch(() => null),
      ]);
      setStats(s);
      setHealth(h);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  useEffect(() => {
    loadData();
    const session = loadSession();
    if (!session?.accessToken) return;
    const ws = new WebSocket(
      `${getWsBaseUrl()}/admin/events?token=${encodeURIComponent(session.accessToken)}`
    );
    ws.onopen = () => setWsOk(true);
    ws.onclose = () => setWsOk(false);
    ws.onmessage = (msg) => {
      try {
        const parsed = JSON.parse(msg.data);
        if (parsed.type === "ping" || parsed.type === "pong") return;
        setEvents((prev) => [
          { type: parsed.type, payload: parsed.payload, at: new Date().toLocaleTimeString() },
          ...prev.slice(0, 19),
        ]);
      } catch {
        // ignore malformed frame
      }
    };
    return () => ws.close();
  }, []);

  const cards = stats
    ? [
        { label: dict.dashboard.totalUsers, value: stats.users.total, icon: Users, color: "var(--brand)" },
        { label: dict.dashboard.activeUsers, value: stats.users.active, icon: Activity, color: "var(--success)" },
        { label: dict.dashboard.pendingDocs, value: stats.documents.pending, icon: FileText, color: "var(--warning)" },
        { label: dict.dashboard.publishedPapers, value: stats.papers.published, icon: Database, color: "var(--info)" },
        { label: dict.dashboard.sessionsToday, value: stats.activity.sessions_today, icon: Server, color: "var(--accent)" },
      ]
    : [];

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">{dict.dashboard.title}</h1>
          <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
            {dict.dashboard.subtitle}
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div
            className="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-medium border"
            style={{
              backgroundColor: wsOk ? "var(--success-soft)" : "var(--bg-surface)",
              borderColor: "var(--border-subtle)",
              color: wsOk ? "var(--success)" : "var(--text-secondary)",
            }}
          >
            <Radio className="w-3.5 h-3.5" />
            <span>{wsOk ? dict.dashboard.wsConnected : dict.dashboard.wsDisconnected}</span>
          </div>
          <button
            type="button"
            onClick={loadData}
            className="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-semibold border cursor-pointer"
            style={{
              backgroundColor: "var(--bg-surface)",
              borderColor: "var(--border-subtle)",
            }}
          >
            <RefreshCw className="w-3.5 h-3.5" />
            <span>{dict.common.refresh}</span>
          </button>
        </div>
      </div>

      {error && (
        <div
          className="p-3 rounded-xl border text-sm"
          style={{ backgroundColor: "var(--danger-soft)", borderColor: "var(--danger)", color: "var(--danger)" }}
        >
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-4">
        {cards.map((c) => {
          const Icon = c.icon;
          return (
            <div
              key={c.label}
              className="p-5 rounded-2xl border"
              style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
            >
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-medium" style={{ color: "var(--text-secondary)" }}>
                  {c.label}
                </span>
                <Icon className="w-4 h-4" style={{ color: c.color }} />
              </div>
              <div className="text-2xl font-bold">{c.value}</div>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div
          className="p-5 rounded-2xl border"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          <h2 className="font-semibold mb-4">{dict.dashboard.systemHealth}</h2>
          <div className="space-y-3">
            {(health?.services || []).map((svc) => (
              <div
                key={svc.name}
                className="flex items-center justify-between p-3 rounded-xl border"
                style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
              >
                <div>
                  <div className="text-sm font-medium capitalize">{svc.name}</div>
                  {svc.detail && (
                    <div className="text-xs" style={{ color: "var(--text-muted)" }}>
                      {svc.detail}
                    </div>
                  )}
                </div>
                <span
                  className="px-2.5 py-1 rounded-lg text-xs font-semibold uppercase"
                  style={{
                    backgroundColor: svc.status === "ok" ? "var(--success-soft)" : "var(--warning-soft)",
                    color: svc.status === "ok" ? "var(--success)" : "var(--warning)",
                  }}
                >
                  {svc.status}
                  {svc.latency_ms ? ` · ${svc.latency_ms.toFixed(1)}ms` : ""}
                </span>
              </div>
            ))}
          </div>
        </div>

        <div
          className="p-5 rounded-2xl border"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          <h2 className="font-semibold mb-4">{dict.dashboard.liveEvents}</h2>
          {events.length === 0 ? (
            <div className="text-sm py-8 text-center" style={{ color: "var(--text-muted)" }}>
              {dict.common.noData}
            </div>
          ) : (
            <div className="space-y-2 max-h-72 overflow-y-auto">
              {events.map((ev, idx) => (
                <div
                  key={idx}
                  className="p-2.5 rounded-xl border text-xs flex items-start justify-between gap-2"
                  style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
                >
                  <div>
                    <span className="font-mono-code font-semibold" style={{ color: "var(--brand)" }}>
                      {ev.type}
                    </span>
                    <div className="mt-0.5 truncate max-w-xs" style={{ color: "var(--text-secondary)" }}>
                      {JSON.stringify(ev.payload)}
                    </div>
                  </div>
                  <span style={{ color: "var(--text-muted)" }}>{ev.at}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
