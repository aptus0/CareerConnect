export function formatDate(value?: string) {
  if (!value) return "Tarih yok";
  return new Intl.DateTimeFormat("tr-TR", { dateStyle: "medium" }).format(new Date(value));
}

export function compactText(value?: string, max = 180) {
  if (!value) return "";
  return value.length > max ? `${value.slice(0, max).trim()}…` : value;
}
