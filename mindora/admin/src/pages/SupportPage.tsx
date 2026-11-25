import React, { useEffect, useState } from "react";
import { LifeBuoy, MessageSquare, Send, UserCheck } from "lucide-react";
import { apiRequest } from "../lib/api";
import { useAuth } from "../lib/auth";
import { useI18n } from "../i18n";

interface TicketRow {
  id: string;
  subject: string;
  description: string;
  status: string;
  priority: string;
  assigned_to: string | null;
  user_email: string | null;
  assigned_to_email: string | null;
  created_at: string;
}

interface SupportMessage {
  id: string;
  author_email: string | null;
  body: string;
  is_admin: boolean;
  created_at: string;
}

interface TicketDetail extends TicketRow {
  messages: SupportMessage[];
}

interface SupportStats {
  total: number;
  open: number;
  in_progress: number;
  resolved: number;
  closed: number;
}

export function SupportPage() {
  const { dict } = useI18n();
  const { session } = useAuth();
  const [tickets, setTickets] = useState<TicketRow[]>([]);
  const [stats, setStats] = useState<SupportStats | null>(null);
  const [statusFilter, setStatusFilter] = useState("");
  const [active, setActive] = useState<TicketDetail | null>(null);
  const [reply, setReply] = useState("");
  const [error, setError] = useState<string | null>(null);

  const loadList = async () => {
    setError(null);
    try {
      const qs = statusFilter ? `?status=${encodeURIComponent(statusFilter)}` : "";
      const [listOut, st] = await Promise.all([
        apiRequest<{ items: TicketRow[] }>(`/admin/support/tickets${qs}`),
        apiRequest<SupportStats>("/admin/support/stats").catch(() => null),
      ]);
      setTickets(listOut.items);
      setStats(st);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  useEffect(() => {
    loadList();
  }, [statusFilter]);

  const openTicket = async (id: string) => {
    try {
      const detail = await apiRequest<TicketDetail>(`/admin/support/tickets/${id}`);
      setActive(detail);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const sendReply = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!active || !reply.trim()) return;
    try {
      await apiRequest(`/admin/support/tickets/${active.id}/messages`, {
        method: "POST",
        body: JSON.stringify({ body: reply.trim() }),
      });
      setReply("");
      await openTicket(active.id);
      await loadList();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const updateStatus = async (status: string) => {
    if (!active) return;
    try {
      await apiRequest(`/admin/support/tickets/${active.id}/status`, {
        method: "PATCH",
        body: JSON.stringify({ status }),
      });
      await openTicket(active.id);
      await loadList();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const assignToMe = async () => {
    if (!active || !session?.user.id) return;
    try {
      await apiRequest(`/admin/support/tickets/${active.id}/assign`, {
        method: "PATCH",
        body: JSON.stringify({ assigned_to: session.user.id }),
      });
      await openTicket(active.id);
      await loadList();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">{dict.support.title}</h1>
        <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
          {dict.support.subtitle}
        </p>
      </div>

      {stats && (
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {[
            { label: dict.support.open, val: stats.open, color: "var(--warning)" },
            { label: dict.support.inProgress, val: stats.in_progress, color: "var(--info)" },
            { label: dict.support.resolved, val: stats.resolved, color: "var(--success)" },
            { label: dict.support.closed, val: stats.closed, color: "var(--text-muted)" },
          ].map((s) => (
            <div
              key={s.label}
              className="p-4 rounded-2xl border"
              style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
            >
              <div className="text-xs" style={{ color: "var(--text-secondary)" }}>{s.label}</div>
              <div className="text-xl font-bold mt-1" style={{ color: s.color }}>{s.val}</div>
            </div>
          ))}
        </div>
      )}

      {error && (
        <div
          className="p-3 rounded-xl border text-sm"
          style={{ backgroundColor: "var(--danger-soft)", borderColor: "var(--danger)", color: "var(--danger)" }}
        >
          {error}
        </div>
      )}

      <div className="flex items-center gap-2">
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="px-3 py-2 rounded-xl border text-sm"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          <option value="">{dict.common.all}</option>
          <option value="open">{dict.support.open}</option>
          <option value="in_progress">{dict.support.inProgress}</option>
          <option value="resolved">{dict.support.resolved}</option>
          <option value="closed">{dict.support.closed}</option>
        </select>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div
          className="lg:col-span-5 rounded-2xl border divide-y max-h-[600px] overflow-y-auto"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          {tickets.length === 0 ? (
            <div className="p-6 text-center text-sm" style={{ color: "var(--text-muted)" }}>
              {dict.common.noData}
            </div>
          ) : (
            tickets.map((t) => (
              <button
                key={t.id}
                type="button"
                onClick={() => openTicket(t.id)}
                className="w-full text-left p-4 cursor-pointer transition-colors"
                style={{
                  backgroundColor: active?.id === t.id ? "var(--brand-soft)" : "transparent",
                  borderColor: "var(--border-subtle)",
                }}
              >
                <div className="flex items-center justify-between gap-2">
                  <span className="font-semibold text-sm truncate">{t.subject}</span>
                  <span className="text-xs uppercase font-semibold" style={{ color: "var(--brand)" }}>
                    {t.status}
                  </span>
                </div>
                <div className="text-xs mt-1 truncate" style={{ color: "var(--text-secondary)" }}>
                  {t.user_email || "contact@mindora.dev"} · {t.priority}
                </div>
              </button>
            ))
          )}
        </div>

        <div
          className="lg:col-span-7 p-5 rounded-2xl border flex flex-col min-h-[420px]"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          {!active ? (
            <div className="m-auto text-center space-y-2" style={{ color: "var(--text-muted)" }}>
              <LifeBuoy className="w-8 h-8 mx-auto" />
              <div className="text-sm">{dict.common.noData}</div>
            </div>
          ) : (
            <>
              <div className="flex flex-wrap items-center justify-between gap-3 pb-4 border-b" style={{ borderColor: "var(--border-subtle)" }}>
                <div>
                  <h2 className="font-bold">{active.subject}</h2>
                  <div className="text-xs" style={{ color: "var(--text-secondary)" }}>
                    {active.user_email || "Public contact"} · {new Date(active.created_at).toLocaleString()}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={assignToMe}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold border cursor-pointer"
                    style={{ borderColor: "var(--border-subtle)" }}
                  >
                    <UserCheck className="w-3.5 h-3.5" />
                    <span>{dict.support.assignToMe}</span>
                  </button>
                  <select
                    value={active.status}
                    onChange={(e) => updateStatus(e.target.value)}
                    className="px-3 py-1.5 rounded-xl border text-xs font-semibold"
                    style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
                  >
                    <option value="open">{dict.support.open}</option>
                    <option value="in_progress">{dict.support.inProgress}</option>
                    <option value="resolved">{dict.support.resolved}</option>
                    <option value="closed">{dict.support.closed}</option>
                  </select>
                </div>
              </div>

              <div className="flex-1 py-4 space-y-3 overflow-y-auto max-h-96">
                <div
                  className="p-3 rounded-xl border text-sm"
                  style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
                >
                  {active.description}
                </div>

                {active.messages.map((m) => (
                  <div
                    key={m.id}
                    className="p-3 rounded-xl border text-sm"
                    style={{
                      backgroundColor: m.is_admin ? "var(--brand-soft)" : "var(--bg-elevated)",
                      borderColor: "var(--border-subtle)",
                    }}
                  >
                    <div className="flex items-center justify-between text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
                      <span className="inline-flex items-center gap-1 font-semibold">
                        <MessageSquare className="w-3 h-3" />
                        {m.author_email || (m.is_admin ? "Admin" : "Student")}
                      </span>
                      <span>{new Date(m.created_at).toLocaleString()}</span>
                    </div>
                    <div>{m.body}</div>
                  </div>
                ))}
              </div>

              <form onSubmit={sendReply} className="pt-3 border-t flex gap-2" style={{ borderColor: "var(--border-subtle)" }}>
                <input
                  value={reply}
                  onChange={(e) => setReply(e.target.value)}
                  placeholder={dict.support.replyPlaceholder}
                  className="flex-1 px-3 py-2 rounded-xl border text-sm"
                  style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
                />
                <button
                  type="submit"
                  className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-semibold cursor-pointer"
                  style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
                >
                  <Send className="w-3.5 h-3.5" />
                  <span>{dict.support.sendReply}</span>
                </button>
              </form>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
