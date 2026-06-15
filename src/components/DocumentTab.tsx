'use client';

import { useState, useRef } from 'react';
import { Upload, FileText, Download, Languages } from 'lucide-react';
import LanguageSelect from './LanguageSelect';
import { fileTypes } from '@/lib/utils';
import { translateText } from '@/lib/puter';

export default function DocumentTab() {
  const [file, setFile] = useState<File | null>(null);
  const [targetLang, setTargetLang] = useState('ur');
  const [loading, setLoading] = useState(false);
  const [parsing, setParsing] = useState(false);
  const [result, setResult] = useState<{
    originalText: string;
    translatedText: string;
    filename: string;
  } | null>(null);
  const [error, setError] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selected = e.target.files?.[0];
    if (selected) {
      if (selected.size > 10 * 1024 * 1024) {
        setError('File size must be under 10MB');
        return;
      }
      setFile(selected);
      setResult(null);
      setError('');
    }
  };

  const handleUpload = async () => {
    if (!file) return;
    setParsing(true);
    setError('');

    try {
      const formData = new FormData();
      formData.append('file', file);

      const response = await fetch('/api/document', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        const err = await response.json();
        throw new Error(err.error || 'Document processing failed');
      }

      const data = await response.json();
      setParsing(false);
      setLoading(true);

      const translated = await translateText(data.originalText, targetLang);
      setResult({
        originalText: data.originalText,
        translatedText: translated.text,
        filename: data.filename,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to process document');
    } finally {
      setParsing(false);
      setLoading(false);
    }
  };

  const downloadAsText = () => {
    if (!result?.translatedText) return;
    const blob = new Blob([result.translatedText], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `translated_${result.filename}.txt`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const acceptedTypes = fileTypes.map((ft) => ft.accept).join(',');

  return (
    <div className="flex flex-col gap-4">
      <div className="max-w-xs">
        <LanguageSelect value={targetLang} onChange={setTargetLang} label="Target Language" />
      </div>

      <div
        onClick={() => fileInputRef.current?.click()}
        className="flex cursor-pointer flex-col items-center gap-3 rounded-lg border-2 border-dashed border-zinc-300 p-8 transition-colors hover:border-blue-400 dark:border-zinc-600 dark:hover:border-blue-500"
      >
        <Upload size={32} className="text-zinc-400" />
        <div className="text-center">
          <p className="text-sm font-medium text-zinc-600 dark:text-zinc-300">
            {file ? file.name : 'Click to upload a document'}
          </p>
          <p className="text-xs text-zinc-400 mt-1">
            PDF, Word, TXT, or Image (max 10MB)
          </p>
        </div>
        <input
          ref={fileInputRef}
          type="file"
          accept={acceptedTypes}
          onChange={handleFileSelect}
          className="hidden"
        />
      </div>

      {file && (
        <div className="flex items-center gap-2 rounded-lg bg-zinc-50 p-3 dark:bg-zinc-800">
          <FileText size={18} className="text-zinc-400" />
          <span className="flex-1 text-sm text-zinc-600 dark:text-zinc-300 truncate">
            {file.name}
          </span>
          <span className="text-xs text-zinc-400">
            {(file.size / 1024).toFixed(1)} KB
          </span>
        </div>
      )}

      {error && (
        <p className="text-sm text-red-500 dark:text-red-400">{error}</p>
      )}

      <button
        onClick={handleUpload}
        disabled={!file || parsing || loading}
        className="flex items-center justify-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
      >
        <Languages size={18} />
        {parsing ? 'Parsing document...' : loading ? 'Translating...' : 'Translate Document'}
      </button>

      {result && (
        <div className="flex flex-col gap-3 rounded-lg border border-zinc-200 p-4 dark:border-zinc-700">
          <h3 className="text-sm font-semibold text-zinc-700 dark:text-zinc-300">Result</h3>

          <div className="max-h-40 overflow-y-auto rounded bg-zinc-50 p-2 text-xs text-zinc-600 dark:bg-zinc-800 dark:text-zinc-400">
            <p className="font-medium mb-1">Original:</p>
            <p className="line-clamp-4">{result.originalText}</p>
          </div>

          <div className="max-h-40 overflow-y-auto rounded bg-blue-50 p-2 text-xs text-zinc-700 dark:bg-blue-900/20 dark:text-zinc-300">
            <p className="font-medium mb-1">Translated:</p>
            <p className="line-clamp-4">{result.translatedText}</p>
          </div>

          <button
            onClick={downloadAsText}
            className="flex items-center justify-center gap-2 rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700"
          >
            <Download size={16} />
            Download Translation
          </button>
        </div>
      )}
    </div>
  );
}
