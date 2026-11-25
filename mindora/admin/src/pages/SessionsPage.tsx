import React, { useEffect, useState } from "react";
import { Trash2, RefreshCw } from "lucide-react";
import { apiRequest } from "../lib/api";
import { useI18n } from "../i18n";

interface SessionRow {
  id: string;
  user_id: string;
  user_email: string | null;
  is_admin: boolean;
  is_expired: boolean;
  expires_at: string;
  created_at: string;
}

export function SessionsPage() {
  const { dict } = useI18n();
  const [sessions, setSessions] = useState<SessionRow[]>([]);
  const [adminOnly, setAdminOnly] = useState(false);
  const [includeExpired, setIncludeExpired] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = async () => {
    setError(null);
    try {
      const qs = new URLSearchParams({
        admin_only: String(adminOnly),
        include_expired: String(includeExpired),
      });
      const out = await apiRequest<{ items: SessionRow[] }>(`/admin/sessions?${qs.toString()}`);
      setSessions(out.items);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  useEffect(() => {
    load();
  }, [adminOnly, includeExpired]);

  const revoke = async (id: string) => {
    try {
      await apiRequest(`/admin/sessions/${id}`, { method: "DELETE" });
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const cleanup = async () => {
    try {
      await apiRequest("/admin/sessions/cleanup", { method: "POST" });
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">{dict.sessions.title}</h1>
          <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
            {dict.sessions.subtitle}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={cleanup}
            className="px-3 py-2 rounded-xl text-xs font-semibold border cursor-pointer"
            style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
          >
            {dict.sessions.cleanupExpired}
          </button>
          <button
            type="button"
            onClick={load}
            className="inline-flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-semibold border cursor-pointer"
            style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
          >
            <RefreshCw className="w-3.5 h-3.5" />
            <span>{dict.common.refresh}</span>
          </button>
        </div>
      </div>

      {error && (
        <div className="p-3 rounded-xl border text-sm" style={{ backgroundColor: "var(--danger-soft)", borderColor: "var(--danger)", color: "var(--danger)" }}>
          {error}
        </div>
      )}

      <div className="flex items-center gap-4 text-xs">
        <label className="inline-flex items-center gap-2 cursor-pointer">
          <input type="checkbox" checked={adminOnly} onChange={(e) => setAdminOnly(e.target.checked)} />
          <span>{dict.sessions.adminOnly}</span>
        </label>
        <label className="inline-flex items-center gap-2 cursor-pointer">
          <input type="checkbox" checked={includeExpired} onChange={(e) => setIncludeExpired(e.target.checked)} />
          <span>{dict.sessions.includeExpired}</span>
        </label>
      </div>

      <div className="rounded-2xl border overflow-x-auto" style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}>
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b text-left text-xs" style={{ borderColor: "var(--border-subtle)", color: "var(--text-secondary)" }}>
              <th className="p-3">Email</th>
              <th className="p-3">Admin</th>
              <th className="p-3">Expires</th>
              <th className="p-3">{dict.common.status}</th>
              <th className="p-3 text-right">{dict.common.actions}</th>
            </tr>
          </thead>
          <tbody>
            {sessions.length === 0 ? (
              <tr>
                <td colSpan={5} className="p-6 text-center text-sm" style={{ color: "var(--text-muted)" }}>
                  {dict.common.noData}
                </td>
              </tr>
            ) : (
              sessions.map((s) => (
                <tr key={s.id} className="border-b last:border-b-0" style={{ borderColor: "var(--border-subtle)" }}>
                  <td className="p-3 font-medium">{s.user_email || s.user_id}</td>
                  <td className="p-3 text-xs">{s.is_admin ? "Admin" : "Student"}</td>
                  <td className="p-3 text-xs">{new Date(s.expires_at).toLocaleString()}</td>
                  <td className="p-3">
                    <span
                      className="px-2 py-0.5 rounded-lg text-xs font-semibold"
                      style={{
                        backgroundColor: s.is_expired ? "var(--danger-soft)" : "var(--success-soft)",
                        color: s.is_expired ? "var(--danger)" : "var(--success)",
                      }}
                    >
                      {s.is_expired ? dict.common.inactive : dict.common.active}
                    </span>
                  </td>
                  <td className="p-3 text-right">
                    <button
                      type="button"
                      onClick={() => revoke(s.id)}
                      className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-semibold cursor-pointer"
                      style={{ backgroundColor: "var(--danger-soft)", color: "var(--danger)" }}
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                      <span>{dict.sessions.revoke}</span>
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
