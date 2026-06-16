'use client';

import { useState, useRef, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Camera, CameraOff, ScanText } from 'lucide-react';
import LanguageSelect from './LanguageSelect';
import TranslationCard from './TranslationCard';
import { imageTranslate } from '@/lib/puter';

export default function CameraTranslate() {
  const [isActive, setIsActive] = useState(false);
  const [capturedText, setCapturedText] = useState('');
  const [translatedText, setTranslatedText] = useState('');
  const [targetLang, setTargetLang] = useState('en');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const streamRef = useRef<MediaStream | null>(null);

  const startCamera = async () => {
    try {
      setError('');
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: 'environment', width: 1080, height: 720 },
      });
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
      }
      streamRef.current = stream;
      setIsActive(true);
    } catch {
      setError('Camera access denied. Please allow camera permissions.');
    }
  };

  const stopCamera = () => {
    streamRef.current?.getTracks().forEach((t) => t.stop());
    streamRef.current = null;
    setIsActive(false);
  };

  const captureAndTranslate = useCallback(async () => {
    if (!videoRef.current || !canvasRef.current) return;

    const video = videoRef.current;
    const canvas = canvasRef.current;
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    ctx.drawImage(video, 0, 0);

    setLoading(true);
    setError('');

    try {
      canvas.toBlob(async (blob) => {
        if (!blob) {
          setError('Failed to capture image');
          setLoading(false);
          return;
        }

        setCapturedText('Processing image...');

        const result = await imageTranslate(blob, targetLang);
        if (result) {
          setTranslatedText(result);
          setCapturedText('Image captured and translated');
        } else {
          setError('No text detected in image. Try again with clearer lighting.');
        }
        setLoading(false);
      }, 'image/jpeg', 0.9);
    } catch {
      setError('Failed to process image. Try again.');
      setLoading(false);
    }
  }, [targetLang]);

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className="flex flex-col gap-4"
    >
      <div className="max-w-xs">
        <LanguageSelect value={targetLang} onChange={setTargetLang} label="Translate to" />
      </div>

      <div className="relative overflow-hidden rounded-lg bg-black">
        {isActive ? (
          <video
            ref={videoRef}
            autoPlay
            playsInline
            className="h-64 w-full object-cover"
          />
        ) : (
          <div className="flex h-64 items-center justify-center bg-zinc-900">
            <Camera size={48} className="text-zinc-600" />
          </div>
        )}
        <canvas ref={canvasRef} className="hidden" />

        <div className="absolute bottom-3 left-1/2 flex -translate-x-1/2 gap-3">
          {!isActive ? (
            <button
              onClick={startCamera}
              className="flex items-center gap-2 rounded-full bg-blue-600 px-5 py-2.5 text-sm font-medium text-white shadow-lg hover:bg-blue-700"
            >
              <Camera size={16} />
              Open Camera
            </button>
          ) : (
            <>
              <button
                onClick={captureAndTranslate}
                disabled={loading}
                className="flex items-center gap-2 rounded-full bg-white px-5 py-2.5 text-sm font-medium text-zinc-800 shadow-lg hover:bg-zinc-100 disabled:opacity-50"
              >
                <ScanText size={16} />
                {loading ? 'Processing...' : 'Scan & Translate'}
              </button>
              <button
                onClick={stopCamera}
                className="flex items-center gap-2 rounded-full bg-red-500 px-4 py-2.5 text-sm font-medium text-white shadow-lg hover:bg-red-600"
              >
                <CameraOff size={16} />
              </button>
            </>
          )}
        </div>
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

      {capturedText && (
        <TranslationCard text={capturedText} label="Status" readOnly />
      )}

      {translatedText && (
        <TranslationCard text={translatedText} label="Translation" readOnly />
      )}
    </motion.div>
  );
}
