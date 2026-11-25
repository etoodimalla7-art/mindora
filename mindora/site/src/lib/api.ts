export function getApiBaseUrl(): string {
  const envUrl = (import.meta.env.VITE_API_BASE_URL as string | undefined)?.trim();
  if (envUrl) return envUrl.replace(/\/+$/, "");
  if (typeof window !== "undefined") {
    return `${window.location.origin}/api/v1`;
  }
  return "/api/v1";
}

export interface PublicSettings {
  identity: {
    name?: string;
    tagline?: string;
    primary_color?: string;
  };
  education_systems: string[];
  subjects: string[];
  levels: string[];
  maintenance: {
    enabled: boolean;
    message: string;
  };
  flags: Record<string, boolean>;
}

export interface PublicPlan {
  id: string;
  code: string;
  name: string;
  description?: string | null;
  tier?: string;
  amount_minor: number;
  currency: string;
  billing_cycle: string;
  features: string[] | Record<string, unknown>;
}

export async function fetchPublicSettings(): Promise<PublicSettings | null> {
  try {
    const res = await fetch(`${getApiBaseUrl()}/settings/public`);
    if (!res.ok) return null;
    return (await res.json()) as PublicSettings;
  } catch {
    return null;
  }
}

export async function fetchPublicPlans(): Promise<PublicPlan[]> {
  try {
    const res = await fetch(`${getApiBaseUrl()}/subscriptions/plans/public`);
    if (!res.ok) return [];
    const data = await res.json();
    return Array.isArray(data) ? (data as PublicPlan[]) : [];
  } catch {
    return [];
  }
}

export async function submitContact(payload: {
  name: string;
  email: string;
  category: string;
  subject: string;
  message: string;
}): Promise<{ ticket_id: string; status: string; message: string }> {
  const res = await fetch(`${getApiBaseUrl()}/support/contact`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    let errMsg = `HTTP ${res.status}`;
    try {
      const json = await res.json();
      errMsg = json?.error?.message || json?.detail || errMsg;
    } catch {
      // ignore non-json
    }
    throw new Error(errMsg);
  }
  return (await res.json()) as { ticket_id: string; status: string; message: string };
}
