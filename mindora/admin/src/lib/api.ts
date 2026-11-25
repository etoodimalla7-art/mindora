export function getApiBaseUrl(): string {
  const envUrl = (import.meta.env.VITE_API_BASE_URL as string | undefined)?.trim();
  if (envUrl) return envUrl.replace(/\/+$/, "");
  if (typeof window !== "undefined") {
    return `${window.location.origin}/api/v1`;
  }
  return "/api/v1";
}

export function getWsBaseUrl(): string {
  const api = getApiBaseUrl();
  if (api.startsWith("https://")) return `wss://${api.slice(8)}`;
  if (api.startsWith("http://")) return `ws://${api.slice(7)}`;
  if (typeof window !== "undefined") {
    const proto = window.location.protocol === "https:" ? "wss:" : "ws:";
    return `${proto}//${window.location.host}${api}`;
  }
  return api;
}

export interface StoredAdminSession {
  accessToken: string;
  refreshToken: string;
  user: {
    id: string;
    email: string;
    full_name: string | null;
    is_admin: boolean;
    preferred_language: string;
  };
  permissions: string[];
  roles: string[];
}

const SESSION_KEY = "mindora_admin_session_v1";

export function loadSession(): StoredAdminSession | null {
  try {
    const raw = localStorage.getItem(SESSION_KEY);
    return raw ? (JSON.parse(raw) as StoredAdminSession) : null;
  } catch {
    return null;
  }
}

export function saveSession(session: StoredAdminSession | null): void {
  if (!session) {
    localStorage.removeItem(SESSION_KEY);
  } else {
    localStorage.setItem(SESSION_KEY, JSON.stringify(session));
  }
}

export class ApiError extends Error {
  status: number;
  code: string;
  constructor(status: number, code: string, message: string) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

let refreshingPromise: Promise<StoredAdminSession | null> | null = null;

async function tryRefreshSession(): Promise<StoredAdminSession | null> {
  const current = loadSession();
  if (!current?.refreshToken) return null;
  if (!refreshingPromise) {
    refreshingPromise = (async () => {
      try {
        const res = await fetch(`${getApiBaseUrl()}/auth/refresh`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ refresh_token: current.refreshToken }),
        });
        if (!res.ok) {
          saveSession(null);
          return null;
        }
        const data = await res.json();
        const updated: StoredAdminSession = {
          ...current,
          accessToken: data.tokens.access_token,
          refreshToken: data.tokens.refresh_token,
          user: data.user,
        };
        saveSession(updated);
        return updated;
      } catch {
        return null;
      } finally {
        refreshingPromise = null;
      }
    })();
  }
  return refreshingPromise;
}

export async function apiRequest<T>(
  path: string,
  options: RequestInit & { skipAuth?: boolean } = {}
): Promise<T> {
  const { skipAuth, headers, ...rest } = options;
  const session = loadSession();
  const reqHeaders = new Headers(headers || {});

  if (!reqHeaders.has("Content-Type") && !(rest.body instanceof FormData)) {
    reqHeaders.set("Content-Type", "application/json");
  }
  if (!skipAuth && session?.accessToken) {
    reqHeaders.set("Authorization", `Bearer ${session.accessToken}`);
  }

  let res = await fetch(`${getApiBaseUrl()}${path}`, {
    ...rest,
    headers: reqHeaders,
  });

  if (res.status === 401 && !skipAuth && session?.refreshToken) {
    const refreshed = await tryRefreshSession();
    if (refreshed?.accessToken) {
      reqHeaders.set("Authorization", `Bearer ${refreshed.accessToken}`);
      res = await fetch(`${getApiBaseUrl()}${path}`, {
        ...rest,
        headers: reqHeaders,
      });
    }
  }

  if (!res.ok) {
    let errCode = "http_error";
    let errMsg = `HTTP ${res.status}`;
    try {
      const json = await res.json();
      if (json?.error) {
        errCode = json.error.code || errCode;
        errMsg = json.error.message || errMsg;
      } else if (json?.detail) {
        errMsg = typeof json.detail === "string" ? json.detail : JSON.stringify(json.detail);
      }
    } catch {
      // ignore non-json error body
    }
    throw new ApiError(res.status, errCode, errMsg);
  }

  if (res.status === 204) {
    return undefined as T;
  }

  const contentType = res.headers.get("content-type") || "";
  if (contentType.includes("application/json")) {
    return (await res.json()) as T;
  }
  return (await res.text()) as unknown as T;
}

export async function apiDownloadBlob(path: string): Promise<Blob> {
  const session = loadSession();
  const headers: Record<string, string> = {};
  if (session?.accessToken) {
    headers.Authorization = `Bearer ${session.accessToken}`;
  }
  const res = await fetch(`${getApiBaseUrl()}${path}`, { headers });
  if (!res.ok) {
    throw new ApiError(res.status, "download_failed", `HTTP ${res.status}`);
  }
  return res.blob();
}
