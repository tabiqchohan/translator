'use client';

import { BadgeCheck } from 'lucide-react';
import { languages } from '@/lib/utils';

interface DetectedBadgeProps {
  lang: string;
  confidence?: number;
}

export default function DetectedBadge({ lang, confidence }: DetectedBadgeProps) {
  if (!lang || lang === 'auto') return null;

  const langName = languages.find((l) => l.code === lang)?.name || lang;

  return (
    <span className="inline-flex items-center gap-1 rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-700 dark:bg-green-900/30 dark:text-green-400">
      <BadgeCheck size={12} />
      Detected: {langName}
      {confidence && <span className="opacity-60">({Math.round(confidence * 100)}%)</span>}
    </span>
  );
}
