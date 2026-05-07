import { getEnv } from "@/lib/env";

export type SalesforceToken = {
  access_token: string;
  instance_url: string;
  token_type: string;
  issued_at?: string;
  signature?: string;
};

type Cache = {
  token?: SalesforceToken;
  expiresAt: number;
};

const tokenCache: Cache = {
  expiresAt: 0
};

function normalizeLoginUrl(url: string) {
  return url.replace(/\/$/, "");
}

export async function getSalesforceToken(): Promise<SalesforceToken> {
  const now = Date.now();
  if (tokenCache.token && tokenCache.expiresAt > now + 60_000) {
    return tokenCache.token;
  }

  const loginUrl = normalizeLoginUrl(getEnv("SALESFORCE_LOGIN_URL")!);
  const body = new URLSearchParams({
    grant_type: "client_credentials",
    client_id: getEnv("SALESFORCE_CLIENT_ID")!,
    client_secret: getEnv("SALESFORCE_CLIENT_SECRET")!
  });

  const response = await fetch(`${loginUrl}/services/oauth2/token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
    cache: "no-store"
  });

  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(
      `Salesforce OAuth failed (${response.status}): ${payload.error_description || payload.error || "Unknown error"}`
    );
  }

  tokenCache.token = payload as SalesforceToken;
  tokenCache.expiresAt = now + 100 * 60 * 1000;
  return tokenCache.token;
}

export async function salesforceApex<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = await getSalesforceToken();
  const normalizedPath = path.startsWith("/services/")
    ? path
    : `/services/apexrest${path.startsWith("/") ? path : `/${path}`}`;

  const headers = new Headers(init.headers);
  headers.set("Authorization", `Bearer ${token.access_token}`);
  headers.set("Accept", "application/json");
  if (init.body && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }

  const response = await fetch(`${token.instance_url}${normalizedPath}`, {
    ...init,
    headers,
    cache: "no-store"
  });

  const text = await response.text();
  const data = text ? JSON.parse(text) : null;

  if (!response.ok) {
    const message = data?.message || data?.[0]?.message || response.statusText;
    throw new Error(`Salesforce API failed (${response.status}): ${message}`);
  }

  return data as T;
}
