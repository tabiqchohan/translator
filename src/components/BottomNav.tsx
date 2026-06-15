'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Languages, History, Heart, Settings, User } from 'lucide-react';
import { useSession } from 'next-auth/react';
import { classNames } from '@/lib/utils';

export default function BottomNav() {
  const pathname = usePathname();
  const { data: session } = useSession();

  const hideOn = ['/login', '/register', '/forgot-password', '/reset-password'];
  if (hideOn.some((p) => pathname.startsWith(p))) return null;

  const items = [
    { href: '/', icon: Languages, label: 'Translate' },
    { href: '/history', icon: History, label: 'History' },
    { href: '/favorites', icon: Heart, label: 'Favorites' },
    { href: '/settings', icon: Settings, label: 'Settings' },
    { href: session ? '/profile' : '/login', icon: User, label: session ? 'Profile' : 'Sign In' },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-10 border-t border-zinc-200 bg-white/80 backdrop-blur-sm dark:border-zinc-700 dark:bg-zinc-900/80 md:hidden">
      <div className="mx-auto flex max-w-lg items-center justify-around px-1 py-1">
        {items.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={classNames(
                'flex flex-col items-center gap-0.5 rounded-lg px-2 py-1.5 text-[10px] transition-colors',
                isActive
                  ? 'text-blue-600 dark:text-blue-400'
                  : 'text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-300'
              )}
            >
              <item.icon size={18} />
              <span>{item.label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
