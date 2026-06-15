'use client';

import { Copy, Check, Share2 } from 'lucide-react';
import { useState } from 'react';
import { showToast } from './Toast';

interface TranslationCardProps {
  text: string;
  label: string;
  placeholder?: string;
  onChange?: (value: string) => void;
  readOnly?: boolean;
  onKeyDown?: (e: React.KeyboardEvent) => void;
}

export default function TranslationCard({
  text,
  label,
  placeholder = 'Enter text here...',
  onChange,
  readOnly = false,
  onKeyDown,
}: TranslationCardProps) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    if (!text) return;
    await navigator.clipboard.writeText(text);
    setCopied(true);
    showToast('Copied!', 'success');
    setTimeout(() => setCopied(false), 2000);
  };

  const handleShare = async () => {
    if (!text || !navigator.share) return;
    await navigator.share({ text });
  };

  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-center justify-between">
        <label className="text-sm font-medium text-zinc-600 dark:text-zinc-400">{label}</label>
        <div className="flex items-center gap-1">
          {!readOnly && text && (
            <button
              onClick={handleCopy}
              className="rounded-md p-1.5 text-zinc-400 hover:bg-zinc-100 hover:text-zinc-600 dark:hover:bg-zinc-700 dark:hover:text-zinc-300"
              title="Copy"
            >
              {copied ? <Check size={16} /> : <Copy size={16} />}
            </button>
          )}
          {!readOnly && text && typeof navigator.share === 'function' && (
            <button
              onClick={handleShare}
              className="rounded-md p-1.5 text-zinc-400 hover:bg-zinc-100 hover:text-zinc-600 dark:hover:bg-zinc-700 dark:hover:text-zinc-300"
              title="Share"
            >
              <Share2 size={16} />
            </button>
          )}
        </div>
      </div>
      {readOnly ? (
        <div className="min-h-[120px] rounded-lg border border-zinc-200 bg-zinc-50 p-3 text-sm leading-relaxed text-zinc-800 dark:border-zinc-700 dark:bg-zinc-800/50 dark:text-zinc-200">
          {text || <span className="text-zinc-400">{placeholder}</span>}
        </div>
      ) : (
        <textarea
          value={text}
          onChange={(e) => onChange?.(e.target.value)}
          onKeyDown={onKeyDown}
          placeholder={placeholder}
          rows={4}
          className="min-h-[120px] w-full resize-y rounded-lg border border-zinc-200 bg-white p-3 text-sm leading-relaxed text-zinc-800 placeholder-zinc-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 dark:border-zinc-700 dark:bg-zinc-800 dark:text-zinc-200 dark:placeholder-zinc-500 dark:focus:border-blue-400"
        />
      )}
    </div>
  );
}
