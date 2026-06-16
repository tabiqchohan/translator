'use client';

import Link from 'next/link';
import { Languages, History, Heart, Menu, X } from 'lucide-react';
import { usePathname } from 'next/navigation';
import { useState } from 'react';
import ThemeToggle from './ThemeToggle';
import AuthButtons from './AuthButtons';
import { classNames } from '@/lib/utils';

export default function Header() {
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);

  if (pathname.startsWith('/login') || pathname.startsWith('/register') || pathname.startsWith('/forgot-password') || pathname.startsWith('/reset-password')) {
    return null;
  }

  const navLinks = [
    { href: '/history', icon: History, label: 'History' },
    { href: '/favorites', icon: Heart, label: 'Favorites' },
  ];

  return (
    <header className="sticky top-0 z-20 border-b border-zinc-200/50 bg-white/70 backdrop-blur-xl dark:border-zinc-700/50 dark:bg-zinc-900/70">
      <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-3">
        <Link href="/" className="flex items-center gap-2 text-lg font-bold text-zinc-800 dark:text-zinc-100">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-blue-500 to-indigo-600 shadow-md">
            <Languages size={16} className="text-white" />
          </div>
          <span className="hidden sm:inline">Translater</span>
        </Link>

        {/* Desktop nav */}
        <div className="hidden items-center gap-1 md:flex">
          {navLinks.map(({ href, icon: Icon, label }) => (
            <Link
              key={href}
              href={href}
              className={classNames(
                'rounded-lg px-3 py-2 text-sm transition-colors',
                pathname === href
                  ? 'bg-blue-50 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400'
                  : 'text-zinc-500 hover:bg-zinc-100 hover:text-zinc-700 dark:text-zinc-400 dark:hover:bg-zinc-800 dark:hover:text-zinc-200'
              )}
            >
              {label}
            </Link>
          ))}
          <div className="ml-2 border-l border-zinc-200 pl-2 dark:border-zinc-700">
            <ThemeToggle />
          </div>
          <div className="ml-2">
            <AuthButtons />
          </div>
        </div>

        {/* Mobile nav */}
        <div className="flex items-center gap-2 md:hidden">
          <ThemeToggle />
          <button
            onClick={() => setMenuOpen(!menuOpen)}
            className="rounded-lg p-2 text-zinc-500 hover:bg-zinc-100 dark:hover:bg-zinc-800"
          >
            {menuOpen ? <X size={18} /> : <Menu size={18} />}
          </button>
        </div>
      </div>

      {/* Mobile menu */}
      {menuOpen && (
        <div className="border-t border-zinc-200/50 bg-white px-4 py-3 dark:border-zinc-700/50 dark:bg-zinc-900 md:hidden">
          <div className="flex flex-col gap-2">
            {navLinks.map(({ href, icon: Icon, label }) => (
              <Link
                key={href}
                href={href}
                onClick={() => setMenuOpen(false)}
                className={classNames(
                  'flex items-center gap-2 rounded-lg px-3 py-2 text-sm transition-colors',
                  pathname === href
                    ? 'bg-blue-50 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400'
                    : 'text-zinc-500 hover:bg-zinc-100 dark:text-zinc-400 dark:hover:bg-zinc-800'
                )}
              >
                <Icon size={16} />
                {label}
              </Link>
            ))}
            <div className="mt-1 border-t border-zinc-100 pt-2 dark:border-zinc-800">
              <AuthButtons />
            </div>
          </div>
        </div>
      )}
    </header>
  );
}
