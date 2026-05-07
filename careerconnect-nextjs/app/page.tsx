import Link from "next/link";

export default function HomePage() {
  return (
    <main>
      <section className="container-page grid gap-10 py-20 lg:grid-cols-[1.1fr_0.9fr] lg:items-center">
        <div>
          <p className="mb-4 inline-flex rounded-full border border-sky-200 bg-sky-50 px-4 py-2 text-sm font-semibold text-sky-800">
            Salesforce + Next.js Recruitment Portal
          </p>
          <h1 className="text-5xl font-black tracking-tight text-slate-950 md:text-6xl">
            Aday, ilan ve başvuru sürecini tek portaldan yönet.
          </h1>
          <p className="mt-6 max-w-2xl text-lg leading-8 text-slate-600">
            CareerConnect; Next.js arayüzü, API Route/BFF katmanı ve Salesforce Apex REST backend’i ile kurulan profesyonel işe alım mimarisidir.
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <Link href="/jobs" className="rounded-full bg-sky-700 px-6 py-3 font-semibold text-white shadow-soft hover:bg-sky-800">
              Açık Pozisyonları Gör
            </Link>
            <Link href="/admin" className="rounded-full border border-slate-300 bg-white px-6 py-3 font-semibold text-slate-800 hover:bg-slate-50">
              HR Paneline Git
            </Link>
          </div>
        </div>
        <div className="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-soft">
          <div className="grid gap-4">
            {[
              ["Next.js", "SSR/CSR, App Router, API Routes"],
              ["Salesforce", "Apex REST, Custom Objects, Triggers"],
              ["External API", "Reed API preview + Salesforce sync endpoint"],
              ["Security", "OAuth Client Credentials, server-side secrets"]
            ].map(([title, text]) => (
              <div key={title} className="rounded-2xl bg-slate-50 p-5">
                <h3 className="font-bold text-slate-950">{title}</h3>
                <p className="mt-1 text-sm text-slate-600">{text}</p>
              </div>
            ))}
          </div>
        </div>
      </section>
    </main>
  );
}
