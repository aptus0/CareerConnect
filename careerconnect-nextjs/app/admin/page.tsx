import { AdminPanel } from "@/components/AdminPanel";

export default function AdminPage() {
  return (
    <main className="container-page py-12">
      <h1 className="text-4xl font-black tracking-tight text-slate-950">HR Admin Panel</h1>
      <p className="mt-3 max-w-2xl text-slate-600">Bu ekran demo amaçlıdır. Production’da NextAuth/SSO ve role guard eklenmelidir.</p>
      <div className="mt-8"><AdminPanel /></div>
    </main>
  );
}
