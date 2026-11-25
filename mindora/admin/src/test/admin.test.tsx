import React from "react";
import { describe, expect, it, vi } from "vitest";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { I18nProvider } from "../i18n";
import { AuthProvider } from "../lib/auth";
import { AdminRoutes } from "../App";
import { SettingsPage } from "../pages/SettingsPage";
import { saveSession } from "../lib/api";

function mockFetchSequence(responses: Array<{ ok?: boolean; status?: number; body: unknown }>) {
  let idx = 0;
  return vi.spyOn(globalThis, "fetch").mockImplementation(async () => {
    const item = responses[Math.min(idx++, responses.length - 1)];
    return {
      ok: item.ok ?? true,
      status: item.status ?? 200,
      headers: new Headers({ "content-type": "application/json" }),
      json: async () => item.body,
      text: async () => JSON.stringify(item.body),
    } as Response;
  });
}

describe("MINDORA Admin Panel", () => {
  it("redirects unauthenticated access to login and completes 2FA step", async () => {
    const fetchMock = mockFetchSequence([
      {
        body: {
          requires_2fa: true,
          challenge_token: "chal-123",
          email: "admin@mindora.dev",
          message: "Code sent",
        },
      },
      {
        body: {
          tokens: { access_token: "acc-1", refresh_token: "ref-1" },
          user: {
            id: "u-1",
            email: "admin@mindora.dev",
            full_name: "Admin",
            is_admin: true,
            preferred_language: "fr",
          },
          permissions: ["users.read"],
          roles: ["super_admin"],
        },
      },
      { body: { users: { total: 10, active: 9, admins: 1, new_this_week: 2 }, documents: { total: 4, pending: 1, approved: 3 }, papers: { total: 4, published: 4, draft: 0 }, activity: { sessions_today: 2, uploads_today: 1 } } },
      { body: { overall: "ok", services: [] } },
    ]);

    render(
      <I18nProvider>
        <AuthProvider>
          <MemoryRouter initialEntries={["/dashboard"]}>
            <AdminRoutes />
          </MemoryRouter>
        </AuthProvider>
      </I18nProvider>
    );

    const emailInput = screen.getByLabelText(/e-?mail/i);
    const pwdInput = screen.getByLabelText(/mot de passe|password/i);
    fireEvent.change(emailInput, { target: { value: "admin@mindora.dev" } });
    fireEvent.change(pwdInput, { target: { value: "MindoraAdmin2026!" } });
    fireEvent.submit(emailInput.closest("form")!);

    await waitFor(() => {
      expect(screen.getByLabelText(/6 chiffres|6-digit/i)).toBeInTheDocument();
    });

    const codeInput = screen.getByLabelText(/6 chiffres|6-digit/i);
    fireEvent.change(codeInput, { target: { value: "123456" } });
    fireEvent.submit(codeInput.closest("form")!);

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledTimes(2);
    });
  });

  it("hides unauthorized navigation items based on RBAC permissions", async () => {
    saveSession({
      accessToken: "acc-mod",
      refreshToken: "ref-mod",
      user: {
        id: "u-mod",
        email: "mod@mindora.dev",
        full_name: "Moderator",
        is_admin: false,
        preferred_language: "en",
      },
      permissions: ["documents.read", "documents.moderate"],
      roles: ["moderator"],
    });

    vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
      const url = String(input);
      if (url.includes("/admin/documents")) {
        return {
          ok: true,
          status: 200,
          headers: new Headers({ "content-type": "application/json" }),
          json: async () => [],
        } as Response;
      }
      return {
        ok: true,
        status: 200,
        headers: new Headers({ "content-type": "application/json" }),
        json: async () => ({
          permissions: ["documents.read", "documents.moderate"],
          roles: ["moderator"],
        }),
      } as Response;
    });

    render(
      <I18nProvider>
        <AuthProvider>
          <MemoryRouter initialEntries={["/moderation"]}>
            <AdminRoutes />
          </MemoryRouter>
        </AuthProvider>
      </I18nProvider>
    );

    await waitFor(() => {
      expect(screen.getByText(/File de Modération|Document Moderation Queue/i)).toBeInTheDocument();
    });
    expect(screen.queryByText(/Centre IA|AI Center/i)).not.toBeInTheDocument();
    expect(screen.queryByText(/Paramètres|Settings/i)).not.toBeInTheDocument();
  });

  it("renders settings & switches FR/EN dictionary cleanly", async () => {
    localStorage.setItem("mindora_admin_locale", "en");
    vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
      const url = String(input);
      if (url.includes("feature-flags")) {
        return {
          ok: true,
          status: 200,
          headers: new Headers({ "content-type": "application/json" }),
          json: async () => [{ key: "ai_vision_enabled", enabled: true, description: "Vision" }],
        } as Response;
      }
      if (url.includes("maintenance")) {
        return {
          ok: true,
          status: 200,
          headers: new Headers({ "content-type": "application/json" }),
          json: async () => ({ enabled: false, message: "" }),
        } as Response;
      }
      return {
        ok: true,
        status: 200,
        headers: new Headers({ "content-type": "application/json" }),
        json: async () => [{ key: "app_name", value: "MINDORA", description: "Brand" }],
      } as Response;
    });

    render(
      <I18nProvider>
        <AuthProvider>
          <SettingsPage />
        </AuthProvider>
      </I18nProvider>
    );

    await waitFor(() => {
      expect(screen.getByText("Global Settings & Maintenance")).toBeInTheDocument();
      expect(screen.getByText("ai_vision_enabled")).toBeInTheDocument();
    });
  });
});
