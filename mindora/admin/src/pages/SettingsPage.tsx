import React, { useEffect, useState } from "react";
import { Save, Wrench } from "lucide-react";
import { apiRequest } from "../lib/api";
import { useI18n } from "../i18n";

interface FeatureFlag {
  key: string;
  enabled: boolean;
  description: string | null;
}

interface AppSetting {
  key: string;
  value: unknown;
  description: string | null;
}

interface MaintenanceOut {
  enabled: boolean;
  message: string;
}

export function SettingsPage() {
  const { dict } = useI18n();
  const [flags, setFlags] = useState<FeatureFlag[]>([]);
  const [settings, setSettings] = useState<AppSetting[]>([]);
  const [draftValues, setDraftValues] = useState<Record<string, string>>({});
  const [maintEnabled, setMaintEnabled] = useState(false);
  const [maintMsg, setMaintMsg] = useState("");
  const [statusMsg, setStatusMsg] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = async () => {
    setError(null);
    try {
      const [f, s, m] = await Promise.all([
        apiRequest<FeatureFlag[]>("/admin/settings/feature-flags"),
        apiRequest<AppSetting[]>("/admin/settings"),
        apiRequest<MaintenanceOut>("/admin/settings/maintenance"),
      ]);
      setFlags(f);
      setSettings(s);
      const map: Record<string, string> = {};
      s.forEach((item) => {
        map[item.key] = typeof item.value === "string" ? item.value : JSON.stringify(item.value);
      });
      setDraftValues(map);
      setMaintEnabled(m.enabled);
      setMaintMsg(m.message || "");
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  useEffect(() => {
    load();
  }, []);

  const toggleFlag = async (flag: FeatureFlag) => {
    try {
      await apiRequest(`/admin/settings/feature-flags/${encodeURIComponent(flag.key)}`, {
        method: "PATCH",
        body: JSON.stringify({ enabled: !flag.enabled }),
      });
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const saveMaintenance = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatusMsg(null);
    try {
      await apiRequest("/admin/settings/maintenance", {
        method: "POST",
        body: JSON.stringify({ enabled: maintEnabled, message: maintMsg }),
      });
      setStatusMsg(dict.common.successSaved);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const saveSetting = async (key: string) => {
    const raw = draftValues[key] ?? "";
    let parsed: unknown = raw;
    try {
      parsed = JSON.parse(raw);
    } catch {
      parsed = raw;
    }
    try {
      await apiRequest(`/admin/settings/${encodeURIComponent(key)}`, {
        method: "PATCH",
        body: JSON.stringify({ value: parsed }),
      });
      setStatusMsg(dict.common.successSaved);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">{dict.settings.title}</h1>
        <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
          {dict.settings.subtitle}
        </p>
      </div>

      {error && (
        <div className="p-3 rounded-xl border text-sm" style={{ backgroundColor: "var(--danger-soft)", borderColor: "var(--danger)", color: "var(--danger)" }}>
          {error}
        </div>
      )}
      {statusMsg && (
        <div className="p-3 rounded-xl border text-sm" style={{ backgroundColor: "var(--success-soft)", borderColor: "var(--success)", color: "var(--success)" }}>
          {statusMsg}
        </div>
      )}

      <form
        onSubmit={saveMaintenance}
        className="p-5 rounded-2xl border space-y-4"
        style={{ backgroundColor: "var(--bg-surface)", borderColor: maintEnabled ? "var(--warning)" : "var(--border-subtle)" }}
      >
        <div className="flex items-center gap-2 font-semibold">
          <Wrench className="w-4 h-4" style={{ color: "var(--warning)" }} />
          <span>{dict.settings.maintenanceMode}</span>
        </div>

        <label className="flex items-center gap-2 text-sm cursor-pointer">
          <input
            type="checkbox"
            checked={maintEnabled}
            onChange={(e) => setMaintEnabled(e.target.checked)}
          />
          <span>{dict.settings.maintenanceEnabled}</span>
        </label>

        <input
          value={maintMsg}
          onChange={(e) => setMaintMsg(e.target.value)}
          placeholder={dict.settings.maintenanceMessage}
          className="w-full px-3 py-2 rounded-xl border text-sm"
          style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
        />

        <button
          type="submit"
          className="px-4 py-2 rounded-xl text-xs font-semibold cursor-pointer"
          style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
        >
          {dict.settings.saveMaintenance}
        </button>
      </form>

      <div className="p-5 rounded-2xl border space-y-3" style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}>
        <h2 className="font-semibold">{dict.settings.featureFlags}</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {flags.map((f) => (
            <div
              key={f.key}
              className="p-3 rounded-xl border flex items-center justify-between gap-3"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            >
              <div>
                <div className="font-mono-code text-xs font-semibold">{f.key}</div>
                {f.description && (
                  <div className="text-xs" style={{ color: "var(--text-muted)" }}>{f.description}</div>
                )}
              </div>
              <button
                type="button"
                onClick={() => toggleFlag(f)}
                className="px-3 py-1 rounded-lg text-xs font-semibold cursor-pointer"
                style={{
                  backgroundColor: f.enabled ? "var(--success-soft)" : "var(--bg-surface)",
                  color: f.enabled ? "var(--success)" : "var(--text-secondary)",
                }}
              >
                {f.enabled ? dict.common.active : dict.common.inactive}
              </button>
            </div>
          ))}
        </div>
      </div>

      <div className="p-5 rounded-2xl border space-y-3" style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}>
        <h2 className="font-semibold">{dict.settings.appSettings}</h2>
        <div className="space-y-2">
          {settings.map((s) => (
            <div
              key={s.key}
              className="p-3 rounded-xl border flex flex-wrap items-center gap-3"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            >
              <div className="w-48 font-mono-code text-xs font-semibold" style={{ color: "var(--brand)" }}>
                {s.key}
              </div>
              <input
                value={draftValues[s.key] ?? ""}
                onChange={(e) => setDraftValues((prev) => ({ ...prev, [s.key]: e.target.value }))}
                className="flex-1 min-w-[200px] px-3 py-1.5 rounded-xl border text-xs font-mono-code"
                style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
              />
              <button
                type="button"
                onClick={() => saveSetting(s.key)}
                className="inline-flex items-center gap-1 px-3 py-1.5 rounded-xl text-xs font-semibold cursor-pointer"
                style={{ backgroundColor: "var(--brand-soft)", color: "var(--brand)" }}
              >
                <Save className="w-3.5 h-3.5" />
                <span>{dict.common.save}</span>
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
