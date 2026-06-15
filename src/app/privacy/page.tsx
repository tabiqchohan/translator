import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';

export default function PrivacyPage() {
  return (
    <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col px-4 py-6">
      <Link href="/" className="mb-4 flex items-center gap-1 text-sm text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300">
        <ArrowLeft size={14} /> Back
      </Link>
      <h1 className="mb-6 text-2xl font-bold text-zinc-800 dark:text-zinc-100">Privacy Policy</h1>
      <div className="prose prose-sm dark:prose-invert max-w-none space-y-4 text-zinc-600 dark:text-zinc-400">
        <p><strong>Last updated:</strong> June 2026</p>

        <h2 className="text-lg font-semibold text-zinc-800 dark:text-zinc-200">1. Information We Collect</h2>
        <p>When you create an account, we collect your name and email address. Translation text is processed temporarily to provide the service and is not stored permanently on our servers.</p>

        <h2 className="text-lg font-semibold text-zinc-800 dark:text-zinc-200">2. How We Use Your Information</h2>
        <p>We use your information to: provide translation services, save your translation history (if signed in), improve our service, and communicate with you about account-related matters.</p>

        <h2 className="text-lg font-semibold text-zinc-800 dark:text-zinc-200">3. Data Storage</h2>
        <p>Your account data and saved translations are stored securely in PostgreSQL (Neon). Translation processing is handled by Puter.js third-party AI service.</p>

        <h2 className="text-lg font-semibold text-zinc-800 dark:text-zinc-200">4. Third-Party Services</h2>
        <p>We use Puter.js for AI translation. No personal data is shared beyond what is necessary for translation. We do not sell or share your data with advertisers.</p>

        <h2 className="text-lg font-semibold text-zinc-800 dark:text-zinc-200">5. Your Rights</h2>
        <p>You may request deletion of your account and associated data by contacting us. You can also clear your translation history at any time.</p>

        <h2 className="text-lg font-semibold text-zinc-800 dark:text-zinc-200">6. Contact</h2>
        <p>For privacy concerns, contact us at privacy@translater.app</p>
      </div>
    </main>
  );
}
