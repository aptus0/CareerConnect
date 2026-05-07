import Link from "next/link";
import { salesforceApex } from "@/lib/salesforce";
import { formatDate } from "@/lib/format";
import type { JobPosition, SalesforceApiResponse } from "@/lib/types";

export default async function JobDetailPage({ params }: { params: Promise<{ id: string }> | { id: string } }) {
  const { id } = await params;
  const response = await salesforceApex<SalesforceApiResponse<JobPosition>>(`/careers/jobs/${id}`);
  const job = response.data;

  return (
    <main className="container-page py-12">
      <Link href="/jobs" className="text-sm font-bold text-sky-700">← İlanlara dön</Link>
      <section className="mt-6 grid gap-6 lg:grid-cols-[1fr_320px]">
        <article className="rounded-[2rem] border border-slate-200 bg-white p-8 shadow-soft">
          <p className="font-bold text-sky-700">{job.department}</p>
          <h1 className="mt-2 text-4xl font-black text-slate-950">{job.title}</h1>
          <div className="mt-5 flex flex-wrap gap-2 text-sm font-semibold text-slate-600">
            <span className="rounded-full bg-slate-100 px-4 py-2">{job.location}</span>
            <span className="rounded-full bg-slate-100 px-4 py-2">{job.employmentType}</span>
            <span className="rounded-full bg-slate-100 px-4 py-2">{job.remoteEligible ? "Remote uygun" : "Ofis/Lokasyon"}</span>
            <span className="rounded-full bg-slate-100 px-4 py-2">Son tarih: {formatDate(job.deadline)}</span>
          </div>
          <h2 className="mt-8 text-2xl font-black">Açıklama</h2>
          <p className="mt-3 whitespace-pre-wrap leading-8 text-slate-600">{job.description || "Açıklama girilmemiş."}</p>
          <h2 className="mt-8 text-2xl font-black">Gereksinimler</h2>
          <p className="mt-3 whitespace-pre-wrap leading-8 text-slate-600">{job.requirements || "Gereksinim girilmemiş."}</p>
        </article>
        <aside className="h-fit rounded-[2rem] border border-slate-200 bg-white p-6 shadow-soft">
          <p className="text-sm font-semibold text-slate-500">Maaş</p>
          <p className="mt-1 text-2xl font-black text-slate-950">{job.salaryRange || "Belirtilmedi"}</p>
          <p className="mt-5 text-sm text-slate-600">Başvuru sayısı: {job.applicationCount || 0}{job.maxApplicants ? ` / ${job.maxApplicants}` : ""}</p>
          <Link href={`/apply/${job.id}`} className="mt-6 block rounded-full bg-sky-700 px-6 py-3 text-center font-bold text-white hover:bg-sky-800">Başvur</Link>
        </aside>
      </section>
    </main>
  );
}
