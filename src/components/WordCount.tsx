'use client';

interface WordCountProps {
  text: string;
}

export default function WordCount({ text }: WordCountProps) {
  if (!text) return null;

  const chars = text.length;
  const words = text.trim() ? text.trim().split(/\s+/).length : 0;
  const lines = text.split('\n').length;

  return (
    <div className="flex items-center gap-3 text-xs text-zinc-400">
      <span>{chars} chars</span>
      <span>{words} words</span>
      <span>{lines} lines</span>
    </div>
  );
}
