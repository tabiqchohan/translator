'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { Languages, User, Mail, Lock, Eye, EyeOff, ArrowRight } from 'lucide-react';

export default function RegisterPage() {
  const router = useRouter();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const res = await fetch('/api/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, email, password }),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || 'Registration failed');
        return;
      }

      setSuccess(true);
      setTimeout(() => router.push('/login'), 2000);
    } catch {
      setError('Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden px-4">
      <div className="pointer-events-none absolute inset-0 bg-gradient-to-br from-blue-600/5 via-purple-600/5 to-cyan-600/5 dark:from-blue-600/10 dark:via-purple-600/10 dark:to-cyan-600/10" />
      <div className="pointer-events-none absolute inset-0 bg-grid opacity-50" />

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="relative w-full max-w-sm"
      >
        <Link href="/" className="mb-8 flex items-center justify-center gap-2 text-xl font-bold text-zinc-800 dark:text-zinc-100">
          <motion.div animate={{ y: [0, -4, 0] }} transition={{ repeat: Infinity, duration: 3 }} className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 shadow-lg shadow-blue-500/30">
            <Languages size={20} className="text-white" />
          </motion.div>
          Translater
        </Link>

        <div className="rounded-2xl border border-zinc-200/50 bg-white/60 p-8 backdrop-blur-xl dark:border-zinc-700/50 dark:bg-zinc-800/60">
          <div className="mb-6 text-center">
            <h1 className="text-2xl font-bold text-zinc-800 dark:text-zinc-100">Create Account</h1>
            <p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400">Join Translater and start translating.</p>
          </div>

          {success && (
            <motion.p initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="mb-4 w-full rounded-lg bg-green-50 px-4 py-3 text-sm text-green-600 dark:bg-green-900/30 dark:text-green-400">
              Account created! Redirecting to sign in...
            </motion.p>
          )}

          {error && (
            <motion.p initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="mb-4 w-full rounded-lg bg-red-50 px-4 py-3 text-sm text-red-600 dark:bg-red-900/30 dark:text-red-400">
              {error}
            </motion.p>
          )}

          <form onSubmit={handleSubmit} className="flex w-full flex-col gap-5">
            <div>
              <label className="mb-1.5 block text-sm font-medium text-zinc-600 dark:text-zinc-400">Name</label>
              <div className="relative">
                <User size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-400" />
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                  className="w-full rounded-xl border border-zinc-200 bg-white/50 py-3 pl-10 pr-3 text-sm backdrop-blur-sm transition-all focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-500/20 dark:border-zinc-700 dark:bg-zinc-800/50 dark:text-zinc-100"
                  placeholder="Your name"
                />
              </div>
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-medium text-zinc-600 dark:text-zinc-400">Email</label>
              <div className="relative">
                <Mail size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-400" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  className="w-full rounded-xl border border-zinc-200 bg-white/50 py-3 pl-10 pr-3 text-sm backdrop-blur-sm transition-all focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-500/20 dark:border-zinc-700 dark:bg-zinc-800/50 dark:text-zinc-100"
                  placeholder="you@example.com"
                />
              </div>
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-medium text-zinc-600 dark:text-zinc-400">Password</label>
              <div className="relative">
                <Lock size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-400" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  minLength={6}
                  className="w-full rounded-xl border border-zinc-200 bg-white/50 py-3 pl-10 pr-10 text-sm backdrop-blur-sm transition-all focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-500/20 dark:border-zinc-700 dark:bg-zinc-800/50 dark:text-zinc-100"
                  placeholder="At least 6 characters"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-zinc-600"
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            <motion.button
              type="submit"
              disabled={loading}
              whileHover={{ scale: 1.01 }}
              whileTap={{ scale: 0.99 }}
              className="flex w-full items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 py-3 text-sm font-semibold text-white shadow-lg shadow-blue-500/30 transition-all hover:shadow-xl disabled:opacity-50"
            >
              {loading ? (
                <motion.div animate={{ rotate: 360 }} transition={{ repeat: Infinity, duration: 1, ease: 'linear' }} className="h-5 w-5 rounded-full border-2 border-white border-t-transparent" />
              ) : (
                <>
                  Create Account
                  <ArrowRight size={16} />
                </>
              )}
            </motion.button>
          </form>

          <p className="mt-6 text-sm text-zinc-500 dark:text-zinc-400">
            Already have an account?{' '}
            <Link href="/login" className="font-semibold text-blue-600 hover:text-blue-700 dark:text-blue-400">
              Sign in
            </Link>
          </p>
        </div>
      </motion.div>
    </div>
  );
}
