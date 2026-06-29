'use client';

import { useState, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Camera, ScanText, Image, X } from 'lucide-react';
import LanguageSelect from './LanguageSelect';
import TranslationCard from './TranslationCard';
import { imageToText, translateText } from '@/lib/puter';

export default function CameraTranslate() {
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [extractedText, setExtractedText] = useState('');
  const [translatedText, setTranslatedText] = useState('');
  const [targetLang, setTargetLang] = useState('en');
  const [ocrLoading, setOcrLoading] = useState(false);
  const [transLoading, setTransLoading] = useState(false);
  const [error, setError] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const previewUrl = URL.createObjectURL(file);
    setImagePreview(previewUrl);
    setError('');
    setTranslatedText('');
    setExtractedText('');

    setOcrLoading(true);
    const text = await imageToText(file);
    setOcrLoading(false);

    if (!text) {
      setError('No text detected in image. Try clearer lighting or sharper image.');
      return;
    }

    setExtractedText(text);
    setTransLoading(true);
    const result = await translateText(text, targetLang, 'auto');
    setTransLoading(false);

    if (result.text) {
      setTranslatedText(result.text);
    } else {
      setError('Translation failed. Please try again.');
    }

    if (e.target) e.target.value = '';
  };

  const reset = () => {
    if (imagePreview) URL.revokeObjectURL(imagePreview);
    setImagePreview(null);
    setExtractedText('');
    setTranslatedText('');
    setError('');
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className="flex flex-col gap-4"
    >
      <div className="max-w-xs">
        <LanguageSelect value={targetLang} onChange={setTargetLang} label="Translate to" />
      </div>

      <div className="relative overflow-hidden rounded-lg bg-zinc-900">
        {imagePreview ? (
          <>
            <img src={imagePreview} alt="captured" className="h-64 w-full object-contain" />
            <button
              onClick={reset}
              className="absolute right-2 top-2 rounded-full bg-black/50 p-1.5 text-white hover:bg-black/70"
            >
              <X size={18} />
            </button>
          </>
        ) : (
          <div className="flex h-64 flex-col items-center justify-center gap-3 bg-zinc-900">
            <Camera size={48} className="text-zinc-600" />
            <p className="text-xs text-zinc-500">Take a photo or choose from gallery</p>
          </div>
        )}

        <div className="absolute bottom-3 left-1/2 flex -translate-x-1/2 gap-3">
          <button
            onClick={() => fileInputRef.current?.click()}
            className="flex items-center gap-2 rounded-full bg-blue-600 px-5 py-2.5 text-sm font-medium text-white shadow-lg hover:bg-blue-700"
          >
            <Camera size={16} />
            {imagePreview ? 'Retake' : 'Open Camera'}
          </button>
          {!imagePreview && (
            <button
              onClick={() => {
                const input = fileInputRef.current;
                if (input) {
                  input.removeAttribute('capture');
                  input.click();
                  input.setAttribute('capture', 'environment');
                }
              }}
              className="flex items-center gap-2 rounded-full bg-zinc-700 px-4 py-2.5 text-sm font-medium text-white shadow-lg hover:bg-zinc-600"
            >
              <Image size={16} />
            </button>
          )}
        </div>

        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          capture="environment"
          onChange={handleFile}
          className="hidden"
        />
      </div>

      <AnimatePresence>
        {error && (
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="text-sm text-red-500 dark:text-red-400"
          >
            {error}
          </motion.p>
        )}
      </AnimatePresence>

      {ocrLoading && (
        <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="text-sm text-zinc-500">
          Reading text from image...
        </motion.p>
      )}

      {transLoading && (
        <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="text-sm text-zinc-500">
          Translating...
        </motion.p>
      )}

      {extractedText && !ocrLoading && (
        <TranslationCard text={extractedText} label="Extracted text" readOnly />
      )}

      {translatedText && !transLoading && (
        <TranslationCard text={translatedText} label="Translation" readOnly />
      )}
    </motion.div>
  );
}
