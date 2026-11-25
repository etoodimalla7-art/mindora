import React, { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Search, Shield, UserCheck, UserX } from "lucide-react";
import { apiRequest } from "../lib/api";
import { useI18n } from "../i18n";

interface UserRow {
  id: string;
  email: string;
  full_name: string | null;
  is_active: boolean;
  is_verified: boolean;
  is_admin: boolean;
  created_at: string;
}

export function UsersPage() {
  const { dict } = useI18n();
  const [users, setUsers] = useState<UserRow[]>([]);
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<Record<string, boolean>>({});
  const [error, setError] = useState<string | null>(null);

  const load = async (q = search) => {
    setError(null);
    try {
      const params = q ? `?search=${encodeURIComponent(q)}&limit=100` : "?limit=100";
      const rows = await apiRequest<UserRow[]>(`/admin/users${params}`);
      setUsers(rows);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  useEffect(() => {
    load();
  }, []);

  const selectedIds = Object.entries(selected)
    .filter(([, v]) => v)
    .map(([k]) => k);

  const toggleActive = async (id: string) => {
    await apiRequest(`/admin/users/${id}/toggle-active`, { method: "POST" });
    await load();
  };

  const promoteUser = async (id: string) => {
    await apiRequest(`/admin/users/${id}/promote`, { method: "POST" });
    await load();
  };

  const bulkSuspend = async () => {
    if (!selectedIds.length) return;
    await apiRequest("/admin/users/bulk-suspend", {
      method: "POST",
      body: JSON.stringify({ user_ids: selectedIds, reason: "Suspended by admin" }),
    });
    setSelected({});
    await load();
  };

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">{dict.users.title}</h1>
          <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
            {dict.users.subtitle}
          </p>
        </div>

        <form
          onSubmit={(e) => {
            e.preventDefault();
            load(search);
          }}
          className="flex items-center gap-2"
        >
          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-2.5" style={{ color: "var(--text-muted)" }} />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder={dict.common.search}
              className="pl-9 pr-3 py-2 rounded-xl border text-sm outline-none"
              style={{
                backgroundColor: "var(--bg-surface)",
                borderColor: "var(--border-subtle)",
                color: "var(--text-primary)",
              }}
            />
          </div>
          {selectedIds.length > 0 && (
            <button
              type="button"
              onClick={bulkSuspend}
              className="px-3 py-2 rounded-xl text-xs font-semibold cursor-pointer"
              style={{ backgroundColor: "var(--danger-soft)", color: "var(--danger)" }}
            >
              {dict.users.bulkSuspend} ({selectedIds.length})
            </button>
          )}
        </form>
      </div>

      {error && (
        <div
          className="p-3 rounded-xl border text-sm"
          style={{ backgroundColor: "var(--danger-soft)", borderColor: "var(--danger)", color: "var(--danger)" }}
        >
          {error}
        </div>
      )}

      <div
        className="rounded-2xl border overflow-x-auto"
        style={{ backgroundColor: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
      >
        <table className="w-full text-sm text-left">
          <thead>
            <tr className="border-b" style={{ borderColor: "var(--border-subtle)", color: "var(--text-secondary)" }}>
              <th className="p-3 w-10"></th>
              <th className="p-3">{dict.users.email}</th>
              <th className="p-3">{dict.users.name}</th>
              <th className="p-3">{dict.common.status}</th>
              <th className="p-3">{dict.users.role}</th>
              <th className="p-3">{dict.common.actions}</th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id} className="border-b last:border-0" style={{ borderColor: "var(--border-subtle)" }}>
                <td className="p-3">
                  <input
                    type="checkbox"
                    checked={!!selected[u.id]}
                    onChange={(e) => setSelected((prev) => ({ ...prev, [u.id]: e.target.checked }))}
                  />
                </td>
                <td className="p-3 font-medium">
                  <Link to={`/users/${u.id}`} style={{ color: "var(--brand)" }}>
                    {u.email}
                  </Link>
                </td>
                <td className="p-3">{u.full_name || "—"}</td>
                <td className="p-3">
                  <span
                    className="px-2 py-0.5 rounded-lg text-xs font-semibold"
                    style={{
                      backgroundColor: u.is_active ? "var(--success-soft)" : "var(--danger-soft)",
                      color: u.is_active ? "var(--success)" : "var(--danger)",
                    }}
                  >
                    {u.is_active ? dict.common.active : dict.common.inactive}
                  </span>
                </td>
                <td className="p-3">
                  {u.is_admin ? (
                    <span className="inline-flex items-center gap-1 text-xs font-semibold" style={{ color: "var(--accent)" }}>
                      <Shield className="w-3.5 h-3.5" /> Admin
                    </span>
                  ) : (
                    <span className="text-xs" style={{ color: "var(--text-secondary)" }}>
                      Student
                    </span>
                  )}
                </td>
                <td className="p-3 flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => toggleActive(u.id)}
                    className="px-2.5 py-1 rounded-lg text-xs border cursor-pointer inline-flex items-center gap-1"
                    style={{ borderColor: "var(--border-subtle)" }}
                  >
                    {u.is_active ? <UserX className="w-3.5 h-3.5" /> : <UserCheck className="w-3.5 h-3.5" />}
                    <span>{u.is_active ? dict.users.suspend : dict.users.unsuspend}</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => promoteUser(u.id)}
                    className="px-2.5 py-1 rounded-lg text-xs border cursor-pointer"
                    style={{ borderColor: "var(--border-subtle)", color: "var(--brand)" }}
                  >
                    {dict.users.promote}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
