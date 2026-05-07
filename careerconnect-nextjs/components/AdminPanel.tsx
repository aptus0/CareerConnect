"use client";

import { FormEvent, useState } from "react";
import { apiJson } from "@/lib/api";
import type { SalesforceApiResponse } from "@/lib/types";

export function AdminPanel() {
  const [syncMessage, setSyncMessage] = useState("");
  const [creating, setCreating] = useState(false);

  async function createJob(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setCreating(true);
    setSyncMessage("");
    const form = new FormData(event.currentTarget);
    const body = {
      title: String(form.get("title") || ""),
      department: String(form.get("department") || "Engineering"),
      location: String(form.get("location") || "Remote"),
      employmentType: String(form.get("employmentType") || "Full-Time"),
      salaryRange: String(form.get("salaryRange") || ""),
      description: String(form.get("description") || ""),
      requirements: String(form.get("requirements") || ""),
      status: "Open",
      remoteEligible: form.get("remoteEligible") === "on",
      maxApplicants: Number(form.get("maxApplicants") || 0) || undefined
    };

    try {
      const response = await apiJson<SalesforceApiResponse<string>>("/api/sf/jobs", {
        method: "POST",
        body: JSON.stringify(body)
      });
      setSyncMessage(response.message || "İlan oluşturuldu");
      event.currentTarget.reset();
    } catch (error) {
      setSyncMessage(error instanceof Error ? error.message : "İlan oluşturulamadı");
    } finally {
      setCreating(false);
    }
  }

  async function syncExternalJobs() {
    setSyncMessage("Dış API senkronizasyonu başlatılıyor…");
    try {
      const response = await apiJson<SalesforceApiResponse<Record<string, number>>>("/api/sf/external-sync", {
        method: "POST",
        body: JSON.stringify({ keywords: "software", location: "London" })
      });
      const stats = response.data || {};
      setSyncMessage(`Sync tamamlandı. Insert: ${stats.inserted || 0}, Update: ${stats.updated || 0}, Error: ${stats.errors || 0}`);
    } catch (error) {
      setSyncMessage(error instanceof Error ? error.message : "Sync başarısız");
    }
  }

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_360px]">
      <form onSubmit={createJob} className="grid gap-4 rounded-[2rem] border border-slate-200 bg-white p-6 shadow-soft">
        <h2 className="text-2xl font-black text-slate-950">Yeni Pozisyon Oluştur</h2>
        <div className="grid gap-4 md:grid-cols-2">
          <input name="title" required placeholder="Pozisyon adı" className="rounded-2xl border border-slate-200 px-4 py-3" />
          <select name="department" className="rounded-2xl border border-slate-200 px-4 py-3">
            {['Engineering', 'Marketing', 'Sales', 'HR', 'Finance', 'Operations'].map((d) => <option key={d}>{d}</option>)}
          </select>
          <input name="location" placeholder="Lokasyon" className="rounded-2xl border border-slate-200 px-4 py-3" />
          <select name="employmentType" className="rounded-2xl border border-slate-200 px-4 py-3">
            {['Full-Time', 'Part-Time', 'Contract', 'Internship'].map((d) => <option key={d}>{d}</option>)}
          </select>
          <input name="salaryRange" placeholder="Maaş aralığı" className="rounded-2xl border border-slate-200 px-4 py-3" />
          <input name="maxApplicants" type="number" min="1" placeholder="Maksimum aday" className="rounded-2xl border border-slate-200 px-4 py-3" />
        </div>
        <textarea name="description" rows={5} placeholder="Açıklama" className="rounded-2xl border border-slate-200 px-4 py-3" />
        <textarea name="requirements" rows={5} placeholder="Gereksinimler" className="rounded-2xl border border-slate-200 px-4 py-3" />
        <label className="flex items-center gap-2 text-sm font-semibold text-slate-700"><input name="remoteEligible" type="checkbox" /> Remote uygun</label>
        <button disabled={creating} className="rounded-full bg-slate-950 px-6 py-3 font-bold text-white disabled:opacity-60">{creating ? "Oluşturuluyor…" : "Salesforce’a Kaydet"}</button>
      </form>
      <aside className="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-soft">
        <h2 className="text-2xl font-black text-slate-950">Dış API</h2>
        <p className="mt-3 text-sm leading-6 text-slate-600">Bu buton Next.js API route → Salesforce Apex REST → Named Credential ExternalJobAPI zincirini çalıştırır.</p>
        <button onClick={syncExternalJobs} className="mt-5 rounded-full bg-sky-700 px-6 py-3 font-bold text-white hover:bg-sky-800">Reed API Sync</button>
        {syncMessage ? <p className="mt-5 rounded-2xl bg-slate-50 p-4 text-sm font-semibold text-slate-700">{syncMessage}</p> : null}
      </aside>
    </div>
  );
}
