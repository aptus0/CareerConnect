import Link from "next/link";
import { ApplyForm } from "@/components/ApplyForm";

export default async function ApplyPage({ params }: { params: Promise<{ id: string }> | { id: string } }) {
  const { id } = await params;
  return (
    <main className="container-page py-12">
      <Link href={`/jobs/${id}`} className="text-sm font-bold text-sky-700">← Pozisyon detayına dön</Link>
      <div className="mt-6 max-w-3xl">
        <ApplyForm jobId={id} />
      </div>
    </main>
  );
}
