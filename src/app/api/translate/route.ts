import { NextRequest } from 'next/server';

async function tryGroq(text: string, target: string, source: string) {
  const token = process.env.GROQ_API_KEY;
  if (!token) return { missingToken: true };

  try {
    const sourcePart = source === 'auto' ? '' : ` from ${source}`;
    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        model: 'mixtral-8x7b-32768',
        messages: [{ role: 'user', content: `Translate the following text${sourcePart} to ${target}. Output ONLY the translation, nothing else:\n\n${text}` }],
      }),
      signal: AbortSignal.timeout(15000),
    });
    if (!res.ok) return null;
    const data = await res.json();
    let content = data?.choices?.[0]?.message?.content?.trim();
    if (content) {
      content = content.replace(/^["']|["']$/g, '');
      if (content && content !== text) return { text: content };
    }
  } catch {}
  return null;
}

async function tryGoogle(text: string, target: string, source: string) {
  try {
    const src = source === 'auto' ? 'auto' : source;
    const params = new URLSearchParams({ client: 'gtx', sl: src, tl: target, dt: 't', q: text });
    const res = await fetch(`https://translate.googleapis.com/translate_a/single?${params.toString()}`, {
      headers: { 'User-Agent': 'Mozilla/5.0' },
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) return null;
    const raw = await res.text();
    if (raw.includes('<html') || !raw.startsWith('[[')) return null;
    const data = JSON.parse(raw);
    const translated = data?.[0]?.map((s: any) => s?.[0] || '').filter(Boolean).join('');
    if (translated && translated !== text) return { text: translated };
  } catch {}
  return null;
}

async function tryMyMemory(text: string, target: string, source: string) {
  const src = source === 'auto' ? 'en' : source;
  try {
    const res = await fetch(
      `https://api.mymemory.translated.net/get?q=${encodeURIComponent(text)}&langpair=${src}|${target}`,
      { signal: AbortSignal.timeout(8000) }
    );
    if (!res.ok) return null;
    const data = await res.json();
    const t = data?.responseData?.translatedText;
    if (t && t !== text && !t.includes('<html') && !t.includes('MYMEMORY')) return { text: t };
  } catch {}
  return null;
}

export async function POST(req: NextRequest) {
  try {
    const { text, targetLang, sourceLang = 'auto' } = await req.json();
    if (!text?.trim()) {
      return Response.json({ error: 'Text is required' }, { status: 400 });
    }

    const groqResult = await tryGroq(text, targetLang, sourceLang);
    if (groqResult?.missingToken) {
      return Response.json({ error: 'SETUP_TOKEN' }, { status: 503 });
    }
    if (groqResult) return Response.json(groqResult);

    const result = await tryGoogle(text, targetLang, sourceLang)
      || await tryMyMemory(text, targetLang, sourceLang);

    if (!result) return Response.json({ error: 'UNAVAILABLE' }, { status: 503 });
    return Response.json(result);
  } catch {
    return Response.json({ error: 'Translation failed' }, { status: 500 });
  }
}
