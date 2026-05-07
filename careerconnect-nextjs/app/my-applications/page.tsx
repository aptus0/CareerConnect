import { salesforceApex } from "@/lib/salesforce";
import { formatDate } from "@/lib/format";
import type { ApplicationSummary, SalesforceApiResponse } from "@/lib/types";

export default async function MyApplicationsPage() {
  let response: SalesforceApiResponse<ApplicationSummary[]> | null = null;
  let error = "";
  try {
    response = await salesforceApex<SalesforceApiResponse<ApplicationSummary[]>>("/careers/applications");
  } catch (err) {
    error = err instanceof Error ? err.message : "Başvurular alınamadı";
  }

  return (
    <main className="container-page py-12">
      <h1 className="text-4xl font-black tracking-tight text-slate-950">Başvurularım</h1>
      <p className="mt-3 max-w-2xl text-slate-600">Salesforce Candidate Profile bağlantısına göre başvuru geçmişi listelenir.</p>
      {error ? <p className="mt-8 rounded-2xl bg-amber-50 p-4 text-sm font-semibold text-amber-800">{error}</p> : null}
      <div className="mt-8 grid gap-4">
        {(response?.data || []).map((app) => (
          <article key={app.id} className="rounded-3xl border border-slate-200 bg-white p-6 shadow-soft">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <p className="text-sm font-bold text-sky-700">{app.applicationNumber}</p>
                <h2 className="text-xl font-black text-slate-950">{app.jobTitle}</h2>
              </div>
              <span className="rounded-full bg-slate-100 px-4 py-2 text-sm font-bold text-slate-700">{app.status}</span>
            </div>
            <p className="mt-4 text-sm text-slate-600">Gönderim: {formatDate(app.submittedDate)}</p>
            {app.rejectionReason ? <p className="mt-3 text-sm text-red-700">{app.rejectionReason}</p> : null}
          </article>
        ))}
      </div>
    </main>
  );
}
