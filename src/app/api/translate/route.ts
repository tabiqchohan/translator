import { NextRequest } from 'next/server';

const LANG_MAP: Record<string, string> = {
  en: 'en', es: 'es', fr: 'fr', de: 'de', it: 'it', pt: 'pt',
  ru: 'ru', ar: 'ar', hi: 'hi', ur: 'ur', bn: 'bn', zh: 'zh',
  ja: 'ja', ko: 'ko', tr: 'tr', vi: 'vi', th: 'th', id: 'id',
  ms: 'ms', nl: 'nl', sv: 'sv', pl: 'pl', uk: 'uk', ro: 'ro',
  cs: 'cs', el: 'el', he: 'he', fa: 'fa', tl: 'tl', pa: 'pa',
  ps: 'ps', sd: 'sd',
};

async function libreTranslate(text: string, target: string, source: string) {
  const src = source === 'auto' ? 'auto' : LANG_MAP[source] || source;
  const tgt = LANG_MAP[target] || target;

  const controllers = [
    'https://libretranslate.com/translate',
    'https://translate.argosopentech.com/translate',
  ];

  for (const url of controllers) {
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ q: text, source: src, target: tgt, format: 'text' }),
        signal: AbortSignal.timeout(8000),
      });
      if (!res.ok) continue;
      const data = await res.json();
      if (data.translatedText) return { text: data.translatedText };
    } catch {
      continue;
    }
  }

  return null;
}

async function puterTranslate(text: string, target: string, source: string) {
  const token = process.env.PUTER_AUTH_TOKEN;
  if (!token) return null;

  try {
    const sourcePart = source === 'auto' ? '' : ` from ${source}`;
    const messages = [
      {
        role: 'user',
        content: `Translate the following text${sourcePart} to ${target}. Output ONLY the translation, nothing else:\n\n${text}`,
      },
    ];

    const res = await fetch('https://api.puter.com/puterai/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ model: 'gpt-4.1', messages }),
      signal: AbortSignal.timeout(15000),
    });

    if (!res.ok) return null;
    const data = await res.json();
    const content = data?.choices?.[0]?.message?.content?.trim();
    if (content) return { text: content.replace(/^["']|["']$/g, '') };
  } catch {
    return null;
  }

  return null;
}

export async function POST(req: NextRequest) {
  try {
    const { text, targetLang, sourceLang = 'auto' } = await req.json();

    if (!text?.trim()) {
      return Response.json({ error: 'Text is required' }, { status: 400 });
    }

    let result = await puterTranslate(text, targetLang, sourceLang);
    if (!result) {
      result = await libreTranslate(text, targetLang, sourceLang);
    }

    if (!result) {
      return Response.json({ error: 'Translation failed. Try again.' }, { status: 500 });
    }

    return Response.json(result);
  } catch {
    return Response.json({ error: 'Translation failed' }, { status: 500 });
  }
}
