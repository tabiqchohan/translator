'use client';

import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Star, X } from 'lucide-react';

export default function AppRating() {
  const [visible, setVisible] = useState(false);
  const [rating, setRating] = useState(0);
  const [submitted, setSubmitted] = useState(false);

  useEffect(() => {
    const shown = localStorage.getItem('rating-shown');
    const count = parseInt(localStorage.getItem('translate-count') || '0');
    if (!shown && count >= 3) {
      setTimeout(() => setVisible(true), 2000);
    }
  }, []);

  const handleRate = (n: number) => {
    setRating(n);
    if (n >= 4) {
      setSubmitted(true);
      setTimeout(() => {
        setVisible(false);
        localStorage.setItem('rating-shown', 'true');
        window.open('https://play.google.com/store/apps/details?id=com.translater.app', '_blank');
      }, 1000);
    } else {
      setSubmitted(true);
      setTimeout(() => {
        setVisible(false);
        localStorage.setItem('rating-shown', 'true');
      }, 1500);
    }
  };

  const dismiss = () => {
    setVisible(false);
    localStorage.setItem('rating-shown', 'true');
  };

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: 50 }}
          className="fixed bottom-20 left-4 right-4 z-50 mx-auto max-w-sm rounded-xl border border-zinc-200 bg-white p-5 shadow-xl dark:border-zinc-700 dark:bg-zinc-800"
        >
          <button onClick={dismiss} className="absolute right-3 top-3 text-zinc-400 hover:text-zinc-600">
            <X size={16} />
          </button>

          <h3 className="text-base font-semibold text-zinc-800 dark:text-zinc-100">
            {submitted ? 'Thank you!' : 'Enjoying Translater?'}
          </h3>
          <p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
            {submitted
              ? rating >= 4
                ? 'Rate us on Google Play!'
                : 'We will improve. Thanks for your feedback!'
              : 'Tap a star to rate'}
          </p>

          <div className="mt-3 flex items-center justify-center gap-1.5">
            {[1, 2, 3, 4, 5].map((n) => (
              <button
                key={n}
                onClick={() => handleRate(n)}
                disabled={submitted}
                className={`rounded-lg p-1 transition-colors ${
                  n <= rating ? 'text-yellow-400' : 'text-zinc-300 dark:text-zinc-600'
                } ${submitted ? 'cursor-not-allowed' : 'hover:text-yellow-400'}`}
              >
                <Star size={28} fill={n <= rating ? 'currentColor' : 'none'} />
              </button>
            ))}
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
