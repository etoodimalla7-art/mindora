import React from "react";
import { describe, expect, it, vi } from "vitest";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { I18nProvider } from "../i18n";
import { SiteRoutes } from "../App";

describe("MINDORA Public Site", () => {
  it("renders hero APK download, Play Store badge, and admin footer link", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ identity: { name: "MINDORA" }, maintenance: { enabled: false, message: "" } }),
    } as Response);

    render(
      <I18nProvider>
        <MemoryRouter initialEntries={["/"]}>
          <SiteRoutes />
        </MemoryRouter>
      </I18nProvider>
    );

    expect(screen.getByText(/Télécharger l'APK Android/i)).toBeInTheDocument();
    expect(screen.getAllByText(/Google Play/i).length).toBeGreaterThan(0);
    const adminLink = screen.getByRole("link", { name: /Administration|Admin Portal/i });
    expect(adminLink).toHaveAttribute("href", "/admin/");
  });

  it("submits live contact form to /api/v1/support/contact", async () => {
    const fetchMock = vi.spyOn(globalThis, "fetch").mockResolvedValue({
      ok: true,
      status: 201,
      json: async () => ({
        ticket_id: "t-999",
        status: "open",
        message: "Received",
      }),
    } as Response);

    render(
      <I18nProvider>
        <MemoryRouter initialEntries={["/contact"]}>
          <SiteRoutes />
        </MemoryRouter>
      </I18nProvider>
    );

    fireEvent.change(screen.getByLabelText(/Nom complet|Full name/i), {
      target: { value: "Amadou Bello" },
    });
    fireEvent.change(screen.getByLabelText(/Adresse e-mail|Email address/i), {
      target: { value: "amadou@example.cm" },
    });
    fireEvent.change(screen.getByLabelText(/Objet|Subject/i), {
      target: { value: "Question GCE A-Level" },
    });
    fireEvent.change(screen.getByLabelText(/Ton message|Your message/i), {
      target: { value: "Bonjour, comment activer les examens blancs ?" },
    });

    fireEvent.submit(screen.getByRole("button", { name: /Envoyer|Send/i }).closest("form")!);

    await waitFor(() => {
      expect(screen.getByText(/t-999/)).toBeInTheDocument();
    });
    expect(fetchMock).toHaveBeenCalledWith(
      expect.stringContaining("/support/contact"),
      expect.objectContaining({ method: "POST" })
    );
  });
});
