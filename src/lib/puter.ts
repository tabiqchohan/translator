'use client';

export async function translateText(
  text: string,
  targetLang: string,
  sourceLang = 'auto'
): Promise<{ text: string }> {
  try {
    const res = await fetch('/api/translate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text, targetLang, sourceLang }),
    });

    if (!res.ok) return { text: '' };
    const data = await res.json();
    return { text: data.text || '' };
  } catch {
    return { text: '' };
  }
}

export async function imageToText(imageBlob: Blob | File): Promise<string> {
  try {
    const { createWorker } = await import('tesseract.js');
    const worker = await createWorker('eng+urd+ara', 1, { logger: () => {} });
    const { data } = await worker.recognize(imageBlob);
    await worker.terminate();
    const text = data.text?.trim() || '';
    return text.length < 3 ? '' : text;
  } catch {
    return '';
  }
}

export async function imageTranslate(imageBlob: Blob | File, targetLang: string): Promise<string> {
  const text = await imageToText(imageBlob);
  if (!text) return '';
  const translated = await translateText(text, targetLang, 'auto');
  return translated.text;
}
