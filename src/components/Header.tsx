'use client';

import Link from 'next/link';
import { Languages, History, Heart } from 'lucide-react';
import { usePathname } from 'next/navigation';
import ThemeToggle from './ThemeToggle';
import AuthButtons from './AuthButtons';
import { classNames } from '@/lib/utils';

export default function Header() {
  const pathname = usePathname();

  if (pathname.startsWith('/login') || pathname.startsWith('/register') || pathname.startsWith('/forgot-password') || pathname.startsWith('/reset-password')) {
    return null;
  }

  return (
    <header className="sticky top-0 z-10 border-b border-zinc-200 bg-white/80 backdrop-blur-sm dark:border-zinc-700 dark:bg-zinc-900/80">
      <div className="mx-auto flex max-w-3xl items-center justify-between px-4 py-3">
        <Link href="/" className="flex items-center gap-2 text-lg font-bold text-zinc-800 dark:text-zinc-100">
          <Languages size={22} className="text-blue-600" />
          <span className="hidden sm:inline">Translater</span>
        </Link>

        <div className="flex items-center gap-1">
          <Link
            href="/history"
            className={classNames(
              'rounded-lg p-2 text-sm transition-colors',
              pathname === '/history'
                ? 'bg-zinc-100 text-blue-600 dark:bg-zinc-700 dark:text-blue-400'
                : 'text-zinc-500 hover:bg-zinc-100 hover:text-zinc-700 dark:text-zinc-400 dark:hover:bg-zinc-700 dark:hover:text-zinc-200'
            )}
            title="History"
          >
            <History size={18} />
          </Link>
          <Link
            href="/favorites"
            className={classNames(
              'rounded-lg p-2 text-sm transition-colors',
              pathname === '/favorites'
                ? 'bg-zinc-100 text-blue-600 dark:bg-zinc-700 dark:text-blue-400'
                : 'text-zinc-500 hover:bg-zinc-100 hover:text-zinc-700 dark:text-zinc-400 dark:hover:bg-zinc-700 dark:hover:text-zinc-200'
            )}
            title="Favorites"
          >
            <Heart size={18} />
          </Link>
          <div className="ml-1 border-l border-zinc-200 pl-1 dark:border-zinc-700">
            <ThemeToggle />
          </div>
          <div className="ml-1 border-l border-zinc-200 pl-1 dark:border-zinc-700">
            <AuthButtons />
          </div>
        </div>
      </div>
    </header>
  );
}
