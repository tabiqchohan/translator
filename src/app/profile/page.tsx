'use client';

import { useSession } from 'next-auth/react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { ArrowLeft, User, Mail, Calendar, Shield, Settings, History, Heart } from 'lucide-react';
import { useEffect } from 'react';

export default function ProfilePage() {
  const { data: session, status } = useSession();
  const router = useRouter();

  useEffect(() => {
    if (status === 'unauthenticated') {
      router.push('/login');
    }
  }, [status, router]);

  if (status === 'loading') {
    return (
      <main className="mx-auto flex max-w-lg flex-1 flex-col items-center justify-center px-4">
        <p className="text-zinc-500">Loading profile...</p>
      </main>
    );
  }

  if (!session?.user) return null;

  return (
    <main className="mx-auto flex w-full max-w-lg flex-1 flex-col px-4 py-6">
      <div className="mb-6 flex items-center gap-3">
        <Link
          href="/"
          className="rounded-lg p-2 text-zinc-400 hover:bg-zinc-100 hover:text-zinc-600 dark:hover:bg-zinc-700"
        >
          <ArrowLeft size={20} />
        </Link>
        <h1 className="text-lg font-semibold text-zinc-800 dark:text-zinc-100">Profile</h1>
      </div>

      <div className="flex flex-col items-center gap-4 pb-6">
        <div className="flex h-20 w-20 items-center justify-center rounded-full bg-blue-100 text-3xl font-bold text-blue-600 dark:bg-blue-900/50 dark:text-blue-400">
          {(session.user.name || session.user.email || 'U')[0].toUpperCase()}
        </div>
        <div className="text-center">
          <h2 className="text-xl font-semibold text-zinc-800 dark:text-zinc-100">
            {session.user.name || 'User'}
          </h2>
          <p className="text-sm text-zinc-500">{session.user.email}</p>
        </div>
      </div>

      <div className="flex flex-col gap-2">
        <div className="flex items-center gap-3 rounded-lg border border-zinc-200 p-3 dark:border-zinc-700">
          <User size={18} className="text-zinc-400" />
          <div>
            <p className="text-xs text-zinc-400">Name</p>
            <p className="text-sm text-zinc-700 dark:text-zinc-300">{session.user.name || 'Not set'}</p>
          </div>
        </div>

        <div className="flex items-center gap-3 rounded-lg border border-zinc-200 p-3 dark:border-zinc-700">
          <Mail size={18} className="text-zinc-400" />
          <div>
            <p className="text-xs text-zinc-400">Email</p>
            <p className="text-sm text-zinc-700 dark:text-zinc-300">{session.user.email}</p>
          </div>
        </div>

        <div className="flex items-center gap-3 rounded-lg border border-zinc-200 p-3 dark:border-zinc-700">
          <Shield size={18} className="text-zinc-400" />
          <div>
            <p className="text-xs text-zinc-400">Account Type</p>
            <p className="text-sm text-green-600 dark:text-green-400">Active</p>
          </div>
        </div>

        <div className="flex items-center gap-3 rounded-lg border border-zinc-200 p-3 dark:border-zinc-700">
          <Calendar size={18} className="text-zinc-400" />
          <div>
            <p className="text-xs text-zinc-400">Status</p>
            <p className="text-sm text-zinc-700 dark:text-zinc-300">Signed in</p>
          </div>
        </div>
      </div>

      <div className="mt-8 flex flex-col gap-2">
        <Link
          href="/history"
          className="flex items-center gap-3 rounded-lg bg-zinc-50 px-4 py-3 text-sm font-medium text-zinc-700 transition-colors hover:bg-zinc-100 dark:bg-zinc-800 dark:text-zinc-300 dark:hover:bg-zinc-700"
        >
          <History size={18} className="text-zinc-400" />
          Translation History
        </Link>
        <Link
          href="/favorites"
          className="flex items-center gap-3 rounded-lg bg-zinc-50 px-4 py-3 text-sm font-medium text-zinc-700 transition-colors hover:bg-zinc-100 dark:bg-zinc-800 dark:text-zinc-300 dark:hover:bg-zinc-700"
        >
          <Heart size={18} className="text-zinc-400" />
          Favorites
        </Link>
        <Link
          href="/settings"
          className="flex items-center gap-3 rounded-lg bg-zinc-50 px-4 py-3 text-sm font-medium text-zinc-700 transition-colors hover:bg-zinc-100 dark:bg-zinc-800 dark:text-zinc-300 dark:hover:bg-zinc-700"
        >
          <Settings size={18} className="text-zinc-400" />
          Settings
        </Link>
      </div>

      <div className="mt-auto pt-8 text-center text-xs text-zinc-400">
        Translater v1.0.0
      </div>
    </main>
  );
}
