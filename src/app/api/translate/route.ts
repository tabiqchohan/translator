import { NextRequest } from 'next/server';

const LANG_MAP: Record<string, string> = {
  en: 'en', es: 'es', fr: 'fr', de: 'de', it: 'it', pt: 'pt',
  ru: 'ru', ar: 'ar', hi: 'hi', ur: 'ur', bn: 'bn', zh: 'zh',
  ja: 'ja', ko: 'ko', tr: 'tr', vi: 'vi', th: 'th', id: 'id',
  ms: 'ms', nl: 'nl', sv: 'sv', pl: 'pl', uk: 'uk', ro: 'ro',
  cs: 'cs', el: 'el', he: 'he', fa: 'fa', tl: 'tl', pa: 'pa',
  ps: 'ps', sd: 'sd',
};

async function tryMyMemory(text: string, target: string, source: string) {
  const src = source === 'auto' ? 'en' : LANG_MAP[source] || source;
  const tgt = LANG_MAP[target] || target;
  try {
    const url = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(text)}&langpair=${src}|${tgt}`;
    const res = await fetch(url, { signal: AbortSignal.timeout(8000) });
    if (!res.ok) return null;
    const data = await res.json();
    if (data?.responseStatus === 200 && data?.responseData?.translatedText) {
      return { text: data.responseData.translatedText };
    }
  } catch {}
  return null;
}

async function tryLibreTranslate(text: string, target: string, source: string) {
  const src = source === 'auto' ? 'auto' : LANG_MAP[source] || source;
  const tgt = LANG_MAP[target] || target;
  for (const url of [
    'https://libretranslate.com/translate',
    'https://translate.argosopentech.com/translate',
  ]) {
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ q: text, source: src, target: tgt, format: 'text' }),
        signal: AbortSignal.timeout(5000),
      });
      if (!res.ok) continue;
      const data = await res.json();
      if (data.translatedText) return { text: data.translatedText };
    } catch {}
  }
  return null;
}

async function tryPuter(text: string, target: string, source: string) {
  const token = process.env.PUTER_AUTH_TOKEN;
  if (!token) return null;
  try {
    const sourcePart = source === 'auto' ? '' : ` from ${source}`;
    const res = await fetch('https://api.puter.com/puterai/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        model: 'gpt-4.1',
        messages: [{ role: 'user', content: `Translate the following text${sourcePart} to ${target}. Output ONLY the translation:\n\n${text}` }],
      }),
      signal: AbortSignal.timeout(15000),
    });
    if (!res.ok) return null;
    const data = await res.json();
    const content = data?.choices?.[0]?.message?.content?.trim();
    if (content) return { text: content.replace(/^["']|["']$/g, '') };
  } catch {}
  return null;
}

export async function POST(req: NextRequest) {
  try {
    const { text, targetLang, sourceLang = 'auto' } = await req.json();
    if (!text?.trim()) {
      return Response.json({ error: 'Text is required' }, { status: 400 });
    }

    const result = (await tryPuter(text, targetLang, sourceLang))
      || (await tryMyMemory(text, targetLang, sourceLang))
      || (await tryLibreTranslate(text, targetLang, sourceLang));

    if (!result) {
      return Response.json({ error: 'Translation service unavailable. Try again.' }, { status: 503 });
    }

    return Response.json(result);
  } catch {
    return Response.json({ error: 'Translation failed' }, { status: 500 });
  }
}
