'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Languages, ArrowLeft } from 'lucide-react';

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [sent, setSent] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const res = await fetch('/api/forgot-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || 'Something went wrong');
        return;
      }

      setSent(true);
    } catch {
      setError('Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="mx-auto flex min-h-[80vh] w-full max-w-sm flex-col items-center justify-center px-4">
      <Link href="/" className="mb-8 flex items-center gap-2 text-xl font-bold text-zinc-800 dark:text-zinc-100">
        <Languages size={24} className="text-blue-600" />
        Translater
      </Link>

      <h1 className="mb-2 text-2xl font-bold text-zinc-800 dark:text-zinc-100">Reset Password</h1>
      <p className="mb-6 text-sm text-zinc-500 dark:text-zinc-400">
        Enter your email and we&apos;ll send you a reset link
      </p>

      {sent && (
        <div className="w-full rounded-lg bg-green-50 p-4 text-sm text-green-600 dark:bg-green-900/30 dark:text-green-400">
          <p className="font-medium">Reset link sent!</p>
          <p className="mt-1">Check your email for the password reset link.</p>
        </div>
      )}

      {error && (
        <p className="mb-4 w-full rounded-lg bg-red-50 p-3 text-sm text-red-600 dark:bg-red-900/30 dark:text-red-400">
          {error}
        </p>
      )}

      {!sent && (
        <form onSubmit={handleSubmit} className="flex w-full flex-col gap-4">
          <div>
            <label className="mb-1.5 block text-sm font-medium text-zinc-600 dark:text-zinc-400">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="w-full rounded-lg border border-zinc-200 bg-white px-3 py-2.5 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 dark:border-zinc-700 dark:bg-zinc-800 dark:text-zinc-100"
              placeholder="you@example.com"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-lg bg-blue-600 py-2.5 text-sm font-medium text-white transition-colors hover:bg-blue-700 disabled:opacity-50"
          >
            {loading ? 'Sending...' : 'Send Reset Link'}
          </button>
        </form>
      )}

      <Link
        href="/login"
        className="mt-6 flex items-center gap-1 text-sm text-zinc-500 hover:text-zinc-700 dark:text-zinc-400 dark:hover:text-zinc-200"
      >
        <ArrowLeft size={14} />
        Back to sign in
      </Link>
    </main>
  );
}
