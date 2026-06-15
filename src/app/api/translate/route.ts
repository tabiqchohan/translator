import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { text, sourceLang, targetLang } = await request.json();

    if (!text || !targetLang) {
      return NextResponse.json(
        { error: 'text and targetLang are required' },
        { status: 400 }
      );
    }

    const source = sourceLang && sourceLang !== 'auto' ? ` from ${sourceLang}` : '';
    const prompt = `Translate the following text${source} to ${targetLang}. Output only the translation, nothing else:\n\n${text}`;

    const response = await fetch('https://api.puter.com/ai/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        messages: [{ role: 'user', content: prompt }],
        model: 'gpt-4.1',
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      return NextResponse.json({ error: 'Translation failed', details: error }, { status: 500 });
    }

    const data = await response.json();
    const translatedText = data?.message?.content ?? data?.response ?? '';

    return NextResponse.json({ translatedText });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
