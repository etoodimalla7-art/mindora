import React, { useEffect, useState } from "react";
import { Check, Plus, ShieldAlert } from "lucide-react";
import { apiRequest } from "../lib/api";
import { useI18n } from "../i18n";

interface LoginRow {
  id: string;
  email: string;
  ip: string | null;
  success: boolean;
  failure_reason: string | null;
  created_at: string;
}

interface SecurityAlert {
  id: string;
  type: string;
  severity: string;
  message: string;
  acknowledged: boolean;
  created_at: string;
}

interface AuditLog {
  id: string;
  admin_email: string | null;
  action: string;
  resource_type: string | null;
  result: string;
  created_at: string;
}

interface SystemMetrics {
  total_users: number;
  active_sessions_24h: number;
  requests_per_minute: number;
  failed_logins_24h: number;
  unacknowledged_alerts: number;
}

export function SecurityPage() {
  const { dict } = useI18n();
  const [metrics, setMetrics] = useState<SystemMetrics | null>(null);
  const [logins, setLogins] = useState<LoginRow[]>([]);
  const [alerts, setAlerts] = useState<SecurityAlert[]>([]);
  const [audits, setAudits] = useState<AuditLog[]>([]);
  const [severity, setSeverity] = useState("medium");
  const [message, setMessage] = useState("");
  const [error, setError] = useState<string | null>(null);

  const load = async () => {
    setError(null);
    try {
      const [m, l, a, au] = await Promise.all([
        apiRequest<SystemMetrics>("/admin/system/metrics").catch(() => null),
        apiRequest<{ items: LoginRow[] }>("/admin/security/login-history?limit=30"),
        apiRequest<{ items: SecurityAlert[] }>("/admin/security/alerts?limit=30"),
        apiRequest<AuditLog[]>("/admin/audit-logs?limit=30").catch(() => []),
      ]);
      setMetrics(m);
      setLogins(l.items);
      setAlerts(a.items);
      setAudits(au);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  useEffect(() => {
    load();
  }, []);

  const acknowledge = async (id: string) => {
    try {
      await apiRequest(`/admin/security/alerts/${id}/acknowledge`, { method: "PATCH" });
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const createAlert = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!message.trim()) return;
    try {
      await apiRequest("/admin/security/alerts", {
        method: "POST",
        body: JSON.stringify({ type: "manual", severity, message: message.trim() }),
      });
      setMessage("");
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">{dict.security.title}</h1>
        <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
          {dict.security.subtitle}
        </p>
      </div>

      {metrics && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="p-4 rounded-2xl border" style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}>
            <div className="text-xs" style={{ color: "var(--text-secondary)" }}>Active 24h</div>
            <div className="text-2xl font-bold mt-1">{metrics.active_sessions_24h}</div>
          </div>
          <div className="p-4 rounded-2xl border" style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}>
            <div className="text-xs" style={{ color: "var(--text-secondary)" }}>Req / min</div>
            <div className="text-2xl font-bold mt-1">{metrics.requests_per_minute}</div>
          </div>
          <div className="p-4 rounded-2xl border" style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}>
            <div className="text-xs" style={{ color: "var(--text-secondary)" }}>Failed Logins 24h</div>
            <div className="text-2xl font-bold mt-1" style={{ color: "var(--warning)" }}>{metrics.failed_logins_24h}</div>
          </div>
          <div className="p-4 rounded-2xl border" style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}>
            <div className="text-xs" style={{ color: "var(--text-secondary)" }}>{dict.security.alerts}</div>
            <div className="text-2xl font-bold mt-1" style={{ color: "var(--danger)" }}>{metrics.unacknowledged_alerts}</div>
          </div>
        </div>
      )}

      {error && (
        <div className="p-3 rounded-xl border text-sm" style={{ backgroundColor: "var(--danger-soft)", borderColor: "var(--danger)", color: "var(--danger)" }}>
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="p-5 rounded-2xl border space-y-4" style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}>
          <div className="flex items-center gap-2 font-semibold">
            <ShieldAlert className="w-4 h-4" style={{ color: "var(--warning)" }} />
            <span>{dict.security.alerts}</span>
          </div>

          <form onSubmit={createAlert} className="flex flex-wrap gap-2">
            <select
              value={severity}
              onChange={(e) => setSeverity(e.target.value)}
              className="px-3 py-2 rounded-xl border text-xs"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            >
              <option value="low">low</option>
              <option value="medium">medium</option>
              <option value="high">high</option>
              <option value="critical">critical</option>
            </select>
            <input
              required
              minLength={3}
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder={dict.security.createAlert}
              className="flex-1 px-3 py-2 rounded-xl border text-xs"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
            <button
              type="submit"
              className="inline-flex items-center gap-1 px-3 py-2 rounded-xl text-xs font-semibold cursor-pointer"
              style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
            >
              <Plus className="w-3.5 h-3.5" />
              <span>{dict.common.create}</span>
            </button>
          </form>

          <div className="space-y-2 max-h-72 overflow-y-auto">
            {alerts.map((a) => (
              <div
                key={a.id}
                className="p-3 rounded-xl border flex items-center justify-between gap-2 text-xs"
                style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
              >
                <div>
                  <span className="font-semibold uppercase mr-2" style={{ color: "var(--warning)" }}>
                    [{a.severity}]
                  </span>
                  <span>{a.message}</span>
                </div>
                {!a.acknowledged && (
                  <button
                    type="button"
                    onClick={() => acknowledge(a.id)}
                    className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg font-semibold cursor-pointer"
                    style={{ backgroundColor: "var(--success-soft)", color: "var(--success)" }}
                  >
                    <Check className="w-3 h-3" />
                    <span>{dict.security.acknowledge}</span>
                  </button>
                )}
              </div>
            ))}
          </div>
        </div>

        <div className="p-5 rounded-2xl border space-y-3" style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}>
          <h2 className="font-semibold">{dict.security.loginHistory}</h2>
          <div className="space-y-2 max-h-80 overflow-y-auto">
            {logins.map((l) => (
              <div
                key={l.id}
                className="p-2.5 rounded-xl border flex items-center justify-between text-xs"
                style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
              >
                <div>
                  <div className="font-medium">{l.email}</div>
                  <div style={{ color: "var(--text-muted)" }}>{l.ip || "—"} · {l.failure_reason || "ok"}</div>
                </div>
                <span
                  className="px-2 py-0.5 rounded-md font-semibold uppercase"
                  style={{
                    backgroundColor: l.success ? "var(--success-soft)" : "var(--danger-soft)",
                    color: l.success ? "var(--success)" : "var(--danger)",
                  }}
                >
                  {l.success ? "OK" : "FAIL"}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="p-5 rounded-2xl border space-y-3" style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}>
        <h2 className="font-semibold">{dict.security.auditLogs}</h2>
        <div className="space-y-2 max-h-64 overflow-y-auto">
          {audits.map((au) => (
            <div
              key={au.id}
              className="p-2.5 rounded-xl border flex flex-wrap items-center justify-between gap-2 text-xs"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            >
              <div>
                <span className="font-mono-code font-semibold" style={{ color: "var(--brand)" }}>{au.action}</span>
                <span className="ml-2" style={{ color: "var(--text-secondary)" }}>
                  {au.admin_email || "system"} · {au.resource_type || "—"}
                </span>
              </div>
              <span style={{ color: "var(--text-muted)" }}>{new Date(au.created_at).toLocaleString()}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
