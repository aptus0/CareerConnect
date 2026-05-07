import Link from "next/link";
import { compactText, formatDate } from "@/lib/format";
import type { JobPosition } from "@/lib/types";

export function JobCard({ job }: { job: JobPosition }) {
  return (
    <article className="rounded-3xl border border-slate-200 bg-white p-6 shadow-soft transition hover:-translate-y-1 hover:shadow-lg">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-sm font-semibold text-sky-700">{job.department || "Genel"}</p>
          <h3 className="mt-1 text-xl font-black text-slate-950">{job.title}</h3>
        </div>
        {job.remoteEligible ? (
          <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-bold text-emerald-700">Remote</span>
        ) : null}
      </div>
      <div className="mt-4 flex flex-wrap gap-2 text-xs font-semibold text-slate-600">
        <span className="rounded-full bg-slate-100 px-3 py-1">{job.location || "Konum yok"}</span>
        <span className="rounded-full bg-slate-100 px-3 py-1">{job.employmentType || "Tip yok"}</span>
        <span className="rounded-full bg-slate-100 px-3 py-1">Son: {formatDate(job.deadline)}</span>
      </div>
      <p className="mt-4 min-h-14 text-sm leading-6 text-slate-600">{compactText(job.description)}</p>
      <div className="mt-6 flex items-center justify-between gap-4">
        <span className="text-sm font-bold text-slate-800">{job.salaryRange || "Maaş belirtilmedi"}</span>
        <Link href={`/jobs/${job.id}`} className="rounded-full bg-slate-950 px-4 py-2 text-sm font-bold text-white hover:bg-slate-800">
          Detay
        </Link>
      </div>
    </article>
  );
}
