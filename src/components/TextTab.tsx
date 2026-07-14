'use client';

import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Languages, ArrowRightLeft, X, FileDown, Sparkles, Check, Copy, Share2 } from 'lucide-react';
import LanguageSelect from './LanguageSelect';
import TranslationCard from './TranslationCard';
import WordCount from './WordCount';
import DetectedBadge from './DetectedBadge';
import { translateText } from '@/lib/puter';
import { showToast } from './Toast';
import { languages } from '@/lib/utils';
import { useSession } from 'next-auth/react';

const SETTINGS_KEY = 'translater-settings';

export default function TextTab() {
  const { data: session } = useSession();
  const [sourceText, setSourceText] = useState('');
  const [translatedText, setTranslatedText] = useState('');
  const [sourceLang, setSourceLang] = useState('auto');
  const [targetLang, setTargetLang] = useState('ur');
  const [detectedLang, setDetectedLang] = useState<string | undefined>();
  const [confidence, setConfidence] = useState<number | undefined>();

  useEffect(() => {
    try {
      const saved = localStorage.getItem(SETTINGS_KEY);
      if (saved) {
        const s = JSON.parse(saved);
        if (s.defaultTargetLang) setTargetLang(s.defaultTargetLang);
      }
    } catch {}
  }, []);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleTranslate = async () => {
    if (!sourceText.trim()) return;
    setLoading(true);
    setError('');
    setDetectedLang(undefined);
    setConfidence(undefined);
    try {
      const result = await translateText(sourceText, targetLang, sourceLang);
      if (result.error) {
        setError(result.error);
        setLoading(false);
        return;
      }
      setTranslatedText(result.text);

      if (session?.user?.id && result.text) {
        fetch('/api/history', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            userId: session.user.id,
            sourceText,
            translatedText: result.text,
            sourceLang,
            targetLang,
            type: 'text',
          }),
        }).catch(() => {});
      }

      try {
        const recent = JSON.parse(localStorage.getItem('recent-langs') || '[]');
        const pair = `${sourceLang}|${targetLang}`;
        const updated = [pair, ...recent.filter((r: string) => r !== pair)].slice(0, 5);
        localStorage.setItem('recent-langs', JSON.stringify(updated));
      } catch {}
    } catch {
      setError('Translation failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const swapLanguages = () => {
    if (sourceLang === 'auto') return;
    setSourceLang(targetLang);
    setTargetLang(sourceLang);
    setSourceText(translatedText);
    setTranslatedText(sourceText);
  };

  const clearAll = () => {
    setSourceText('');
    setTranslatedText('');
    setError('');
    setDetectedLang(undefined);
    setConfidence(undefined);
  };

  const exportAsPdf = async () => {
    if (!translatedText) return;
    const { default: jsPDF } = await import('jspdf');
    const doc = new jsPDF();
    doc.setFontSize(12);
    const lines = doc.splitTextToSize(translatedText, 170);
    doc.text(lines, 20, 20);
    doc.save('translation.pdf');
    showToast('PDF downloaded!', 'success');
  };

  const copyTranslation = async () => {
    if (!translatedText) return;
    await navigator.clipboard.writeText(translatedText);
    showToast('Copied to clipboard!', 'success');
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) {
      handleTranslate();
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className="flex flex-col gap-4"
    >
      <div className="flex items-end gap-2">
        <div className="flex-1">
          <LanguageSelect value={sourceLang} onChange={setSourceLang} label="Source" showAuto />
        </div>
        <motion.button
          whileTap={{ scale: 0.9 }}
          onClick={swapLanguages}
          className="mb-1 rounded-lg p-2 text-zinc-400 hover:bg-zinc-100 hover:text-zinc-600 dark:hover:bg-zinc-700 dark:hover:text-zinc-300"
          title="Swap languages"
        >
          <ArrowRightLeft size={18} />
        </motion.button>
        <div className="flex-1">
          <LanguageSelect value={targetLang} onChange={setTargetLang} label="Target" />
        </div>
      </div>

      <div className="relative">
        <TranslationCard text={sourceText} onChange={setSourceText} label="Source Text" onKeyDown={handleKeyDown} />
        {sourceText && (
          <button
            onClick={clearAll}
            className="absolute right-2 top-8 rounded p-1 text-zinc-400 hover:bg-zinc-100 hover:text-zinc-600 dark:hover:bg-zinc-700"
          >
            <X size={14} />
          </button>
        )}
        <div className="mt-1 flex items-center justify-between px-1">
          <WordCount text={sourceText} />
          {detectedLang && <DetectedBadge lang={detectedLang} confidence={confidence} />}
        </div>
      </div>

      <motion.button
        whileHover={{ scale: 1.01 }}
        whileTap={{ scale: 0.98 }}
        onClick={handleTranslate}
        disabled={loading || !sourceText.trim()}
        className="flex items-center justify-center gap-2 rounded-lg bg-gradient-to-r from-blue-600 to-indigo-600 px-4 py-3 text-sm font-medium text-white shadow-lg shadow-blue-500/20 transition-all hover:from-blue-700 hover:to-indigo-700 disabled:cursor-not-allowed disabled:opacity-50"
      >
        {loading ? (
          <motion.div animate={{ rotate: 360 }} transition={{ repeat: Infinity, duration: 1, ease: 'linear' }}>
            <Sparkles size={18} />
          </motion.div>
        ) : (
          <Languages size={18} />
        )}
        {loading ? 'Translating...' : 'Translate'}
      </motion.button>

      <AnimatePresence>
        {error && (
          <motion.p
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="text-sm text-red-500 dark:text-red-400"
          >
            {error}
          </motion.p>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {(translatedText || loading) && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="flex flex-col gap-2"
          >
            <TranslationCard text={translatedText} label="Translation" readOnly />

            {translatedText && (
              <div className="flex items-center gap-2">
                <button
                  onClick={copyTranslation}
                  className="flex items-center gap-1.5 rounded-lg border border-zinc-200 px-3 py-2 text-xs font-medium text-zinc-600 transition-colors hover:bg-zinc-50 dark:border-zinc-700 dark:text-zinc-400 dark:hover:bg-zinc-800"
                >
                  <Copy size={14} />
                  Copy
                </button>
                <button
                  onClick={exportAsPdf}
                  className="flex items-center gap-1.5 rounded-lg border border-zinc-200 px-3 py-2 text-xs font-medium text-zinc-600 transition-colors hover:bg-zinc-50 dark:border-zinc-700 dark:text-zinc-400 dark:hover:bg-zinc-800"
                >
                  <FileDown size={14} />
                  Export PDF
                </button>
                <button
                  onClick={() => {
                    if (navigator.share) {
                      navigator.share({ title: 'Translation', text: translatedText }).catch(() => {});
                    } else {
                      navigator.clipboard.writeText(translatedText);
                      showToast('Copied to clipboard!', 'success');
                    }
                  }}
                  className="flex items-center gap-1.5 rounded-lg border border-zinc-200 px-3 py-2 text-xs font-medium text-zinc-600 transition-colors hover:bg-zinc-50 dark:border-zinc-700 dark:text-zinc-400 dark:hover:bg-zinc-800"
                >
                  <Share2 size={14} />
                  Share
                </button>
              </div>
            )}
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}
