import React, { createContext, useContext, useEffect, useState } from "react";
import {
  apiRequest,
  loadSession,
  saveSession,
  StoredAdminSession,
} from "./api";

interface AuthContextValue {
  session: StoredAdminSession | null;
  hasPermission: (perm: string) => boolean;
  startAdminLogin: (email: string, password: string) => Promise<{
    challengeToken: string;
    email: string;
    message: string;
  }>;
  verifyTwoFactor: (challengeToken: string, code: string) => Promise<void>;
  resendTwoFactor: (challengeToken: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<StoredAdminSession | null>(() => loadSession());

  useEffect(() => {
    if (!session?.accessToken) return;
    apiRequest<{ permissions: string[]; roles: string[] }>("/auth/admin/permissions")
      .then((res) => {
        const updated: StoredAdminSession = {
          ...session,
          permissions: res.permissions,
          roles: res.roles,
        };
        saveSession(updated);
        setSession(updated);
      })
      .catch(() => {
        // handled by interceptor if invalid
      });
  }, []);

  const hasPermission = (perm: string) => {
    if (!session) return false;
    if (session.user.is_admin) return true;
    return session.permissions.includes(perm);
  };

  const startAdminLogin = async (email: string, password: string) => {
    const res = await apiRequest<{
      requires_2fa: boolean;
      challenge_token: string;
      email: string;
      message: string;
    }>("/auth/admin/login", {
      method: "POST",
      skipAuth: true,
      body: JSON.stringify({ email, password }),
    });
    return {
      challengeToken: res.challenge_token,
      email: res.email,
      message: res.message,
    };
  };

  const verifyTwoFactor = async (challengeToken: string, code: string) => {
    const res = await apiRequest<{
      tokens: { access_token: string; refresh_token: string };
      user: StoredAdminSession["user"];
      permissions: string[];
      roles: string[];
    }>("/auth/admin/2fa/verify", {
      method: "POST",
      skipAuth: true,
      body: JSON.stringify({ challenge_token: challengeToken, code }),
    });
    const next: StoredAdminSession = {
      accessToken: res.tokens.access_token,
      refreshToken: res.tokens.refresh_token,
      user: res.user,
      permissions: res.permissions,
      roles: res.roles,
    };
    saveSession(next);
    setSession(next);
  };

  const resendTwoFactor = async (challengeToken: string) => {
    await apiRequest("/auth/admin/2fa/resend", {
      method: "POST",
      skipAuth: true,
      body: JSON.stringify({ challenge_token: challengeToken }),
    });
  };

  const logout = async () => {
    const current = loadSession();
    if (current?.refreshToken) {
      try {
        await apiRequest("/auth/logout", {
          method: "POST",
          skipAuth: true,
          body: JSON.stringify({ refresh_token: current.refreshToken }),
        });
      } catch {
        // ignore network error on sign out
      }
    }
    saveSession(null);
    setSession(null);
  };

  return React.createElement(
    AuthContext.Provider,
    {
      value: {
        session,
        hasPermission,
        startAdminLogin,
        verifyTwoFactor,
        resendTwoFactor,
        logout,
      },
    },
    children
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used inside AuthProvider");
  return ctx;
}
