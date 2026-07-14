import { NextRequest } from 'next/server';
import { translate } from '@vitalets/google-translate-api';

const LANG_MAP: Record<string, string> = {
  en: 'en', es: 'es', fr: 'fr', de: 'de', it: 'it', pt: 'pt',
  ru: 'ru', ar: 'ar', hi: 'hi', ur: 'ur', bn: 'bn', zh: 'zh',
  ja: 'ja', ko: 'ko', tr: 'tr', vi: 'vi', th: 'th', id: 'id',
  ms: 'ms', nl: 'nl', sv: 'sv', pl: 'pl', uk: 'uk', ro: 'ro',
  cs: 'cs', el: 'el', he: 'he', fa: 'fa', tl: 'tl', pa: 'pa',
  ps: 'ps', sd: 'sd',
};

export async function POST(req: NextRequest) {
  try {
    const { text, targetLang, sourceLang = 'auto' } = await req.json();

    if (!text?.trim()) {
      return Response.json({ error: 'Text is required' }, { status: 400 });
    }

    const from = sourceLang === 'auto' ? 'auto' : LANG_MAP[sourceLang] || sourceLang;
    const to = LANG_MAP[targetLang] || targetLang;

    const result = await translate(text, { from, to });
    return Response.json({ text: result.text });
  } catch {
    return Response.json({ error: 'Translation failed' }, { status: 500 });
  }
}
