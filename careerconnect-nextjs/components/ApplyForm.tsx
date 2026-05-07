"use client";

import { FormEvent, useState } from "react";
import { apiJson } from "@/lib/api";
import type { SalesforceApiResponse } from "@/lib/types";

export function ApplyForm({ jobId }: { jobId: string }) {
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [message, setMessage] = useState("");

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setStatus("loading");
    setMessage("");
    const form = new FormData(event.currentTarget);
    const body = {
      jobPositionId: jobId,
      email: String(form.get("email") || ""),
      phone: String(form.get("phone") || ""),
      linkedInUrl: String(form.get("linkedInUrl") || ""),
      yearsOfExperience: Number(form.get("yearsOfExperience") || 0),
      expectedSalary: Number(form.get("expectedSalary") || 0),
      coverLetter: String(form.get("coverLetter") || "")
    };

    try {
      const response = await apiJson<SalesforceApiResponse<string>>("/api/sf/apply", {
        method: "POST",
        body: JSON.stringify(body)
      });
      setStatus("success");
      setMessage(response.message || "Başvurun başarıyla alındı.");
      event.currentTarget.reset();
    } catch (error) {
      setStatus("error");
      setMessage(error instanceof Error ? error.message : "Başvuru gönderilemedi");
    }
  }

  return (
    <form onSubmit={submit} className="grid gap-4 rounded-[2rem] border border-slate-200 bg-white p-6 shadow-soft">
      <h2 className="text-2xl font-black text-slate-950">Başvuru Formu</h2>
      <div className="grid gap-4 md:grid-cols-2">
        <input name="email" required type="email" placeholder="E-posta" className="rounded-2xl border border-slate-200 px-4 py-3" />
        <input name="phone" placeholder="Telefon" className="rounded-2xl border border-slate-200 px-4 py-3" />
        <input name="linkedInUrl" type="url" placeholder="LinkedIn URL" className="rounded-2xl border border-slate-200 px-4 py-3" />
        <input name="yearsOfExperience" type="number" min="0" max="80" placeholder="Deneyim yılı" className="rounded-2xl border border-slate-200 px-4 py-3" />
        <input name="expectedSalary" type="number" min="0" placeholder="Beklenen maaş" className="rounded-2xl border border-slate-200 px-4 py-3 md:col-span-2" />
      </div>
      <textarea name="coverLetter" rows={7} placeholder="Ön yazı" className="rounded-2xl border border-slate-200 px-4 py-3" />
      <button disabled={status === "loading"} className="rounded-full bg-sky-700 px-6 py-3 font-bold text-white hover:bg-sky-800 disabled:cursor-not-allowed disabled:opacity-60">
        {status === "loading" ? "Gönderiliyor…" : "Başvuruyu Gönder"}
      </button>
      {message ? (
        <p className={`rounded-2xl p-4 text-sm font-semibold ${status === "error" ? "bg-red-50 text-red-700" : "bg-emerald-50 text-emerald-700"}`}>{message}</p>
      ) : null}
    </form>
  );
}
