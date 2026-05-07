"use client";

import { useEffect, useMemo, useState } from "react";
import { JobCard } from "@/components/JobCard";
import { apiJson } from "@/lib/api";
import type { JobPosition, SalesforceApiResponse } from "@/lib/types";

const departments = ["", "Engineering", "Marketing", "Sales", "HR", "Finance", "Operations"];
const types = ["", "Full-Time", "Part-Time", "Contract", "Internship"];

export function JobsClient() {
  const [jobs, setJobs] = useState<JobPosition[]>([]);
  const [department, setDepartment] = useState("");
  const [type, setType] = useState("");
  const [remote, setRemote] = useState(false);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    const controller = new AbortController();
    async function load() {
      setLoading(true);
      setError("");
      const params = new URLSearchParams();
      if (department) params.set("department", department);
      if (type) params.set("type", type);
      if (remote) params.set("remote", "true");
      try {
        const response = await apiJson<SalesforceApiResponse<JobPosition[]>>(`/api/sf/jobs?${params.toString()}`, {
          signal: controller.signal
        });
        setJobs(response.data || []);
      } catch (err) {
        if (!controller.signal.aborted) setError(err instanceof Error ? err.message : "İlanlar alınamadı");
      } finally {
        if (!controller.signal.aborted) setLoading(false);
      }
    }
    load();
    return () => controller.abort();
  }, [department, type, remote]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return jobs;
    return jobs.filter((job) => [job.title, job.department, job.location, job.description, job.requirements].filter(Boolean).join(" ").toLowerCase().includes(q));
  }, [jobs, search]);

  return (
    <section className="container-page py-10">
      <div className="rounded-[2rem] border border-slate-200 bg-white/85 p-5 shadow-soft">
        <div className="grid gap-3 md:grid-cols-[1fr_180px_180px_auto]">
          <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Pozisyon, lokasyon veya yetenek ara" className="rounded-2xl border border-slate-200 px-4 py-3 text-sm" />
          <select value={department} onChange={(event) => setDepartment(event.target.value)} className="rounded-2xl border border-slate-200 px-4 py-3 text-sm">
            {departments.map((item) => <option key={item} value={item}>{item || "Tüm departmanlar"}</option>)}
          </select>
          <select value={type} onChange={(event) => setType(event.target.value)} className="rounded-2xl border border-slate-200 px-4 py-3 text-sm">
            {types.map((item) => <option key={item} value={item}>{item || "Tüm çalışma tipleri"}</option>)}
          </select>
          <label className="flex items-center gap-2 rounded-2xl border border-slate-200 px-4 py-3 text-sm font-semibold text-slate-700">
            <input type="checkbox" checked={remote} onChange={(event) => setRemote(event.target.checked)} /> Remote
          </label>
        </div>
      </div>

      {loading ? <p className="mt-8 text-slate-600">İlanlar yükleniyor…</p> : null}
      {error ? <p className="mt-8 rounded-2xl bg-red-50 p-4 text-sm font-semibold text-red-700">{error}</p> : null}
      {!loading && !error ? (
        <div className="mt-8 grid gap-5 md:grid-cols-2 lg:grid-cols-3">
          {filtered.map((job) => <JobCard key={job.id} job={job} />)}
        </div>
      ) : null}
      {!loading && !error && filtered.length === 0 ? <p className="mt-8 text-slate-600">Uygun ilan bulunamadı.</p> : null}
    </section>
  );
}
