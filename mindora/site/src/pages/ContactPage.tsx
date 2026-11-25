import React, { useState } from "react";
import { CheckCircle2, Send } from "lucide-react";
import { useI18n } from "../i18n";
import { submitContact } from "../lib/api";

export function ContactPage() {
  const { dict } = useI18n();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [category, setCategory] = useState("general");
  const [subject, setSubject] = useState("");
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [ticketId, setTicketId] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    setTicketId(null);
    try {
      const res = await submitContact({ name, email, category, subject, message });
      setTicketId(res.ticket_id);
      setName("");
      setEmail("");
      setSubject("");
      setMessage("");
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto px-4 sm:px-6 py-14 space-y-8">
      <div className="space-y-2">
        <h1 className="text-3xl font-extrabold">{dict.contact.title}</h1>
        <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
          {dict.contact.subtitle}
        </p>
      </div>

      {ticketId && (
        <div
          className="p-4 rounded-2xl border flex items-center gap-3 text-sm"
          style={{
            backgroundColor: "var(--success-soft)",
            borderColor: "var(--success)",
            color: "var(--success)",
          }}
        >
          <CheckCircle2 className="w-5 h-5 shrink-0" />
          <span>
            {dict.contact.successPrefix}
            {ticketId}
          </span>
        </div>
      )}

      {error && (
        <div
          className="p-4 rounded-2xl border text-sm"
          style={{
            backgroundColor: "var(--danger-soft)",
            borderColor: "var(--danger)",
            color: "var(--danger)",
          }}
        >
          {error}
        </div>
      )}

      <form
        onSubmit={handleSubmit}
        className="p-6 rounded-2xl border space-y-4"
        style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
      >
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label htmlFor="c-name" className="block text-xs font-semibold mb-1.5" style={{ color: "var(--text-secondary)" }}>
              {dict.contact.name}
            </label>
            <input
              id="c-name"
              required
              minLength={2}
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-3 py-2.5 rounded-xl border text-sm"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
          </div>
          <div>
            <label htmlFor="c-email" className="block text-xs font-semibold mb-1.5" style={{ color: "var(--text-secondary)" }}>
              {dict.contact.email}
            </label>
            <input
              id="c-email"
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-3 py-2.5 rounded-xl border text-sm"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label htmlFor="c-cat" className="block text-xs font-semibold mb-1.5" style={{ color: "var(--text-secondary)" }}>
              {dict.contact.category}
            </label>
            <select
              id="c-cat"
              value={category}
              onChange={(e) => setCategory(e.target.value)}
              className="w-full px-3 py-2.5 rounded-xl border text-sm"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            >
              {dict.contact.categories.map((c) => (
                <option key={c.value} value={c.value}>
                  {c.label}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label htmlFor="c-subj" className="block text-xs font-semibold mb-1.5" style={{ color: "var(--text-secondary)" }}>
              {dict.contact.subject}
            </label>
            <input
              id="c-subj"
              required
              minLength={3}
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
              className="w-full px-3 py-2.5 rounded-xl border text-sm"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
          </div>
        </div>

        <div>
          <label htmlFor="c-msg" className="block text-xs font-semibold mb-1.5" style={{ color: "var(--text-secondary)" }}>
            {dict.contact.message}
          </label>
          <textarea
            id="c-msg"
            required
            minLength={5}
            rows={5}
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            className="w-full px-3 py-2.5 rounded-xl border text-sm"
            style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
          />
        </div>

        <button
          type="submit"
          disabled={busy}
          className="inline-flex items-center gap-2 px-5 py-3 rounded-xl text-sm font-semibold cursor-pointer"
          style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
        >
          <Send className="w-4 h-4" />
          <span>{busy ? dict.contact.sending : dict.contact.send}</span>
        </button>
      </form>
    </div>
  );
}
