'use client';

import { useEffect, useState, useCallback } from 'react';
import { History, Trash2, Heart, ArrowLeft, Search } from 'lucide-react';
import Link from 'next/link';
import { HistoryEntry } from '@/types';
import { ListSkeleton } from '@/components/Skeleton';
import { useSession } from 'next-auth/react';

export default function HistoryPage() {
  const { data: session } = useSession();
  const [entries, setEntries] = useState<HistoryEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState('');
  const [search, setSearch] = useState('');

  const fetchHistory = useCallback(async () => {
    setErrorMsg('');
    setLoading(true);
    try {
      const res = await fetch('/api/history');
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Failed to load history');
      setEntries(data.entries ?? []);
    } catch (err) {
      setEntries([]);
      setErrorMsg(err instanceof Error ? err.message : 'Something went wrong');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (session) fetchHistory();
    else setLoading(false);
  }, [session, fetchHistory]);

  const deleteEntry = async (id: string) => {
    await fetch(`/api/history?id=${id}`, { method: 'DELETE' });
    setEntries((prev) => prev.filter((e) => e.id !== id));
  };

  const toggleFav = async (id: string) => {
    await fetch(`/api/history?id=${id}`, { method: 'PATCH' });
    setEntries((prev) =>
      prev.map((e) => (e.id === id ? { ...e, isFavorite: !e.isFavorite } : e))
    );
  };

  const filtered = entries.filter(
    (e) =>
      e.sourceText.toLowerCase().includes(search.toLowerCase()) ||
      e.translatedText.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col px-4 py-6">
      <div className="flex items-center gap-3 mb-4">
        <Link href="/" className="rounded-lg p-2 text-zinc-400 hover:bg-zinc-100 hover:text-zinc-600 dark:hover:bg-zinc-700">
          <ArrowLeft size={20} />
        </Link>
        <h1 className="text-lg font-semibold text-zinc-800 dark:text-zinc-100">Translation History</h1>
      </div>

      {entries.length > 0 && (
        <div className="relative mb-4">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-400" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search translations..."
            className="w-full rounded-lg border border-zinc-200 bg-white py-2 pl-9 pr-3 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 dark:border-zinc-700 dark:bg-zinc-800 dark:text-zinc-100"
          />
        </div>
      )}

      {loading ? (
        <ListSkeleton count={5} />
      ) : errorMsg ? (
        <div className="flex flex-col items-center gap-2 py-12 text-zinc-400">
          <History size={32} />
          <p className="text-sm text-red-500 dark:text-red-400">{errorMsg}</p>
          <button
            onClick={fetchHistory}
            className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
          >
            Retry
          </button>
        </div>
      ) : filtered.length === 0 ? (
        <div className="flex flex-col items-center gap-2 py-12 text-zinc-400">
          <History size={32} />
          <p className="text-sm">{search ? 'No results found' : 'No translations yet'}</p>
          {!search && (
            <Link href="/" className="text-sm text-blue-600 hover:underline dark:text-blue-400">
              Translate something
            </Link>
          )}
        </div>
      ) : (
        <div className="flex flex-col gap-3">
          {filtered.map((entry) => (
            <div
              key={entry.id}
              className="rounded-lg border border-zinc-200 bg-white p-4 transition-colors hover:border-zinc-300 dark:border-zinc-700 dark:bg-zinc-800 dark:hover:border-zinc-600"
            >
              <div className="mb-2 flex items-start justify-between gap-2">
                <span className="rounded bg-zinc-100 px-2 py-0.5 text-xs font-medium text-zinc-500 dark:bg-zinc-700 dark:text-zinc-400">
                  {entry.sourceLang} → {entry.targetLang}
                </span>
                <div className="flex items-center gap-1 shrink-0">
                  <button
                    onClick={() => toggleFav(entry.id)}
                    className={`rounded p-1 ${
                      entry.isFavorite
                        ? 'text-red-500'
                        : 'text-zinc-400 hover:text-red-400'
                    }`}
                  >
                    <Heart size={14} fill={entry.isFavorite ? 'currentColor' : 'none'} />
                  </button>
                  <button
                    onClick={() => deleteEntry(entry.id)}
                    className="rounded p-1 text-zinc-400 hover:text-red-500"
                  >
                    <Trash2 size={14} />
                  </button>
                </div>
              </div>
              <p className="text-sm text-zinc-700 dark:text-zinc-300 line-clamp-2">{entry.sourceText}</p>
              <p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400 line-clamp-2">{entry.translatedText}</p>
            </div>
          ))}
        </div>
      )}
    </main>
  );
}
