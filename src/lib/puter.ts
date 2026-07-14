'use client';

let puterInstance: any = null;

async function getPuter() {
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
      script.onerror = () => reject();
      document.head.appendChild(script);
    });
    puterInstance = (window as any).puter;
    return puterInstance;
  }
}

export async function translateText(
  text: string,
  targetLang: string,
  sourceLang = 'auto'
): Promise<{ text: string; detectedLang?: string; confidence?: number }> {
  // Try server API first
  try {
    const res = await fetch('/api/translate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text, targetLang, sourceLang }),
    });
    if (res.ok) {
      const data = await res.json();
      if (data.text) return { text: data.text };
    }
  } catch {}

  // Fallback to client-side Puter.js
  try {
    const puter = await getPuter();
    if (!puter) return { text: '' };
    const source = sourceLang === 'auto' ? '' : ` from ${sourceLang}`;
    const response = await puter.ai.chat(
      `Translate the following text${source} to ${targetLang}. Output ONLY the translation:\n\n${text}`,
      { model: 'gpt-4.1' }
    );
    let content = response?.message?.content ?? response ?? '';
    if (typeof content === 'string') {
      content = content.trim().replace(/^["']|["']$/g, '');
    }
    return { text: content || '' };
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
