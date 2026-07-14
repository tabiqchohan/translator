'use client';

import { useState, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Mic, Square, Volume2, Sparkles } from 'lucide-react';
import LanguageSelect from './LanguageSelect';
import TranslationCard from './TranslationCard';
import { translateText } from '@/lib/puter';

const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;

const langMap: Record<string, string> = {
  auto: 'en-US',
  en: 'en-US', es: 'es-ES', fr: 'fr-FR', de: 'de-DE',
  it: 'it-IT', pt: 'pt-BR', ru: 'ru-RU', ar: 'ar-SA',
  hi: 'hi-IN', ur: 'ur-PK', bn: 'bn-IN', zh: 'zh-CN',
  ja: 'ja-JP', ko: 'ko-KR', tr: 'tr-TR', vi: 'vi-VN',
  th: 'th-TH', id: 'id-ID', ms: 'ms-MY', nl: 'nl-NL',
};

export default function VoiceTab() {
  const [isRecording, setIsRecording] = useState(false);
  const [transcript, setTranscript] = useState('');
  const [translatedText, setTranslatedText] = useState('');
  const [sourceLang, setSourceLang] = useState('auto');
  const [targetLang, setTargetLang] = useState('ur');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const recognitionRef = useRef<any>(null);
  const transcriptRef = useRef('');

  const startRecording = () => {
    if (!SpeechRecognition) {
      setError('Speech recognition is not supported in this browser. Try Chrome or Edge.');
      return;
    }

    setError('');
    setTranscript('');
    setTranslatedText('');

    try {
      const recognition = new SpeechRecognition();
      recognitionRef.current = recognition;

      recognition.continuous = true;
      recognition.interimResults = true;
      recognition.lang = langMap[sourceLang] || sourceLang;

      recognition.onresult = (event: any) => {
        let final = '';
        for (let i = event.resultIndex; i < event.results.length; i++) {
          final += event.results[i][0].transcript;
        }
        setTranscript(final);
        transcriptRef.current = final;
      };

      recognition.onerror = () => {
        setError('Speech recognition failed. Check microphone permissions.');
        setIsRecording(false);
      };

      recognition.onend = async () => {
        setIsRecording(false);
        const finalText = transcriptRef.current || '';
        if (!finalText.trim()) {
          setError('No speech detected. Please try again.');
          return;
        }

        setLoading(true);
        try {
          const result = await translateText(finalText, targetLang, sourceLang);
          if (result.error) {
            setError(result.error);
          } else {
            setTranslatedText(result.text);
          }
        } catch {
          setError('Translation failed. Please try again.');
        } finally {
          setLoading(false);
        }
      };

      recognition.start();
      setIsRecording(true);
    } catch {
      setError('Failed to start speech recognition.');
    }
  };

  const stopRecording = () => {
    if (recognitionRef.current) {
      recognitionRef.current.stop();
    }
    setIsRecording(false);
  };

  const speak = () => {
    if (!translatedText) return;
    speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(translatedText);
    utterance.lang = targetLang;
    try {
      const saved = JSON.parse(localStorage.getItem('translater-settings') || '{}');
      utterance.rate = saved.ttsRate || 0.9;
    } catch {
      utterance.rate = 0.9;
    }
    speechSynthesis.speak(utterance);
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
        <div className="flex-1">
          <LanguageSelect value={targetLang} onChange={setTargetLang} label="Target" />
        </div>
      </div>

      <div className="flex flex-col items-center gap-3 py-8">
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          onClick={isRecording ? stopRecording : startRecording}
          className={`relative flex h-20 w-20 items-center justify-center rounded-full shadow-lg transition-all ${
            isRecording
              ? 'bg-gradient-to-r from-red-500 to-rose-500 text-white shadow-red-500/30'
              : 'bg-gradient-to-r from-blue-600 to-indigo-600 text-white shadow-blue-500/30 hover:shadow-blue-500/50'
          }`}
        >
          {isRecording ? (
            <>
              <motion.div
                className="absolute inset-0 rounded-full border-2 border-red-400"
                animate={{ scale: [1, 1.3, 1], opacity: [0.5, 0, 0.5] }}
                transition={{ repeat: Infinity, duration: 1.5 }}
              />
              <Square size={24} />
            </>
          ) : (
            <Mic size={28} />
          )}
        </motion.button>

        <p className="text-sm font-medium text-zinc-500 dark:text-zinc-400">
          {isRecording ? 'Listening... tap to stop' : 'Tap to speak'}
        </p>

        {loading && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="flex items-center gap-2 text-sm text-zinc-500"
          >
            <motion.div animate={{ rotate: 360 }} transition={{ repeat: Infinity, duration: 1, ease: 'linear' }}>
              <Sparkles size={16} />
            </motion.div>
            Translating...
          </motion.div>
        )}
      </div>

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
        {transcript && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <TranslationCard text={transcript} label="You said" readOnly />
          </motion.div>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {translatedText && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <div className="mb-2 flex items-center justify-between">
              <label className="text-sm font-medium text-zinc-600 dark:text-zinc-400">Translation</label>
              <motion.button
                whileTap={{ scale: 0.9 }}
                onClick={speak}
                className="flex items-center gap-1.5 rounded-lg bg-zinc-100 px-3 py-1.5 text-xs font-medium text-zinc-600 transition-colors hover:bg-zinc-200 dark:bg-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-600"
              >
                <Volume2 size={14} />
                Speak
              </motion.button>
            </div>
            <TranslationCard text={translatedText} label="" readOnly />
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}
