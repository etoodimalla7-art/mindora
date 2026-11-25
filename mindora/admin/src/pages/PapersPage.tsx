import React, { useEffect, useState } from "react";
import { FileText, Plus, RefreshCw, Trash2, Upload } from "lucide-react";
import { apiRequest } from "../lib/api";
import { useAuth } from "../lib/auth";
import { useI18n } from "../i18n";

interface PaperRow {
  id: string;
  title: string;
  subject: string;
  exam_system: string;
  exam_level: string;
  exam_year: number | null;
  language: string;
  status: string;
  file_name: string;
  file_size: number;
  mime_type: string;
  download_count: number;
  created_at: string;
}

export function PapersPage() {
  const { dict } = useI18n();
  const { hasPermission } = useAuth();
  const canEdit = hasPermission("documents.moderate") || hasPermission("content.manage");

  const [papers, setPapers] = useState<PaperRow[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showUpload, setShowUpload] = useState(false);

  const [title, setTitle] = useState("");
  const [subject, setSubject] = useState("Mathématiques");
  const [examSystem, setExamSystem] = useState("FRANCOPHONE");
  const [examLevel, setExamLevel] = useState("Terminale");
  const [examYear, setExamYear] = useState("2025");
  const [language, setLanguage] = useState("fr");
  const [description, setDescription] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const qs = search.trim() ? `?search=${encodeURIComponent(search.trim())}` : "";
      const rows = await apiRequest<PaperRow[]>(`/admin/papers${qs}`);
      setPapers(rows);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const handleUpload = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!file) return;
    setUploading(true);
    setError(null);
    try {
      const form = new FormData();
      form.append("title", title);
      form.append("subject", subject);
      form.append("exam_system", examSystem);
      form.append("exam_level", examLevel);
      form.append("language", language);
      if (examYear) form.append("exam_year", examYear);
      if (description) form.append("description", description);
      form.append("file", file);

      await apiRequest<PaperRow>("/admin/papers", {
        method: "POST",
        body: form,
      });
      setTitle("");
      setDescription("");
      setFile(null);
      setShowUpload(false);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setUploading(false);
    }
  };

  const handleStatusChange = async (paper: PaperRow, status: string) => {
    try {
      await apiRequest(`/admin/papers/${paper.id}`, {
        method: "PATCH",
        body: JSON.stringify({ status }),
      });
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const handleDelete = async (paper: PaperRow) => {
    try {
      await apiRequest(`/admin/papers/${paper.id}`, { method: "DELETE" });
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const statusStyle = (status: string) => {
    if (status === "published") return { bg: "var(--success-soft)", color: "var(--success)" };
    if (status === "archived") return { bg: "var(--bg-elevated)", color: "var(--text-muted)" };
    return { bg: "var(--warning-soft)", color: "var(--warning)" };
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">{dict.papers.title}</h1>
          <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
            {dict.papers.subtitle}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={load}
            className="inline-flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-semibold border cursor-pointer"
            style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
          >
            <RefreshCw className="w-3.5 h-3.5" />
            <span>{dict.common.refresh}</span>
          </button>
          {canEdit && (
            <button
              type="button"
              onClick={() => setShowUpload((v) => !v)}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold cursor-pointer"
              style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
            >
              <Plus className="w-4 h-4" />
              <span>{dict.papers.uploadPaper}</span>
            </button>
          )}
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

      {showUpload && (
        <form
          onSubmit={handleUpload}
          className="p-5 rounded-2xl border grid grid-cols-1 md:grid-cols-3 gap-4"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          <div>
            <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
              {dict.papers.paperTitle}
            </label>
            <input
              required
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full px-3 py-2 rounded-xl border text-sm"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
          </div>
          <div>
            <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
              {dict.papers.subject}
            </label>
            <input
              required
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
              className="w-full px-3 py-2 rounded-xl border text-sm"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
          </div>
          <div>
            <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
              {dict.papers.system}
            </label>
            <select
              value={examSystem}
              onChange={(e) => setExamSystem(e.target.value)}
              className="w-full px-3 py-2 rounded-xl border text-sm"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            >
              <option value="FRANCOPHONE">FRANCOPHONE</option>
              <option value="ANGLOPHONE">ANGLOPHONE</option>
              <option value="GCE">GCE</option>
              <option value="BAC">BAC</option>
            </select>
          </div>
          <div>
            <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
              {dict.papers.level}
            </label>
            <input
              required
              value={examLevel}
              onChange={(e) => setExamLevel(e.target.value)}
              className="w-full px-3 py-2 rounded-xl border text-sm"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
          </div>
          <div>
            <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
              {dict.papers.year}
            </label>
            <input
              type="number"
              value={examYear}
              onChange={(e) => setExamYear(e.target.value)}
              className="w-full px-3 py-2 rounded-xl border text-sm"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
          </div>
          <div>
            <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
              {dict.papers.language}
            </label>
            <select
              value={language}
              onChange={(e) => setLanguage(e.target.value)}
              className="w-full px-3 py-2 rounded-xl border text-sm"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            >
              <option value="fr">fr</option>
              <option value="en">en</option>
            </select>
          </div>
          <div className="md:col-span-2">
            <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
              {dict.papers.description}
            </label>
            <input
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full px-3 py-2 rounded-xl border text-sm"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
          </div>
          <div>
            <label className="block text-xs mb-1" style={{ color: "var(--text-secondary)" }}>
              {dict.papers.pdfFile}
            </label>
            <input
              type="file"
              required
              accept=".pdf,.doc,.docx"
              onChange={(e) => setFile(e.target.files?.[0] || null)}
              className="w-full px-3 py-1.5 rounded-xl border text-xs"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            />
          </div>
          <div className="md:col-span-3 flex justify-end gap-2">
            <button
              type="button"
              onClick={() => setShowUpload(false)}
              className="px-4 py-2 rounded-xl text-xs font-semibold border cursor-pointer"
              style={{ borderColor: "var(--border-subtle)" }}
            >
              {dict.common.cancel}
            </button>
            <button
              type="submit"
              disabled={uploading || !file}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold cursor-pointer"
              style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
            >
              <Upload className="w-3.5 h-3.5" />
              <span>{uploading ? dict.common.loading : dict.papers.publish}</span>
            </button>
          </div>
        </form>
      )}

      <div className="flex items-center gap-2">
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && load()}
          placeholder={dict.common.search}
          className="px-3 py-2 rounded-xl border text-sm w-full max-w-sm"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        />
        <button
          type="button"
          onClick={load}
          className="px-4 py-2 rounded-xl text-xs font-semibold border cursor-pointer"
          style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
        >
          {dict.common.search}
        </button>
      </div>

      <div
        className="rounded-2xl border overflow-x-auto"
        style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
      >
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b text-left text-xs" style={{ borderColor: "var(--border-subtle)", color: "var(--text-secondary)" }}>
              <th className="p-3">{dict.papers.paperTitle}</th>
              <th className="p-3">{dict.papers.subject}</th>
              <th className="p-3">{dict.papers.system}</th>
              <th className="p-3">{dict.papers.year}</th>
              <th className="p-3">{dict.papers.downloads}</th>
              <th className="p-3">{dict.common.status}</th>
              <th className="p-3 text-right">{dict.common.actions}</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={7} className="p-6 text-center text-sm" style={{ color: "var(--text-muted)" }}>
                  {dict.common.loading}
                </td>
              </tr>
            ) : papers.length === 0 ? (
              <tr>
                <td colSpan={7} className="p-6 text-center text-sm" style={{ color: "var(--text-muted)" }}>
                  {dict.common.noData}
                </td>
              </tr>
            ) : (
              papers.map((p) => {
                const st = statusStyle(p.status);
                return (
                  <tr key={p.id} className="border-b last:border-b-0" style={{ borderColor: "var(--border-subtle)" }}>
                    <td className="p-3">
                      <div className="flex items-center gap-2 font-medium">
                        <FileText className="w-4 h-4 shrink-0" style={{ color: "var(--brand)" }} />
                        <span>{p.title}</span>
                      </div>
                      <div className="text-xs" style={{ color: "var(--text-muted)" }}>
                        {p.file_name} · {(p.file_size / 1024).toFixed(1)} KB
                      </div>
                    </td>
                    <td className="p-3">{p.subject}</td>
                    <td className="p-3 text-xs">{p.exam_system} · {p.exam_level}</td>
                    <td className="p-3">{p.exam_year ?? "—"}</td>
                    <td className="p-3">{p.download_count}</td>
                    <td className="p-3">
                      <select
                        value={p.status}
                        disabled={!canEdit}
                        onChange={(e) => handleStatusChange(p, e.target.value)}
                        className="px-2 py-1 rounded-lg text-xs font-semibold border cursor-pointer"
                        style={{ backgroundColor: st.bg, color: st.color, borderColor: "var(--border-subtle)" }}
                      >
                        <option value="draft">{dict.papers.draft}</option>
                        <option value="published">{dict.papers.published}</option>
                        <option value="archived">{dict.papers.archived}</option>
                      </select>
                    </td>
                    <td className="p-3 text-right">
                      {canEdit && (
                        <button
                          type="button"
                          onClick={() => handleDelete(p)}
                          className="p-1.5 rounded-lg cursor-pointer"
                          style={{ backgroundColor: "var(--danger-soft)", color: "var(--danger)" }}
                          title={dict.common.delete}
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
