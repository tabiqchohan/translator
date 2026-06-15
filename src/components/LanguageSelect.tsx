'use client';

import { languages, classNames } from '@/lib/utils';

interface LanguageSelectProps {
  value: string;
  onChange: (value: string) => void;
  label: string;
  showAuto?: boolean;
}

export default function LanguageSelect({ value, onChange, label, showAuto = false }: LanguageSelectProps) {
  const langs = showAuto ? languages : languages.filter((l) => l.code !== 'auto');

  return (
    <div className="flex flex-col gap-1.5">
      <label className="text-sm font-medium text-zinc-600 dark:text-zinc-400">{label}</label>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className={classNames(
          'rounded-lg border border-zinc-200 bg-white px-3 py-2.5 text-sm',
          'focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20',
          'dark:border-zinc-700 dark:bg-zinc-800 dark:text-zinc-100 dark:focus:border-blue-400'
        )}
      >
        {langs.map((lang) => (
          <option key={lang.code} value={lang.code}>
            {lang.name}
          </option>
        ))}
      </select>
    </div>
  );
}
