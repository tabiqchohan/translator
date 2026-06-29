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

  const trimmed = text.trim();
  if (!trimmed) return { text: '' };

  try {
    const source = sourceLang === 'auto' ? '' : ` from ${sourceLang}`;
    const prompt = `Translate the following text${source} to ${targetLang}. Output ONLY the translation, nothing else, no quotes, no labels:\n\n${trimmed}`;

    const response = await puter.ai.chat(prompt, { model });
    let content = response?.message?.content ?? response ?? '';

    if (typeof content === 'string') {
      content = content.trim().replace(/^["']|["']$/g, '');
    }

    if (!content) {
      throw new Error('Empty response');
    }

    return { text: content };
  } catch {
    try {
      const response = await puter.ai.chat(
        `Translate this to ${targetLang} and return ONLY the translation: ${trimmed}`,
        { model }
      );
      let content = response?.message?.content ?? response ?? '';
      if (typeof content === 'string') {
        content = content.trim().replace(/^["']|["']$/g, '');
      }
      return { text: content || trimmed };
    } catch {
      return { text: trimmed };
    }
  }
}

export async function imageToText(imageBlob: Blob | File): Promise<string> {
  try {
    const { createWorker } = await import('tesseract.js');
    const worker = await createWorker('eng+urd+ara', 1, {
      logger: () => {},
    });
    const { data } = await worker.recognize(imageBlob);
    await worker.terminate();
    const text = data.text?.trim() || '';
    if (text.length < 3) return '';
    return text;
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
