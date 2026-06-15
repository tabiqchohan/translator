import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';

export default function TermsPage() {
  return (
    <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col px-4 py-6">
      <Link href="/" className="mb-4 flex items-center gap-1 text-sm text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300">
        <ArrowLeft size={14} /> Back
      </Link>
      <h1 className="mb-6 text-2xl font-bold text-zinc-800 dark:text-zinc-100">Terms of Service</h1>
      <div className="prose prose-sm dark:prose-invert max-w-none space-y-4 text-zinc-600 dark:text-zinc-400">
        <p><strong>Last updated:</strong> June 2026</p>

        <h2 className="text-lg font-semibold text-zinc-800 dark:text-zinc-200">1. Acceptance of Terms</h2>
        <p>By using Translater, you agree to these terms. If you disagree, do not use the service.</p>

        <h2 className="text-lg font-semibold text-zinc-800 dark:text-zinc-200">2. Service Description</h2>
        <p>Translater provides text, voice, and document translation services powered by AI. The service is provided &quot;as is&quot; without warranty of accuracy.</p>

        <h2 className="text-lg font-semibold text-zinc-800 dark:text-zinc-200">3. User Responsibilities</h2>
        <p>You agree not to: misuse the service for illegal purposes, attempt to bypass rate limits, upload malicious files, or use automated bots without permission.</p>

        <h2 className="text-lg font-semibold text-zinc-800 dark:text-zinc-200">4. Account</h2>
        <p>You are responsible for maintaining your password confidentiality. You may delete your account at any time.</p>

        <h2 className="text-lg font-semibold text-zinc-800 dark:text-zinc-200">5. Limitation of Liability</h2>
        <p>Translater is not liable for translation inaccuracies or service interruptions. The service is free and provided without guarantees.</p>

        <h2 className="text-lg font-semibold text-zinc-800 dark:text-zinc-200">6. Changes</h2>
        <p>We may update these terms at any time. Continued use after changes constitutes acceptance.</p>
      </div>
    </main>
  );
}
