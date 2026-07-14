import { NextRequest } from 'next/server';

async function tryGoogle(text: string, target: string, source: string) {
  try {
    const params = new URLSearchParams({
      sl: source === 'auto' ? 'auto' : source,
      tl: target,
      q: text,
    });
    const url = `https://translate.google.com/translate_a/single?client=at&dt=t&dt=rm&dj=1`;
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
        'User-Agent': 'Mozilla/5.0',
        Referer: 'https://translate.google.com/',
      },
      body: params.toString(),
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) return null;
    const data = await res.json();
    const translated = data?.sentences
      ?.filter((s: any) => s?.trans)
      .map((s: any) => s.trans)
      .join('');
    if (translated && translated !== text) return { text: translated };
  } catch {}
  return null;
}

async function tryMyMemory(text: string, target: string, source: string) {
  const src = source === 'auto' ? 'en' : source;
  try {
    const url = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(text)}&langpair=${src}|${target}&de=translater@app.com`;
    const res = await fetch(url, { signal: AbortSignal.timeout(8000) });
    if (!res.ok) return null;
    const data = await res.json();
    if (data?.responseData?.translatedText) {
      const t = data.responseData.translatedText;
      if (t !== text) return { text: t };
    }
  } catch {}
  return null;
}

export async function POST(req: NextRequest) {
  try {
    const { text, targetLang, sourceLang = 'auto' } = await req.json();
    if (!text?.trim()) {
      return Response.json({ error: 'Text is required' }, { status: 400 });
    }

    const result = await tryGoogle(text, targetLang, sourceLang)
      || await tryMyMemory(text, targetLang, sourceLang);

    if (!result) {
      return Response.json({ error: 'Translation unavailable' }, { status: 503 });
    }

    return Response.json(result);
  } catch {
    return Response.json({ error: 'Translation failed' }, { status: 500 });
  }
}
