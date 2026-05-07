import type { Metadata } from "next";
import Link from "next/link";
import "./globals.css";

export const metadata: Metadata = {
  title: "CareerConnect",
  description: "Next.js + Salesforce recruitment portal"
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="tr">
      <body className="min-h-screen antialiased">
        <header className="sticky top-0 z-40 border-b border-slate-200/80 bg-white/85 backdrop-blur">
          <div className="container-page flex h-16 items-center justify-between">
            <Link href="/" className="text-xl font-black tracking-tight text-slate-950">
              Career<span className="text-sky-700">Connect</span>
            </Link>
            <nav className="flex items-center gap-4 text-sm font-medium text-slate-700">
              <Link href="/jobs" className="hover:text-sky-700">İlanlar</Link>
              <Link href="/my-applications" className="hover:text-sky-700">Başvurularım</Link>
              <Link href="/admin" className="rounded-full bg-slate-950 px-4 py-2 text-white hover:bg-slate-800">HR Panel</Link>
            </nav>
          </div>
        </header>
        {children}
        <footer className="mt-16 border-t border-slate-200 bg-white/70 py-8">
          <div className="container-page text-sm text-slate-500">
            Next.js BFF katmanı Salesforce Apex REST API ile güvenli şekilde konuşur. API anahtarları tarayıcıya gönderilmez.
          </div>
        </footer>
      </body>
    </html>
  );
}
