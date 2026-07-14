import { NextRequest } from 'next/server';
import { translate } from '@vitalets/google-translate-api';

export async function POST(req: NextRequest) {
  try {
    const { text, targetLang, sourceLang = 'auto' } = await req.json();

    if (!text?.trim()) {
      return Response.json({ error: 'Text is required' }, { status: 400 });
    }

    const from = sourceLang === 'auto' ? 'auto' : sourceLang;
    const to = targetLang;

    const result = await translate(text, { from, to });
    return Response.json({ text: result.text });
  } catch (err: any) {
    const msg = err?.message || 'Translation failed';
    return Response.json({ error: msg }, { status: 500 });
  }
}
