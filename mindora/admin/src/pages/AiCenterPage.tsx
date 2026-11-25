import React, { useEffect, useState } from "react";
import { Bot, CheckCircle2, Play, Rocket, Save } from "lucide-react";
import { apiRequest } from "../lib/api";
import { useI18n } from "../i18n";

interface AIConfig {
  id: string;
  name: string;
  system_prompt: string;
  model: string;
  temperature: number;
  max_tokens: number;
  language: string;
  updated_at: string;
}

interface AIVersion {
  id: string;
  version: number;
  model: string;
  temperature: number;
  max_tokens: number;
  notes: string | null;
  published_at: string;
}

interface AITestOut {
  response: string;
  model: string;
  provider: string;
  elapsed_ms: number;
}

export function AiCenterPage() {
  const { dict } = useI18n();
  const [config, setConfig] = useState<AIConfig | null>(null);
  const [versions, setVersions] = useState<AIVersion[]>([]);
  const [systemPrompt, setSystemPrompt] = useState("");
  const [model, setModel] = useState("gemini-3.1-flash-lite-preview");
  const [temperature, setTemperature] = useState(0.7);
  const [maxTokens, setMaxTokens] = useState(1024);
  const [language, setLanguage] = useState("fr");
  const [notes, setNotes] = useState("");
  const [testMsg, setTestMsg] = useState("");
  const [testResult, setTestResult] = useState<AITestOut | null>(null);
  const [statusMsg, setStatusMsg] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = async () => {
    setError(null);
    try {
      const [cfg, vers] = await Promise.all([
        apiRequest<AIConfig>("/admin/ai/config"),
        apiRequest<AIVersion[]>("/admin/ai/versions"),
      ]);
      setConfig(cfg);
      setVersions(vers);
      setSystemPrompt(cfg.system_prompt);
      setModel(cfg.model);
      setTemperature(cfg.temperature);
      setMaxTokens(cfg.max_tokens);
      setLanguage(cfg.language);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  useEffect(() => {
    load();
  }, []);

  const saveDraft = async () => {
    setError(null);
    setStatusMsg(null);
    try {
      const updated = await apiRequest<AIConfig>("/admin/ai/config", {
        method: "PATCH",
        body: JSON.stringify({
          system_prompt: systemPrompt,
          model,
          temperature: Number(temperature),
          max_tokens: Number(maxTokens),
          language,
        }),
      });
      setConfig(updated);
      setStatusMsg(dict.common.successSaved);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const publish = async () => {
    setError(null);
    try {
      await saveDraft();
      await apiRequest<AIVersion>("/admin/ai/config/publish", {
        method: "POST",
        body: JSON.stringify({ notes: notes || null }),
      });
      setNotes("");
      await load();
      setStatusMsg(dict.common.successSaved);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const runTest = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!testMsg.trim()) return;
    setError(null);
    try {
      const res = await apiRequest<AITestOut>("/admin/ai/config/test", {
        method: "POST",
        body: JSON.stringify({
          message: testMsg.trim(),
          system_prompt: systemPrompt,
          model,
          temperature: Number(temperature),
          max_tokens: Number(maxTokens),
        }),
      });
      setTestResult(res);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const activateVersion = async (id: string) => {
    try {
      await apiRequest(`/admin/ai/versions/${id}/activate`, { method: "POST" });
      await load();
      setStatusMsg(dict.common.successSaved);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">{dict.ai.title}</h1>
        <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
          {dict.ai.subtitle}
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
      {statusMsg && (
        <div
          className="p-3 rounded-xl border text-sm flex items-center gap-2"
          style={{ backgroundColor: "var(--success-soft)", borderColor: "var(--success)", color: "var(--success)" }}
        >
          <CheckCircle2 className="w-4 h-4" />
          <span>{statusMsg}</span>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div
          className="lg:col-span-2 p-5 rounded-2xl border space-y-4"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          <div>
            <label className="block text-xs font-semibold mb-1.5" style={{ color: "var(--text-secondary)" }}>
              {dict.ai.systemPrompt}
            </label>
            <textarea
              rows={8}
              value={systemPrompt}
              onChange={(e) => setSystemPrompt(e.target.value)}
              className="w-full p-3 rounded-xl border text-sm font-mono-code"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            <div className="col-span-2">
              <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
                {dict.ai.model}
              </label>
              <input
                value={model}
                onChange={(e) => setModel(e.target.value)}
                className="w-full px-3 py-2 rounded-xl border text-sm"
                style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
              />
            </div>
            <div>
              <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
                {dict.ai.temperature}
              </label>
              <input
                type="number"
                step="0.1"
                min="0"
                max="2"
                value={temperature}
                onChange={(e) => setTemperature(parseFloat(e.target.value) || 0)}
                className="w-full px-3 py-2 rounded-xl border text-sm"
                style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
              />
            </div>
            <div>
              <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
                {dict.ai.maxTokens}
              </label>
              <input
                type="number"
                min="50"
                max="8000"
                value={maxTokens}
                onChange={(e) => setMaxTokens(parseInt(e.target.value, 10) || 1024)}
                className="w-full px-3 py-2 rounded-xl border text-sm"
                style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
              />
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-3 pt-2">
            <button
              type="button"
              onClick={saveDraft}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold border cursor-pointer"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            >
              <Save className="w-3.5 h-3.5" />
              <span>{dict.ai.saveConfig}</span>
            </button>
            <input
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder={dict.ai.publishNotes}
              className="flex-1 min-w-[180px] px-3 py-2 rounded-xl border text-xs"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
            <button
              type="button"
              onClick={publish}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold cursor-pointer"
              style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
            >
              <Rocket className="w-3.5 h-3.5" />
              <span>{dict.ai.publishVersion}</span>
            </button>
          </div>

          {config && (
            <div className="text-xs" style={{ color: "var(--text-muted)" }}>
              {config.name} · {new Date(config.updated_at).toLocaleString()}
            </div>
          )}
        </div>

        <div className="space-y-6">
          <form
            onSubmit={runTest}
            className="p-5 rounded-2xl border space-y-3"
            style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
          >
            <div className="flex items-center gap-2 font-semibold text-sm">
              <Bot className="w-4 h-4" style={{ color: "var(--brand)" }} />
              <span>{dict.ai.sandboxTitle}</span>
            </div>
            <textarea
              rows={3}
              value={testMsg}
              onChange={(e) => setTestMsg(e.target.value)}
              placeholder={dict.ai.testMessage}
              className="w-full p-3 rounded-xl border text-sm"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
            <button
              type="submit"
              className="w-full inline-flex items-center justify-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold cursor-pointer"
              style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
            >
              <Play className="w-3.5 h-3.5" />
              <span>{dict.ai.runTest}</span>
            </button>
            {testResult && (
              <div
                className="p-3 rounded-xl border text-xs space-y-1"
                style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
              >
                <div style={{ color: "var(--brand)" }}>
                  {testResult.provider} · {testResult.model} · {testResult.elapsed_ms}ms
                </div>
                <div className="whitespace-pre-wrap">{testResult.response}</div>
              </div>
            )}
          </form>

          <div
            className="p-5 rounded-2xl border space-y-3"
            style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
          >
            <h2 className="font-semibold text-sm">{dict.ai.versionsTitle}</h2>
            <div className="space-y-2 max-h-64 overflow-y-auto">
              {versions.map((v) => (
                <div
                  key={v.id}
                  className="p-3 rounded-xl border flex items-center justify-between gap-2 text-xs"
                  style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
                >
                  <div>
                    <div className="font-semibold">v{v.version} · {v.model}</div>
                    <div style={{ color: "var(--text-muted)" }}>
                      {v.notes || new Date(v.published_at).toLocaleString()}
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => activateVersion(v.id)}
                    className="px-2.5 py-1 rounded-lg font-semibold cursor-pointer"
                    style={{ backgroundColor: "var(--brand-soft)", color: "var(--brand)" }}
                  >
                    {dict.ai.activate}
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
