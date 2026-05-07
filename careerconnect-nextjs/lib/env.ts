const required = [
  "SALESFORCE_LOGIN_URL",
  "SALESFORCE_CLIENT_ID",
  "SALESFORCE_CLIENT_SECRET"
] as const;

export function getEnv(name: (typeof required)[number] | "SF_API_VERSION" | "REED_API_KEY") {
  const value = process.env[name];
  if (!value && required.includes(name as (typeof required)[number])) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function getSfApiVersion() {
  return process.env.SF_API_VERSION || "v59.0";
}
