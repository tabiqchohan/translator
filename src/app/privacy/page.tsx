import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';

export default function PrivacyPage() {
  return (
    <main className="mx-auto flex w-full max-w-2xl flex-1 flex-col px-4 py-6">
      <div className="mb-6 flex items-center gap-3">
        <Link href="/" className="rounded-lg p-2 text-zinc-400 hover:bg-zinc-100 hover:text-zinc-600 dark:hover:bg-zinc-700">
          <ArrowLeft size={20} />
        </Link>
        <h1 className="text-lg font-semibold text-zinc-800 dark:text-zinc-100">Privacy Policy</h1>
      </div>

      <div className="flex flex-col gap-6 text-sm leading-relaxed text-zinc-600 dark:text-zinc-400">
        <p>Last updated: June 2026</p>

        <section>
          <h2 className="mb-2 text-base font-semibold text-zinc-800 dark:text-zinc-200">1. Information We Collect</h2>
          <ul className="list-disc pl-5 space-y-1">
            <li><strong>Account Information:</strong> When you register, we collect your name, email address, and a securely hashed password.</li>
            <li><strong>Translation Data:</strong> Text you submit for translation is processed and stored as translation history.</li>
            <li><strong>Device Information:</strong> Basic browser and device information for service optimization.</li>
          </ul>
        </section>

        <section>
          <h2 className="mb-2 text-base font-semibold text-zinc-800 dark:text-zinc-200">2. How We Use Your Information</h2>
          <ul className="list-disc pl-5 space-y-1">
            <li>To provide and improve translation services</li>
            <li>To maintain your account and translation history</li>
            <li>To personalize your experience (e.g., default language settings)</li>
            <li>To communicate important account-related notices</li>
          </ul>
        </section>

        <section>
          <h2 className="mb-2 text-base font-semibold text-zinc-800 dark:text-zinc-200">3. Third-Party Services</h2>
          <p>We use the following third-party services:</p>
          <ul className="list-disc pl-5 space-y-1 mt-2">
            <li><strong>Puter.js</strong> — AI-powered translation, speech-to-text, and image-to-text processing. Text you translate is sent to Puter.js servers for processing.</li>
            <li><strong>Neon PostgreSQL</strong> — Cloud database hosting for user accounts and translation history.</li>
            <li><strong>Vercel</strong> — Hosting and infrastructure.</li>
          </ul>
        </section>

        <section>
          <h2 className="mb-2 text-base font-semibold text-zinc-800 dark:text-zinc-200">4. Data Storage and Security</h2>
          <ul className="list-disc pl-5 space-y-1">
            <li>Passwords are hashed using bcrypt before storage.</li>
            <li>Translation history is stored securely in our database.</li>
            <li>We implement reasonable security measures to protect your data.</li>
          </ul>
        </section>

        <section>
          <h2 className="mb-2 text-base font-semibold text-zinc-800 dark:text-zinc-200">5. Data Retention</h2>
          <p>We retain your account information and translation history until you choose to delete your account. You can delete your account at any time from the Settings page, which permanently removes all associated data.</p>
        </section>

        <section>
          <h2 className="mb-2 text-base font-semibold text-zinc-800 dark:text-zinc-200">6. Your Rights</h2>
          <ul className="list-disc pl-5 space-y-1">
            <li>Access your personal data at any time</li>
            <li>Delete your account and all associated data from Settings</li>
            <li>Export your translation history as JSON</li>
          </ul>
        </section>

        <section>
          <h2 className="mb-2 text-base font-semibold text-zinc-800 dark:text-zinc-200">7. Cookies</h2>
          <p>We use essential cookies for authentication (NextAuth.js session tokens). No tracking or advertising cookies are used.</p>
        </section>

        <section>
          <h2 className="mb-2 text-base font-semibold text-zinc-800 dark:text-zinc-200">8. Children&apos;s Privacy</h2>
          <p>Our service is not intended for users under the age of 13. We do not knowingly collect data from children.</p>
        </section>

        <section>
          <h2 className="mb-2 text-base font-semibold text-zinc-800 dark:text-zinc-200">9. Contact</h2>
          <p>For privacy-related inquiries, please contact us at the email associated with this application.</p>
        </section>

        <section>
          <h2 className="mb-2 text-base font-semibold text-zinc-800 dark:text-zinc-200">10. Changes to This Policy</h2>
          <p>We may update this privacy policy from time to time. Users will be notified of material changes via the app.</p>
        </section>
      </div>

      <div className="mt-8 text-center text-xs text-zinc-400">
        Powered by tabiqchohan
      </div>
    </main>
  );
}
