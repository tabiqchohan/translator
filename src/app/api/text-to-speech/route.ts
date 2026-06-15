import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { text } = await request.json();

    if (!text) {
      return NextResponse.json({ error: 'text is required' }, { status: 400 });
    }

    const response = await fetch('https://api.puter.com/ai/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        messages: [
          {
            role: 'user',
            content: `Read the following text aloud. Generate a spoken audio version:\n\n${text}`,
          },
        ],
        model: 'gpt-4.1',
        response_format: { type: 'audio' },
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      return NextResponse.json({ error: 'TTS failed', details: error }, { status: 500 });
    }

    const data = await response.json();
    const audioUrl = data?.audio?.url ?? null;

    return NextResponse.json({ audioUrl });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
