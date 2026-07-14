import { NextRequest } from 'next/server';

async function tryGoogleDirect(text: string, target: string, source: string) {
  try {
    const src = source === 'auto' ? 'auto' : source;
    const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=${src}&tl=${target}&dt=t&q=${encodeURIComponent(text)}`;
    const res = await fetch(url, { signal: AbortSignal.timeout(8000) });
    if (!res.ok) return null;
    const data = await res.json();
    const translated = data?.[0]?.map((s: any) => s?.[0] || '').filter(Boolean).join('');
    if (translated) return { text: translated };
  } catch {}
  return null;
}

async function tryMyMemory(text: string, target: string, source: string) {
  const src = source === 'auto' ? 'en' : source;
  try {
    const url = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(text)}&langpair=${src}|${target}`;
    const res = await fetch(url, { signal: AbortSignal.timeout(8000) });
    if (!res.ok) return null;
    const data = await res.json();
    if (data?.responseData?.translatedText) {
      return { text: data.responseData.translatedText };
    }
  } catch {}
  return null;
}

async function tryLibre(text: string, target: string, source: string) {
  for (const url of [
    'https://libretranslate.com/translate',
    'https://translate.argosopentech.com/translate',
  ]) {
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ q: text, source: source === 'auto' ? 'auto' : source, target, format: 'text' }),
        signal: AbortSignal.timeout(5000),
      });
      if (!res.ok) continue;
      const data = await res.json();
      if (data.translatedText) return { text: data.translatedText };
    } catch {}
  }
  return null;
}

export async function POST(req: NextRequest) {
  try {
    const { text, targetLang, sourceLang = 'auto' } = await req.json();

    if (!text?.trim()) {
      return Response.json({ error: 'Text is required' }, { status: 400 });
    }

    const target = targetLang;
    const source = sourceLang === 'auto' ? 'auto' : sourceLang;

    let result = await tryGoogleDirect(text, target, source);
    if (!result) result = await tryMyMemory(text, target, source);
    if (!result) result = await tryLibre(text, target, source);

    if (!result) {
      return Response.json({ error: 'Translation service unavailable' }, { status: 503 });
    }

    return Response.json(result);
  } catch {
    return Response.json({ error: 'Translation failed' }, { status: 500 });
  }
}
