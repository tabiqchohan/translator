'use client';

import { useSession, signOut } from 'next-auth/react';
import { LogOut, User } from 'lucide-react';
import Link from 'next/link';

export default function AuthButtons() {
  const { data: session } = useSession();

  if (session?.user) {
    return (
      <div className="flex items-center gap-2">
        <Link
          href="/profile"
          className="flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-sm font-medium text-zinc-600 transition-colors hover:bg-zinc-100 dark:text-zinc-400 dark:hover:bg-zinc-700"
        >
          <User size={15} />
          {session.user.name || session.user.email?.split('@')[0]}
        </Link>
        <button
          onClick={() => signOut()}
          className="rounded-lg p-1.5 text-zinc-400 transition-colors hover:bg-red-50 hover:text-red-500 dark:hover:bg-red-900/30"
          title="Sign out"
        >
          <LogOut size={15} />
        </button>
      </div>
    );
  }

  return (
    <Link
      href="/login"
      className="inline-flex items-center gap-1.5 rounded-lg bg-gradient-to-r from-blue-600 to-indigo-600 px-4 py-1.5 text-sm font-medium text-white shadow-sm transition-all hover:shadow-md"
    >
      Sign In
    </Link>
  );
}
