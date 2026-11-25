import React, { useEffect, useState } from "react";
import { Archive, Check, Download, Eye, RefreshCw, X } from "lucide-react";
import { apiDownloadBlob, apiRequest } from "../lib/api";
import { useI18n } from "../i18n";

interface ModerationDoc {
  id: string;
  title: string;
  owner_email: string;
  category: string | null;
  academic_level: string | null;
  language: string;
  exam_system: string | null;
  size_bytes: number;
  status: string;
  rejection_reason: string | null;
  original_filename: string;
  archived_at: string | null;
  created_at: string;
}

export function ModerationPage() {
  const { dict } = useI18n();
  const [docs, setDocs] = useState<ModerationDoc[]>([]);
  const [statusFilter, setStatusFilter] = useState("");
  const [search, setSearch] = useState("");
  const [showArchived, setShowArchived] = useState(false);
  const [selected, setSelected] = useState<string[]>([]);
  const [rejectTarget, setRejectTarget] = useState<string | null>(null);
  const [rejectReason, setRejectReason] = useState("");
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [previewTitle, setPreviewTitle] = useState<string>("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      if (statusFilter) params.set("status", statusFilter);
      if (search.trim()) params.set("search", search.trim());
      params.set("archived", String(showArchived));
      const rows = await apiRequest<ModerationDoc[]>(`/admin/documents?${params.toString()}`);
      setDocs(Array.isArray(rows) ? rows : []);
      setSelected([]);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, [statusFilter, showArchived]);

  const approve = async (id: string) => {
    try {
      await apiRequest(`/admin/documents/${id}/approve`, { method: "POST" });
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const confirmReject = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!rejectTarget || rejectReason.trim().length < 3) return;
    try {
      if (rejectTarget === "__BULK__") {
        await apiRequest("/admin/documents/bulk-reject", {
          method: "POST",
          body: JSON.stringify({ document_ids: selected, reason: rejectReason.trim() }),
        });
      } else {
        await apiRequest(`/admin/documents/${rejectTarget}/reject`, {
          method: "POST",
          body: JSON.stringify({ reason: rejectReason.trim() }),
        });
      }
      setRejectTarget(null);
      setRejectReason("");
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const bulkApprove = async () => {
    if (selected.length === 0) return;
    try {
      await apiRequest("/admin/documents/bulk-approve", {
        method: "POST",
        body: JSON.stringify({ document_ids: selected }),
      });
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const toggleArchive = async (doc: ModerationDoc) => {
    try {
      const action = doc.archived_at ? "unarchive" : "archive";
      await apiRequest(`/admin/documents/${doc.id}/${action}`, { method: "POST" });
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const openPreview = async (doc: ModerationDoc) => {
    try {
      const blob = await apiDownloadBlob(`/admin/documents/${doc.id}/download`);
      if (previewUrl) URL.revokeObjectURL(previewUrl);
      const url = URL.createObjectURL(blob);
      setPreviewTitle(doc.original_filename || doc.title);
      setPreviewUrl(url);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  const toggleSelect = (id: string) => {
    setSelected((prev) => (prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]));
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">{dict.moderation.title}</h1>
          <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
            {dict.moderation.subtitle}
          </p>
        </div>
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

      {error && (
        <div
          className="p-3 rounded-xl border text-sm"
          style={{ backgroundColor: "var(--danger-soft)", borderColor: "var(--danger)", color: "var(--danger)" }}
        >
          {error}
        </div>
      )}

      <div className="flex flex-wrap items-center gap-3">
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="px-3 py-2 rounded-xl border text-sm"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          <option value="">{dict.common.all}</option>
          <option value="pending">{dict.moderation.pending}</option>
          <option value="approved">{dict.moderation.approved}</option>
          <option value="rejected">{dict.moderation.rejected}</option>
        </select>

        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && load()}
          placeholder={dict.common.search}
          className="px-3 py-2 rounded-xl border text-sm w-64"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        />

        <label className="inline-flex items-center gap-2 text-xs cursor-pointer">
          <input
            type="checkbox"
            checked={showArchived}
            onChange={(e) => setShowArchived(e.target.checked)}
          />
          <span>{dict.moderation.showArchived}</span>
        </label>

        {selected.length > 0 && (
          <div className="flex items-center gap-2 ml-auto">
            <button
              type="button"
              onClick={bulkApprove}
              className="px-3 py-1.5 rounded-xl text-xs font-semibold cursor-pointer"
              style={{ backgroundColor: "var(--success-soft)", color: "var(--success)" }}
            >
              {dict.moderation.bulkApprove} ({selected.length})
            </button>
            <button
              type="button"
              onClick={() => setRejectTarget("__BULK__")}
              className="px-3 py-1.5 rounded-xl text-xs font-semibold cursor-pointer"
              style={{ backgroundColor: "var(--danger-soft)", color: "var(--danger)" }}
            >
              {dict.moderation.bulkReject} ({selected.length})
            </button>
          </div>
        )}
      </div>

      {rejectTarget && (
        <form
          onSubmit={confirmReject}
          className="p-4 rounded-2xl border flex flex-wrap items-center gap-3"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--danger)" }}
        >
          <input
            required
            minLength={3}
            value={rejectReason}
            onChange={(e) => setRejectReason(e.target.value)}
            placeholder={dict.moderation.rejectReason}
            className="flex-1 min-w-[220px] px-3 py-2 rounded-xl border text-sm"
            style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
          />
          <button
            type="submit"
            className="px-4 py-2 rounded-xl text-xs font-semibold cursor-pointer"
            style={{ backgroundColor: "var(--danger)", color: "var(--text-primary)" }}
          >
            {dict.common.confirm}
          </button>
          <button
            type="button"
            onClick={() => {
              setRejectTarget(null);
              setRejectReason("");
            }}
            className="px-3 py-2 rounded-xl text-xs font-semibold border cursor-pointer"
            style={{ borderColor: "var(--border-subtle)" }}
          >
            {dict.common.cancel}
          </button>
        </form>
      )}

      <div
        className="rounded-2xl border overflow-x-auto"
        style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
      >
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b text-left text-xs" style={{ borderColor: "var(--border-subtle)", color: "var(--text-secondary)" }}>
              <th className="p-3 w-8"></th>
              <th className="p-3">Document</th>
              <th className="p-3">Owner</th>
              <th className="p-3">System</th>
              <th className="p-3">{dict.common.status}</th>
              <th className="p-3 text-right">{dict.common.actions}</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={6} className="p-6 text-center text-sm" style={{ color: "var(--text-muted)" }}>
                  {dict.common.loading}
                </td>
              </tr>
            ) : docs.length === 0 ? (
              <tr>
                <td colSpan={6} className="p-6 text-center text-sm" style={{ color: "var(--text-muted)" }}>
                  {dict.common.noData}
                </td>
              </tr>
            ) : (
              docs.map((d) => (
                <tr key={d.id} className="border-b last:border-b-0" style={{ borderColor: "var(--border-subtle)" }}>
                  <td className="p-3">
                    <input
                      type="checkbox"
                      checked={selected.includes(d.id)}
                      onChange={() => toggleSelect(d.id)}
                    />
                  </td>
                  <td className="p-3">
                    <div className="font-medium">{d.title}</div>
                    <div className="text-xs" style={{ color: "var(--text-muted)" }}>
                      {d.original_filename} · {(d.size_bytes / 1024).toFixed(1)} KB
                    </div>
                  </td>
                  <td className="p-3 text-xs">{d.owner_email}</td>
                  <td className="p-3 text-xs">{d.exam_system || "—"} {d.academic_level || ""}</td>
                  <td className="p-3">
                    <span
                      className="px-2 py-1 rounded-lg text-xs font-semibold uppercase"
                      style={{
                        backgroundColor:
                          d.status === "approved"
                            ? "var(--success-soft)"
                            : d.status === "rejected"
                            ? "var(--danger-soft)"
                            : "var(--warning-soft)",
                        color:
                          d.status === "approved"
                            ? "var(--success)"
                            : d.status === "rejected"
                            ? "var(--danger)"
                            : "var(--warning)",
                      }}
                    >
                      {d.status}
                    </span>
                  </td>
                  <td className="p-3">
                    <div className="flex items-center justify-end gap-1.5">
                      <button
                        type="button"
                        onClick={() => openPreview(d)}
                        className="p-1.5 rounded-lg border cursor-pointer"
                        style={{ borderColor: "var(--border-subtle)" }}
                        title={dict.moderation.preview}
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                      {d.status !== "approved" && (
                        <button
                          type="button"
                          onClick={() => approve(d.id)}
                          className="p-1.5 rounded-lg cursor-pointer"
                          style={{ backgroundColor: "var(--success-soft)", color: "var(--success)" }}
                          title={dict.moderation.approve}
                        >
                          <Check className="w-4 h-4" />
                        </button>
                      )}
                      {d.status !== "rejected" && (
                        <button
                          type="button"
                          onClick={() => setRejectTarget(d.id)}
                          className="p-1.5 rounded-lg cursor-pointer"
                          style={{ backgroundColor: "var(--danger-soft)", color: "var(--danger)" }}
                          title={dict.moderation.reject}
                        >
                          <X className="w-4 h-4" />
                        </button>
                      )}
                      <button
                        type="button"
                        onClick={() => toggleArchive(d)}
                        className="p-1.5 rounded-lg border cursor-pointer"
                        style={{ borderColor: "var(--border-subtle)" }}
                        title={d.archived_at ? dict.moderation.unarchive : dict.moderation.archive}
                      >
                        <Archive className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {previewUrl && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center p-4"
          style={{ backgroundColor: "rgba(2, 6, 23, 0.8)" }}
        >
          <div
            className="w-full max-w-4xl h-[80vh] rounded-2xl border flex flex-col overflow-hidden"
            style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
          >
            <div
              className="px-4 py-3 border-b flex items-center justify-between"
              style={{ borderColor: "var(--border-subtle)" }}
            >
              <span className="font-semibold text-sm truncate">{previewTitle}</span>
              <div className="flex items-center gap-2">
                <a
                  href={previewUrl}
                  download={previewTitle}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold"
                  style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
                >
                  <Download className="w-3.5 h-3.5" />
                  <span>{dict.moderation.preview}</span>
                </a>
                <button
                  type="button"
                  onClick={() => {
                    URL.revokeObjectURL(previewUrl);
                    setPreviewUrl(null);
                  }}
                  className="p-1.5 rounded-lg border cursor-pointer"
                  style={{ borderColor: "var(--border-subtle)" }}
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            </div>
            <iframe title={previewTitle} src={previewUrl} className="w-full flex-1 bg-white" />
          </div>
        </div>
      )}
    </div>
  );
}
