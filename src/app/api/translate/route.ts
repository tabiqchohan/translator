import { NextRequest } from 'next/server';
import { auth } from '@/auth';
import { getUserPlan } from '@/lib/auth-db';
import {
  consumeQuota,
  FREE_DAILY_LIMIT,
  ANON_DAILY_LIMIT,
} from '@/lib/quota';

const langNames: Record<string, string> = {
  en: 'English', ur: 'Urdu', hi: 'Hindi', es: 'Spanish', fr: 'French',
  de: 'German', zh: 'Chinese (Simplified)', 'zh-TW': 'Chinese (Traditional)',
  ja: 'Japanese', ko: 'Korean', ar: 'Arabic', pt: 'Portuguese', ru: 'Russian',
  tr: 'Turkish', it: 'Italian', nl: 'Dutch', pl: 'Polish', sv: 'Swedish',
  da: 'Danish', fi: 'Finnish', th: 'Thai', vi: 'Vietnamese', ms: 'Malay',
  id: 'Indonesian', bn: 'Bengali', pa: 'Punjabi', fa: 'Persian (Farsi)',
  ps: 'Pashto', sd: 'Sindhi', ta: 'Tamil', te: 'Telugu', mr: 'Marathi',
  gu: 'Gujarati', kn: 'Kannada', ml: 'Malayalam', ne: 'Nepali', si: 'Sinhala',
  my: 'Burmese (Myanmar)', km: 'Khmer', tl: 'Tagalog (Filipino)',
  uk: 'Ukrainian', cs: 'Czech', el: 'Greek', he: 'Hebrew', ro: 'Romanian',
  hu: 'Hungarian', no: 'Norwegian', sk: 'Slovak', bg: 'Bulgarian',
  hr: 'Croatian', sr: 'Serbian', sw: 'Swahili', af: 'Afrikaans',
  az: 'Azerbaijani', uz: 'Uzbek', kk: 'Kazakh',
};

function nameOf(code: string) {
  return langNames[code] || code;
}

async function tryGroq(text: string, target: string, source: string) {
  const token = process.env.GROQ_API_KEY;
  if (!token) return { missingToken: true };

  try {
    const targetName = nameOf(target);
    const sourcePart = source === 'auto' ? '' : ` from ${nameOf(source)}`;
    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: [{ role: 'user', content: `Translate the following text${sourcePart} to ${targetName}. Output ONLY the translation, nothing else:\n\n${text}` }],
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

function clientIp(req: NextRequest): string {
  return (
    req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ||
    req.headers.get('x-real-ip') ||
    'unknown'
  );
}

export async function POST(req: NextRequest) {
  try {
    const { text, targetLang, sourceLang = 'auto' } = await req.json();
    if (!text?.trim()) {
      return Response.json({ error: 'Text is required' }, { status: 400 });
    }
    if (!targetLang) {
      return Response.json({ error: 'targetLang is required' }, { status: 400 });
    }

    // ---- Identify caller + enforce daily free quota ----
    const session = await auth();
    const userId = session?.user?.id;

    let subject: string | null = null;
    let limit = 0; // 0 = unlimited

    if (userId) {
      const plan = await getUserPlan(userId);
      if (plan !== 'pro') {
        subject = `user:${userId}`;
        limit = FREE_DAILY_LIMIT;
      }
    } else {
      subject = `ip:${clientIp(req)}`;
      limit = ANON_DAILY_LIMIT;
    }

    if (subject && limit > 0) {
      const q = await consumeQuota(subject, limit);
      if (!q.allowed) {
        return Response.json(
          {
            error: 'QUOTA_EXCEEDED',
            message:
              'Today\'s free translation limit is reached. Upgrade to Pro for unlimited translations, or try again tomorrow.',
            limit: q.limit,
            used: q.used,
          },
          {
            status: 429,
            headers: {
              'X-Quota-Limit': String(q.limit),
              'X-Quota-Used': String(q.used),
            },
          },
        );
      }
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
