import React from "react";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { I18nProvider } from "./i18n";
import { AuthProvider, useAuth } from "./lib/auth";
import { AdminLayout } from "./components/AdminLayout";
import { LoginPage } from "./pages/LoginPage";
import { DashboardPage } from "./pages/DashboardPage";
import { AnalyticsPage } from "./pages/AnalyticsPage";
import { UsersPage } from "./pages/UsersPage";
import { UserDetailPage } from "./pages/UserDetailPage";
import { PapersPage } from "./pages/PapersPage";
import { ModerationPage } from "./pages/ModerationPage";
import { AiCenterPage } from "./pages/AiCenterPage";
import { ContentPage } from "./pages/ContentPage";
import { BroadcastsPage } from "./pages/BroadcastsPage";
import { SupportPage } from "./pages/SupportPage";
import { SecurityPage } from "./pages/SecurityPage";
import { SessionsPage } from "./pages/SessionsPage";
import { SettingsPage } from "./pages/SettingsPage";

function RequireAuth({ children }: { children: React.ReactElement }) {
  const { session } = useAuth();
  if (!session?.accessToken) {
    return <Navigate to="/login" replace />;
  }
  return children;
}

export function AdminRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        path="/"
        element={
          <RequireAuth>
            <AdminLayout />
          </RequireAuth>
        }
      >
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="dashboard" element={<DashboardPage />} />
        <Route path="analytics" element={<AnalyticsPage />} />
        <Route path="users" element={<UsersPage />} />
        <Route path="users/:id" element={<UserDetailPage />} />
        <Route path="papers" element={<PapersPage />} />
        <Route path="moderation" element={<ModerationPage />} />
        <Route path="ai" element={<AiCenterPage />} />
        <Route path="content" element={<ContentPage />} />
        <Route path="broadcasts" element={<BroadcastsPage />} />
        <Route path="support" element={<SupportPage />} />
        <Route path="security" element={<SecurityPage />} />
        <Route path="sessions" element={<SessionsPage />} />
        <Route path="settings" element={<SettingsPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}

export function App() {
  const base = (import.meta.env.BASE_URL || "/").replace(/\/+$/, "") || "/";
  return (
    <I18nProvider>
      <AuthProvider>
        <BrowserRouter basename={base}>
          <AdminRoutes />
        </BrowserRouter>
      </AuthProvider>
    </I18nProvider>
  );
}
