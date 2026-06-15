'use client';

import { useEffect, useState } from 'react';
import { Heart, ArrowLeft } from 'lucide-react';
import Link from 'next/link';
import { HistoryEntry } from '@/types';

export default function FavoritesPage() {
  const [entries, setEntries] = useState<HistoryEntry[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchFavorites = async () => {
      try {
        const res = await fetch('/api/history');
        const data = await res.json();
        setEntries((data.entries ?? []).filter((e: HistoryEntry) => e.isFavorite));
      } catch {
        setEntries([]);
      } finally {
        setLoading(false);
      }
    };
    fetchFavorites();
  }, []);

  if (loading) {
    return (
      <main className="mx-auto flex max-w-3xl flex-1 flex-col px-4 py-6">
        <p className="text-center text-zinc-500">Loading favorites...</p>
      </main>
    );
  }

  return (
    <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col px-4 py-6">
      <div className="flex items-center gap-3 mb-6">
        <Link href="/" className="rounded-lg p-2 text-zinc-400 hover:bg-zinc-100 hover:text-zinc-600 dark:hover:bg-zinc-700">
          <ArrowLeft size={20} />
        </Link>
        <div className="flex items-center gap-2">
          <Heart size={20} className="text-red-500" />
          <h1 className="text-lg font-semibold text-zinc-800 dark:text-zinc-100">Favorites</h1>
        </div>
      </div>

      {entries.length === 0 ? (
        <div className="flex flex-col items-center gap-2 py-12 text-zinc-400">
          <Heart size={32} />
          <p className="text-sm">No favorite translations yet</p>
        </div>
      ) : (
        <div className="flex flex-col gap-3">
          {entries.map((entry) => (
            <div
              key={entry.id}
              className="rounded-lg border border-zinc-200 bg-white p-4 dark:border-zinc-700 dark:bg-zinc-800"
            >
              <span className="mb-2 inline-block rounded bg-zinc-100 px-2 py-0.5 text-xs font-medium text-zinc-500 dark:bg-zinc-700 dark:text-zinc-400">
                {entry.sourceLang} → {entry.targetLang}
              </span>
              <p className="mt-1 text-sm text-zinc-700 dark:text-zinc-300 line-clamp-2">
                {entry.sourceText}
              </p>
              <p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400 line-clamp-2">
                {entry.translatedText}
              </p>
            </div>
          ))}
        </div>
      )}
    </main>
  );
}
