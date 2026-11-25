import React, { useEffect, useState } from "react";
import { Megaphone, Send } from "lucide-react";
import { apiRequest } from "../lib/api";
import { useI18n } from "../i18n";

interface BroadcastRow {
  id: string;
  title: string;
  body: string;
  target_criteria: Record<string, string>;
  sent_at: string | null;
  sent_count: number;
  created_at: string;
}

export function BroadcastsPage() {
  const { dict } = useI18n();
  const [items, setItems] = useState<BroadcastRow[]>([]);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [role, setRole] = useState("");
  const [system, setSystem] = useState("");
  const [level, setLevel] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [sending, setSending] = useState(false);

  const load = async () => {
    try {
      const rows = await apiRequest<BroadcastRow[]>("/admin/broadcasts");
      setItems(rows);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  useEffect(() => {
    load();
  }, []);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSending(true);
    setError(null);
    try {
      const target_criteria: Record<string, string> = {};
      if (role) target_criteria.role = role;
      if (system) target_criteria.exam_system = system;
      if (level) target_criteria.exam_level = level;

      await apiRequest<BroadcastRow>("/admin/broadcasts", {
        method: "POST",
        body: JSON.stringify({ title, body, target_criteria }),
      });
      setTitle("");
      setBody("");
      setRole("");
      setSystem("");
      setLevel("");
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">{dict.broadcasts.title}</h1>
        <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
          {dict.broadcasts.subtitle}
        </p>
      </div>

      {error && (
        <div
          className="p-3 rounded-xl border text-sm"
          style={{ backgroundColor: "var(--danger-soft)", borderColor: "var(--danger)", color: "var(--danger)" }}
        >
          {error}
        </div>
      )}

      <form
        onSubmit={submit}
        className="p-5 rounded-2xl border space-y-4"
        style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
      >
        <div className="flex items-center gap-2 font-semibold text-sm">
          <Megaphone className="w-4 h-4" style={{ color: "var(--brand)" }} />
          <span>{dict.broadcasts.newBroadcast}</span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          <input
            required
            minLength={3}
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder={dict.broadcasts.broadcastTitle}
            className="md:col-span-3 px-3 py-2 rounded-xl border text-sm"
            style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
          />
          <textarea
            required
            minLength={3}
            rows={3}
            value={body}
            onChange={(e) => setBody(e.target.value)}
            placeholder={dict.broadcasts.broadcastBody}
            className="md:col-span-3 px-3 py-2 rounded-xl border text-sm"
            style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
          />
          <input
            value={role}
            onChange={(e) => setRole(e.target.value)}
            placeholder={dict.broadcasts.targetRole}
            className="px-3 py-2 rounded-xl border text-sm"
            style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
          />
          <input
            value={system}
            onChange={(e) => setSystem(e.target.value)}
            placeholder={dict.broadcasts.targetSystem}
            className="px-3 py-2 rounded-xl border text-sm"
            style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
          />
          <input
            value={level}
            onChange={(e) => setLevel(e.target.value)}
            placeholder={dict.broadcasts.targetLevel}
            className="px-3 py-2 rounded-xl border text-sm"
            style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
          />
        </div>

        <div className="flex justify-end">
          <button
            type="submit"
            disabled={sending}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold cursor-pointer"
            style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
          >
            <Send className="w-3.5 h-3.5" />
            <span>{sending ? dict.common.loading : dict.broadcasts.sendNow}</span>
          </button>
        </div>
      </form>

      <div className="space-y-3">
        {items.map((b) => (
          <div
            key={b.id}
            className="p-4 rounded-2xl border flex flex-wrap items-center justify-between gap-4"
            style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
          >
            <div>
              <div className="font-semibold text-sm">{b.title}</div>
              <div className="text-xs mt-1" style={{ color: "var(--text-secondary)" }}>
                {b.body}
              </div>
              <div className="text-xs mt-1" style={{ color: "var(--text-muted)" }}>
                {JSON.stringify(b.target_criteria)} · {new Date(b.created_at).toLocaleString()}
              </div>
            </div>
            <div
              className="px-3 py-1 rounded-xl text-xs font-semibold"
              style={{ backgroundColor: "var(--brand-soft)", color: "var(--brand)" }}
            >
              {b.sent_count} {dict.broadcasts.sentCount}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
