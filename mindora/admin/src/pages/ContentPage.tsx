import React, { useEffect, useState } from "react";
import { Plus, Save } from "lucide-react";
import { apiRequest } from "../lib/api";
import { useI18n } from "../i18n";

interface ContentString {
  id: string;
  key: string;
  description: string | null;
  value_fr: string;
  value_en: string;
  group: string;
  updated_at: string;
}

export function ContentPage() {
  const { dict } = useI18n();
  const [items, setItems] = useState<ContentString[]>([]);
  const [drafts, setDrafts] = useState<Record<string, { value_fr: string; value_en: string }>>({});
  const [newKey, setNewKey] = useState("");
  const [newGroup, setNewGroup] = useState("general");
  const [newFr, setNewFr] = useState("");
  const [newEn, setNewEn] = useState("");
  const [showNew, setShowNew] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [savedKey, setSavedKey] = useState<string | null>(null);

  const load = async () => {
    setError(null);
    try {
      const rows = await apiRequest<ContentString[]>("/admin/content");
      setItems(rows);
      const map: Record<string, { value_fr: string; value_en: string }> = {};
      rows.forEach((r) => {
        map[r.key] = { value_fr: r.value_fr, value_en: r.value_en };
      });
      setDrafts(map);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  useEffect(() => {
    load();
  }, []);

  const saveItem = async (key: string) => {
    const d = drafts[key];
    if (!d) return;
    setError(null);
    try {
      await apiRequest(`/admin/content/${encodeURIComponent(key)}`, {
        method: "PATCH",
        body: JSON.stringify(d),
      });
      setSavedKey(key);
      setTimeout(() => setSavedKey(null), 2000);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const createItem = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    try {
      await apiRequest("/admin/content", {
        method: "POST",
        body: JSON.stringify({
          key: newKey.trim(),
          group: newGroup.trim() || "general",
          value_fr: newFr,
          value_en: newEn,
        }),
      });
      setNewKey("");
      setNewFr("");
      setNewEn("");
      setShowNew(false);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">{dict.content.title}</h1>
          <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
            {dict.content.subtitle}
          </p>
        </div>
        <button
          type="button"
          onClick={() => setShowNew((v) => !v)}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold cursor-pointer"
          style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
        >
          <Plus className="w-4 h-4" />
          <span>{dict.content.addKey}</span>
        </button>
      </div>

      {error && (
        <div
          className="p-3 rounded-xl border text-sm"
          style={{ backgroundColor: "var(--danger-soft)", borderColor: "var(--danger)", color: "var(--danger)" }}
        >
          {error}
        </div>
      )}

      {showNew && (
        <form
          onSubmit={createItem}
          className="p-5 rounded-2xl border grid grid-cols-1 md:grid-cols-2 gap-4"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          <div>
            <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
              {dict.content.key}
            </label>
            <input
              required
              pattern="^[a-z0-9_.]+$"
              value={newKey}
              onChange={(e) => setNewKey(e.target.value)}
              placeholder="home.hero_title"
              className="w-full px-3 py-2 rounded-xl border text-sm font-mono-code"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
          </div>
          <div>
            <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
              {dict.content.group}
            </label>
            <input
              value={newGroup}
              onChange={(e) => setNewGroup(e.target.value)}
              className="w-full px-3 py-2 rounded-xl border text-sm"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
          </div>
          <div>
            <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
              {dict.content.valueFr}
            </label>
            <input
              value={newFr}
              onChange={(e) => setNewFr(e.target.value)}
              className="w-full px-3 py-2 rounded-xl border text-sm"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
          </div>
          <div>
            <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
              {dict.content.valueEn}
            </label>
            <input
              value={newEn}
              onChange={(e) => setNewEn(e.target.value)}
              className="w-full px-3 py-2 rounded-xl border text-sm"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
          </div>
          <div className="md:col-span-2 flex justify-end">
            <button
              type="submit"
              className="px-4 py-2 rounded-xl text-xs font-semibold cursor-pointer"
              style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
            >
              {dict.common.create}
            </button>
          </div>
        </form>
      )}

      <div className="space-y-3">
        {items.map((item) => {
          const d = drafts[item.key] || { value_fr: item.value_fr, value_en: item.value_en };
          return (
            <div
              key={item.id}
              className="p-4 rounded-2xl border grid grid-cols-1 lg:grid-cols-12 gap-3 items-end"
              style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
            >
              <div className="lg:col-span-3">
                <div className="font-mono-code text-xs font-semibold" style={{ color: "var(--brand)" }}>
                  {item.key}
                </div>
                <div className="text-xs" style={{ color: "var(--text-muted)" }}>
                  {item.group}
                </div>
              </div>
              <div className="lg:col-span-4">
                <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
                  FR
                </label>
                <input
                  value={d.value_fr}
                  onChange={(e) =>
                    setDrafts((prev) => ({ ...prev, [item.key]: { ...d, value_fr: e.target.value } }))
                  }
                  className="w-full px-3 py-2 rounded-xl border text-sm"
                  style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
                />
              </div>
              <div className="lg:col-span-4">
                <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
                  EN
                </label>
                <input
                  value={d.value_en}
                  onChange={(e) =>
                    setDrafts((prev) => ({ ...prev, [item.key]: { ...d, value_en: e.target.value } }))
                  }
                  className="w-full px-3 py-2 rounded-xl border text-sm"
                  style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
                />
              </div>
              <div className="lg:col-span-1 flex justify-end">
                <button
                  type="button"
                  onClick={() => saveItem(item.key)}
                  className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-semibold cursor-pointer"
                  style={{
                    backgroundColor: savedKey === item.key ? "var(--success-soft)" : "var(--brand-soft)",
                    color: savedKey === item.key ? "var(--success)" : "var(--brand)",
                  }}
                >
                  <Save className="w-3.5 h-3.5" />
                  <span>{dict.common.save}</span>
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
