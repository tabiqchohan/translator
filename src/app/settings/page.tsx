'use client';

import { useState, useEffect } from 'react';
import { useTheme } from 'next-themes';
import { signOut } from 'next-auth/react';
import Link from 'next/link';
import { ArrowLeft, Sun, Moon, Monitor, Volume2, Globe, Trash2, Download, AlertTriangle, X } from 'lucide-react';
import { showToast } from '@/components/Toast';
import { languages } from '@/lib/utils';

const SETTINGS_KEY = 'translater-settings';

interface Settings {
  defaultTargetLang: string;
  ttsRate: number;
  theme: 'light' | 'dark' | 'system';
}

const defaultSettings: Settings = {
  defaultTargetLang: 'ur',
  ttsRate: 0.9,
  theme: 'system',
};

export default function SettingsPage() {
  const { theme, setTheme } = useTheme();
  const [settings, setSettings] = useState<Settings>(defaultSettings);
  const [mounted, setMounted] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deletePassword, setDeletePassword] = useState('');
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    setMounted(true);
    try {
      const saved = localStorage.getItem(SETTINGS_KEY);
      if (saved) setSettings({ ...defaultSettings, ...JSON.parse(saved) });
    } catch {}
  }, []);

  const save = (partial: Partial<Settings>) => {
    const updated = { ...settings, ...partial };
    setSettings(updated);
    localStorage.setItem(SETTINGS_KEY, JSON.stringify(updated));
    if (partial.theme) setTheme(partial.theme);
    showToast('Settings saved', 'success');
  };

  const clearHistory = async () => {
    if (!confirm('Delete all translation history?')) return;
    try {
      const entries = await (await fetch('/api/history')).json();
      for (const e of (entries.entries || [])) {
        await fetch(`/api/history?id=${e.id}`, { method: 'DELETE' });
      }
      showToast('History cleared', 'success');
    } catch {
      showToast('Failed to clear history', 'error');
    }
  };

  const exportHistory = async () => {
    try {
      const res = await fetch('/api/history');
      const data = await res.json();
      const blob = new Blob([JSON.stringify(data.entries || [], null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'translation-history.json';
      a.click();
      URL.revokeObjectURL(url);
      showToast('History exported!', 'success');
    } catch {
      showToast('Export failed', 'error');
    }
  };

  const handleDeleteAccount = async () => {
    if (!deletePassword) return;
    setDeleting(true);
    try {
      const res = await fetch('/api/account/delete', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ password: deletePassword }),
      });
      const data = await res.json();
      if (!res.ok) {
        showToast(data.error || 'Failed to delete account', 'error');
        setDeleting(false);
        return;
      }
      showToast('Account deleted successfully', 'success');
      setShowDeleteModal(false);
      setTimeout(() => signOut({ callbackUrl: '/' }), 1000);
    } catch {
      showToast('Failed to delete account', 'error');
      setDeleting(false);
    }
  };

  if (!mounted) return null;

  return (
    <main className="mx-auto flex w-full max-w-lg flex-1 flex-col px-4 py-6">
      <div className="mb-6 flex items-center gap-3">
        <Link href="/profile" className="rounded-lg p-2 text-zinc-400 hover:bg-zinc-100 hover:text-zinc-600 dark:hover:bg-zinc-700">
          <ArrowLeft size={20} />
        </Link>
        <h1 className="text-lg font-semibold text-zinc-800 dark:text-zinc-100">Settings</h1>
      </div>

      <div className="flex flex-col gap-6">
        <section>
          <h2 className="mb-3 text-sm font-semibold text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">Appearance</h2>
          <div className="flex gap-2">
            {[
              { value: 'light', icon: Sun, label: 'Light' },
              { value: 'dark', icon: Moon, label: 'Dark' },
              { value: 'system', icon: Monitor, label: 'System' },
            ].map(({ value, icon: Icon, label }) => (
              <button
                key={value}
                onClick={() => save({ theme: value as any })}
                className={`flex flex-1 flex-col items-center gap-2 rounded-lg border p-4 transition-colors ${
                  (theme === value)
                    ? 'border-blue-500 bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'
                    : 'border-zinc-200 text-zinc-600 hover:bg-zinc-50 dark:border-zinc-700 dark:text-zinc-400 dark:hover:bg-zinc-800'
                }`}
              >
                <Icon size={22} />
                <span className="text-xs font-medium">{label}</span>
              </button>
            ))}
          </div>
        </section>

        <section>
          <h2 className="mb-3 text-sm font-semibold text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">Default Language</h2>
          <select
            value={settings.defaultTargetLang}
            onChange={(e) => save({ defaultTargetLang: e.target.value })}
            className="w-full rounded-lg border border-zinc-200 bg-white px-3 py-2.5 text-sm dark:border-zinc-700 dark:bg-zinc-800 dark:text-zinc-100"
          >
            {languages.filter((l) => l.code !== 'auto').map((lang) => (
              <option key={lang.code} value={lang.code}>{lang.name}</option>
            ))}
          </select>
        </section>

        <section>
          <h2 className="mb-3 text-sm font-semibold text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
            <div className="flex items-center gap-2">
              <Volume2 size={14} />
              TTS Speed
            </div>
          </h2>
          <div className="flex items-center gap-3">
            <span className="text-xs text-zinc-400">Slow</span>
            <input
              type="range"
              min="0.5"
              max="2"
              step="0.1"
              value={settings.ttsRate}
              onChange={(e) => save({ ttsRate: parseFloat(e.target.value) })}
              className="flex-1 accent-blue-600"
            />
            <span className="text-xs text-zinc-400">Fast</span>
            <span className="w-8 text-center text-sm font-medium text-zinc-600 dark:text-zinc-300">{settings.ttsRate.toFixed(1)}x</span>
          </div>
        </section>

        <section>
          <h2 className="mb-3 text-sm font-semibold text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">Data</h2>
          <div className="flex gap-2">
            <button onClick={clearHistory} className="flex items-center gap-2 flex-1 rounded-lg border border-red-200 px-4 py-2.5 text-sm font-medium text-red-600 transition-colors hover:bg-red-50 dark:border-red-800 dark:text-red-400 dark:hover:bg-red-900/30">
              <Trash2 size={16} /> Clear History
            </button>
            <button onClick={exportHistory} className="flex items-center gap-2 flex-1 rounded-lg border border-zinc-200 px-4 py-2.5 text-sm font-medium text-zinc-600 transition-colors hover:bg-zinc-50 dark:border-zinc-700 dark:text-zinc-400 dark:hover:bg-zinc-800">
              <Download size={16} /> Export
            </button>
          </div>
        </section>

        <section>
          <h2 className="mb-3 text-sm font-semibold text-red-500 dark:text-red-400 uppercase tracking-wide">Danger Zone</h2>
          <button onClick={() => setShowDeleteModal(true)} className="flex items-center gap-2 w-full rounded-lg border border-red-300 bg-red-50 px-4 py-2.5 text-sm font-medium text-red-700 transition-colors hover:bg-red-100 dark:border-red-800 dark:bg-red-900/20 dark:text-red-400 dark:hover:bg-red-900/40">
            <AlertTriangle size={16} /> Delete Account
          </button>
        </section>
      </div>

      {showDeleteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
          <div className="w-full max-w-sm rounded-xl bg-white p-6 shadow-2xl dark:bg-zinc-800">
            <div className="mb-4 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-red-600 dark:text-red-400">Delete Account</h3>
              <button onClick={() => { setShowDeleteModal(false); setDeletePassword(''); }} className="rounded-lg p-1 text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-700">
                <X size={18} />
              </button>
            </div>
            <p className="mb-4 text-sm text-zinc-600 dark:text-zinc-400">
              This will permanently delete your account and all translation history. Enter your password to confirm.
            </p>
            <input
              type="password"
              placeholder="Enter your password"
              value={deletePassword}
              onChange={(e) => setDeletePassword(e.target.value)}
              className="mb-4 w-full rounded-lg border border-zinc-200 bg-white px-3 py-2.5 text-sm dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-100"
            />
            <div className="flex gap-2">
              <button onClick={() => { setShowDeleteModal(false); setDeletePassword(''); }} className="flex-1 rounded-lg border border-zinc-200 px-4 py-2.5 text-sm font-medium text-zinc-600 transition-colors hover:bg-zinc-50 dark:border-zinc-700 dark:text-zinc-400 dark:hover:bg-zinc-700">
                Cancel
              </button>
              <button onClick={handleDeleteAccount} disabled={!deletePassword || deleting} className="flex-1 rounded-lg bg-red-600 px-4 py-2.5 text-sm font-medium text-white transition-colors hover:bg-red-700 disabled:opacity-50">
                {deleting ? 'Deleting...' : 'Delete'}
              </button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}
