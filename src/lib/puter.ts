'use client';

let puterInstance: any = null;

export async function initPuter() {
  if (typeof window === 'undefined') return null;
  if (puterInstance) return puterInstance;

  try {
    const module = await import('@heyputer/puter.js');
    puterInstance = module.puter || (window as any).puter;
    return puterInstance;
  } catch {
    const script = document.createElement('script');
    script.src = 'https://js.puter.com/v2/';
    script.async = true;
    await new Promise<void>((resolve, reject) => {
      script.onload = () => resolve();
      script.onerror = () => reject(new Error('Failed to load Puter.js'));
      document.head.appendChild(script);
    });
    puterInstance = (window as any).puter;
    return puterInstance;
  }
}

export async function translateText(
  text: string,
  targetLang: string,
  sourceLang = 'auto',
  model = 'gpt-4.1'
): Promise<{ text: string; detectedLang?: string; confidence?: number }> {
  const puter = await initPuter();
  if (!puter) return { text: '' };

  const source = sourceLang === 'auto' ? '' : ` from ${sourceLang}`;
  const prompt = sourceLang === 'auto'
    ? `Translate the following text to ${targetLang}. First, detect the source language. Return your response as JSON: {"detected":"language_name","translation":"translated_text"}. Do not include anything else:\n\n${text}`
    : `Translate the following text${source} to ${targetLang}. Output only the translation, nothing else:\n\n${text}`;

  const response = await puter.ai.chat(prompt, { model });
  const content = response?.message?.content ?? response ?? '';

  if (sourceLang === 'auto') {
    try {
      const parsed = JSON.parse(content);
      const langMap: Record<string, string> = {
        english: 'en', spanish: 'es', french: 'fr', german: 'de',
        italian: 'it', portuguese: 'pt', russian: 'ru', arabic: 'ar',
        hindi: 'hi', urdu: 'ur', bengali: 'bn', chinese: 'zh',
        japanese: 'ja', korean: 'ko', turkish: 'tr', vietnamese: 'vi',
        thai: 'th', indonesian: 'id', malay: 'ms', dutch: 'nl',
        swedish: 'sv', polish: 'pl', ukrainian: 'uk', romanian: 'ro',
        czech: 'cs', greek: 'el', hebrew: 'he', persian: 'fa',
        tagalog: 'tl', punjabi: 'pa', pashto: 'ps', sindhi: 'sd',
      };
      const detected = langMap[parsed.detected?.toLowerCase()] || parsed.detected;
      return { text: parsed.translation, detectedLang: detected, confidence: 0.9 };
    } catch {
      return { text: content.replace(/^["']|["']$/g, '') };
    }
  }

  return { text: content };
}

export async function speechToText(audioBlob: Blob): Promise<string> {
  const puter = await initPuter();
  if (!puter) return '';
  try {
    const result = await puter.ai.speech2txt(audioBlob);
    if (typeof result === 'string') return result;
    if (result?.text) return result.text;
    return '';
  } catch {
    return '';
  }
}

export async function imageToText(imageBlob: Blob | File, prompt?: string): Promise<string> {
  try {
    const { createWorker } = await import('tesseract.js');
    const worker = await createWorker('eng', 1);
    const { data } = await worker.recognize(imageBlob);
    await worker.terminate();
    return data.text || '';
  } catch {
    return '';
  }
}

export async function imageTranslate(imageBlob: Blob | File, targetLang: string): Promise<string> {
  const text = await imageToText(imageBlob);
  if (!text) return '';
  const translated = await translateText(text, targetLang);
  return translated.text;
}

export async function textToSpeech(text: string): Promise<Blob | null> {
  if ('speechSynthesis' in window) {
    return null;
  }
  return null;
}
