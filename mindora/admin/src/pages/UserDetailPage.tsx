import React, { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { ArrowLeft, KeyRound, Shield } from "lucide-react";
import { apiRequest } from "../lib/api";
import { useI18n } from "../i18n";

interface UserDetail {
  id: string;
  email: string;
  full_name: string | null;
  preferred_language: string;
  country_code: string;
  is_active: boolean;
  is_verified: boolean;
  is_admin: boolean;
  suspension_reason: string | null;
  documents_count: number;
  papers_count: number;
  sessions_count: number;
  roles: string[];
  education_system: string | null;
  education_level: string | null;
  subjects: string[];
}

interface RoleItem {
  id: string;
  name: string;
  description: string | null;
}

export function UserDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { dict } = useI18n();
  const [user, setUser] = useState<UserDetail | null>(null);
  const [roles, setRoles] = useState<RoleItem[]>([]);
  const [perms, setPerms] = useState<string[]>([]);
  const [selectedRole, setSelectedRole] = useState("moderator");
  const [reason, setReason] = useState("");
  const [statusMsg, setStatusMsg] = useState<string | null>(null);

  const load = async () => {
    if (!id) return;
    const [detail, allRoles, effPerms] = await Promise.all([
      apiRequest<UserDetail>(`/admin/users/${id}`),
      apiRequest<RoleItem[]>("/admin/roles"),
      apiRequest<string[]>(`/admin/users/${id}/permissions`).catch(() => []),
    ]);
    setUser(detail);
    setRoles(allRoles);
    setPerms(effPerms);
  };

  useEffect(() => {
    load();
  }, [id]);

  const assignRole = async () => {
    if (!id) return;
    await apiRequest(`/admin/users/${id}/roles`, {
      method: "POST",
      body: JSON.stringify({ role_name: selectedRole }),
    });
    setStatusMsg(dict.common.successSaved);
    await load();
  };

  const revokeRole = async (roleName: string) => {
    if (!id) return;
    await apiRequest(`/admin/users/${id}/roles/${roleName}`, { method: "DELETE" });
    await load();
  };

  const suspend = async () => {
    if (!id || reason.trim().length < 3) return;
    await apiRequest(`/admin/users/${id}/suspend`, {
      method: "POST",
      body: JSON.stringify({ reason }),
    });
    setReason("");
    await load();
  };

  const revokeSessions = async () => {
    if (!id) return;
    await apiRequest(`/admin/users/${id}/revoke-sessions`, { method: "POST" });
    setStatusMsg(dict.common.successSaved);
  };

  if (!user) return <div className="text-sm">{dict.common.loading}</div>;

  return (
    <div className="space-y-6">
      <Link to="/users" className="inline-flex items-center gap-2 text-sm" style={{ color: "var(--brand)" }}>
        <ArrowLeft className="w-4 h-4" />
        <span>{dict.common.back}</span>
      </Link>

      {statusMsg && (
        <div
          className="p-3 rounded-xl text-sm border"
          style={{ backgroundColor: "var(--success-soft)", borderColor: "var(--success)", color: "var(--success)" }}
        >
          {statusMsg}
        </div>
      )}

      <div
        className="p-6 rounded-2xl border space-y-3"
        style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
      >
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="text-xl font-bold">{user.full_name || user.email}</h1>
            <div className="text-sm" style={{ color: "var(--text-secondary)" }}>
              {user.email} · {user.country_code} · {user.preferred_language.toUpperCase()}
            </div>
          </div>
          <button
            type="button"
            onClick={revokeSessions}
            className="inline-flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-semibold cursor-pointer"
            style={{ backgroundColor: "var(--warning-soft)", color: "var(--warning)" }}
          >
            <KeyRound className="w-3.5 h-3.5" />
            <span>{dict.users.revokeSessions}</span>
          </button>
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-2 text-sm">
          <div>Docs: <strong>{user.documents_count}</strong></div>
          <div>Papers: <strong>{user.papers_count}</strong></div>
          <div>Sessions: <strong>{user.sessions_count}</strong></div>
          <div>System: <strong>{user.education_system || "—"}</strong></div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div
          className="p-5 rounded-2xl border space-y-4"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          <h2 className="font-semibold flex items-center gap-2">
            <Shield className="w-4 h-4" style={{ color: "var(--brand)" }} />
            <span>{dict.users.assignRole}</span>
          </h2>
          <div className="flex gap-2">
            <select
              value={selectedRole}
              onChange={(e) => setSelectedRole(e.target.value)}
              className="flex-1 px-3 py-2 rounded-xl border text-sm"
              style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
            >
              {roles.map((r) => (
                <option key={r.id} value={r.name}>
                  {r.name}
                </option>
              ))}
            </select>
            <button
              type="button"
              onClick={assignRole}
              className="px-4 py-2 rounded-xl text-xs font-semibold cursor-pointer"
              style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
            >
              {dict.common.save}
            </button>
          </div>
          <div className="flex flex-wrap gap-2">
            {user.roles.map((r) => (
              <span
                key={r}
                className="inline-flex items-center gap-2 px-2.5 py-1 rounded-lg text-xs font-medium border"
                style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
              >
                {r}
                <button
                  type="button"
                  onClick={() => revokeRole(r)}
                  className="cursor-pointer"
                  style={{ color: "var(--danger)" }}
                >
                  ×
                </button>
              </span>
            ))}
          </div>
          <div className="text-xs" style={{ color: "var(--text-secondary)" }}>
            <strong>{dict.users.permissions}:</strong> {perms.join(", ") || "—"}
          </div>
        </div>

        <div
          className="p-5 rounded-2xl border space-y-3"
          style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
        >
          <h2 className="font-semibold">{dict.users.suspend}</h2>
          <input
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder={dict.users.suspendReasonPrompt}
            className="w-full px-3 py-2 rounded-xl border text-sm"
            style={{ backgroundColor: "var(--bg-elevated)", borderColor: "var(--border-subtle)" }}
          />
          <button
            type="button"
            onClick={suspend}
            className="px-4 py-2 rounded-xl text-xs font-semibold cursor-pointer"
            style={{ backgroundColor: "var(--danger-soft)", color: "var(--danger)" }}
          >
            {dict.users.suspend}
          </button>
        </div>
      </div>
    </div>
  );
}
