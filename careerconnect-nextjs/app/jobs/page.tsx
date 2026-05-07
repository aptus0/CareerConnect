import { JobsClient } from "@/components/JobsClient";

export default function JobsPage() {
  return (
    <main>
      <section className="container-page pt-12">
        <h1 className="text-4xl font-black tracking-tight text-slate-950">Açık Pozisyonlar</h1>
        <p className="mt-3 max-w-2xl text-slate-600">Filtrele, detay görüntüle ve başvuruyu Salesforce üzerinde oluştur.</p>
      </section>
      <JobsClient />
    </main>
  );
}
