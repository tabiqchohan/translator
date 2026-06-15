import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const audio = formData.get('audio');

    if (!audio || !(audio instanceof Blob)) {
      return NextResponse.json({ error: 'audio file is required' }, { status: 400 });
    }

    const audioBuffer = Buffer.from(await audio.arrayBuffer());
    const base64Audio = audioBuffer.toString('base64');

    const response = await fetch('https://api.puter.com/ai/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: 'Transcribe this speech to text. Output only the transcription.' },
              { type: 'audio', data: base64Audio, format: audio.type },
            ],
          },
        ],
        model: 'gpt-4.1',
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      return NextResponse.json({ error: 'Speech-to-text failed', details: error }, { status: 500 });
    }

    const data = await response.json();
    const transcript = data?.message?.content ?? data?.response ?? '';

    return NextResponse.json({ text: transcript });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
