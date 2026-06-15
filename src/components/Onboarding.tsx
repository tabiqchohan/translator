'use client';

import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Languages, Mic, Camera, FileText, ArrowRight, X } from 'lucide-react';

const steps = [
  {
    icon: Languages,
    title: 'Translate Text',
    desc: 'Type or paste text and translate to any language instantly.',
  },
  {
    icon: Mic,
    title: 'Voice Translation',
    desc: 'Speak naturally — we convert speech to text and translate it.',
  },
  {
    icon: Camera,
    title: 'Camera Translation',
    desc: 'Point your camera at text and get instant translations.',
  },
  {
    icon: FileText,
    title: 'Document Translation',
    desc: 'Upload PDF, Word, or images for full document translation.',
  },
];

export default function Onboarding() {
  const [visible, setVisible] = useState(false);
  const [step, setStep] = useState(0);

  useEffect(() => {
    if (!localStorage.getItem('onboarding-done')) {
      setVisible(true);
    }
  }, []);

  const dismiss = () => {
    setVisible(false);
    localStorage.setItem('onboarding-done', 'true');
  };

  const next = () => {
    if (step < steps.length - 1) {
      setStep(step + 1);
    } else {
      dismiss();
    }
  };

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4 backdrop-blur-sm"
        >
          <motion.div
            key={step}
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="w-full max-w-sm rounded-2xl bg-white p-8 shadow-2xl dark:bg-zinc-800"
          >
            <button onClick={dismiss} className="absolute right-4 top-4 text-zinc-400 hover:text-zinc-600">
              <X size={18} />
            </button>

            <div className="flex flex-col items-center text-center">
              <div className="mb-4 flex h-20 w-20 items-center justify-center rounded-2xl bg-blue-100 text-blue-600 dark:bg-blue-900/50 dark:text-blue-400">
                {(() => {
                  const Icon = steps[step].icon;
                  return <Icon size={36} />;
                })()}
              </div>
              <h2 className="text-xl font-bold text-zinc-800 dark:text-zinc-100">{steps[step].title}</h2>
              <p className="mt-2 text-sm text-zinc-500 dark:text-zinc-400">{steps[step].desc}</p>
            </div>

            <div className="mt-6 flex items-center justify-between">
              <div className="flex gap-1.5">
                {steps.map((_, i) => (
                  <div
                    key={i}
                    className={`h-2 w-2 rounded-full transition-colors ${
                      i === step ? 'bg-blue-600' : 'bg-zinc-300 dark:bg-zinc-600'
                    }`}
                  />
                ))}
              </div>
              <button
                onClick={next}
                className="flex items-center gap-1.5 rounded-lg bg-blue-600 px-5 py-2.5 text-sm font-medium text-white transition-colors hover:bg-blue-700"
              >
                {step < steps.length - 1 ? 'Next' : 'Get Started'}
                <ArrowRight size={16} />
              </button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
