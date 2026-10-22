import { NextRequest } from 'next/server';
import { auth } from '@/auth';
import { getUserPlan } from '@/lib/auth-db';
import {
  consumeQuota,
  releaseQuota,
  FREE_DAILY_LIMIT,
  ANON_DAILY_LIMIT,
} from '@/lib/quota';
import {
  getCachedTranslation,
  cacheTranslation,
} from '@/lib/translation-cache';

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

const GROQ_MODEL = 'llama-3.3-70b-versatile';

/** Gemini models to try in order; override the first with GEMINI_MODEL. */
function geminiModels(): string[] {
  const configured = (process.env.GEMINI_MODEL || '').trim();
  return [
    configured,
    'gemini-flash-latest',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
  ].filter((m, i, arr) => !!m && arr.indexOf(m) === i);
}

/** Shared, tone-preserving instruction used by every LLM provider. */
function buildTranslatePrompt(
  text: string,
  target: string,
  source: string,
): string {
  const targetName = nameOf(target);
  const sourcePart = source === 'auto' ? '' : ` from ${nameOf(source)}`;
  return [
    `Translate the following text${sourcePart} to ${targetName}.`,
    '',
    'Rules:',
    '- Output ONLY the translation. No notes, no quotes, no explanation.',
    '- Preserve the tone and register of the original (casual stays casual, formal stays formal).',
    '- If the source is Roman Urdu, Hinglish or mixed English, output natural,',
    '  conversational text - do NOT make it formal, literary or word-for-word stiff.',
    '- Keep names, numbers, emoji, hashtags and line breaks unchanged.',
    '- If the text is already in the target language, return it unchanged.',
    '',
    text,
  ].join('\n');
}

/** Reads one or more env vars into a list of non-empty keys. */
function envKeys(...names: string[]): string[] {
  return names
    .map((n) => process.env[n])
    .filter((v): v is string => typeof v === 'string' && v.trim().length > 0);
}

/** Strips model chatter / wrapping quotes from a raw translation. */
function cleanTranslation(raw: string): string {
  let t = raw.trim();
  t = t.replace(/^(translated text|translation|translated)\s*[:\-–]\s*/i, '');
  t = t.replace(/^["'`“”]+/, '').replace(/["'`“”]+$/, '').trim();
  return t;
}

type TranslateFn = (
  text: string,
  target: string,
  source: string,
  key: string | null,
) => Promise<string | null>;

interface Provider {
  name: string;
  requiresKey: boolean;
  keys: string[];
  translate: TranslateFn;
}

// ---------------------------------------------------------------- providers

/**
 * Primary provider. Best quality for Roman Urdu / Hinglish and the only one
 * that reliably covers all 56 target languages.
 */
async function tryGroq(
  text: string,
  target: string,
  source: string,
  key: string | null,
): Promise<string | null> {
  if (!key) return null;
  const prompt = buildTranslatePrompt(text, target, source);

  try {
    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${key}`,
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        temperature: 0.2,
        max_tokens: 2048,
        messages: [{ role: 'user', content: prompt }],
      }),
      signal: AbortSignal.timeout(15000),
    });
    if (!res.ok) {
      console.warn(`[translate] groq http ${res.status}`);
      return null;
    }
    const data = await res.json();
    const content = cleanTranslation(data?.choices?.[0]?.message?.content ?? '');
    if (content && content !== text) return content;
  } catch (e) {
    console.warn(`[translate] groq error: ${e instanceof Error ? e.message : e}`);
  }
  return null;
}

/** Google Gemini (AI Studio key) - strong Roman Urdu / Hinglish quality. */
async function tryGemini(
  text: string,
  target: string,
  source: string,
  key: string | null,
): Promise<string | null> {
  if (!key) return null;
  const prompt = buildTranslatePrompt(text, target, source);
  const body = JSON.stringify({
    contents: [{ parts: [{ text: prompt }] }],
    generationConfig: { temperature: 0.2, maxOutputTokens: 2048 },
  });

  for (const model of geminiModels()) {
    try {
      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${key}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body,
          signal: AbortSignal.timeout(15000),
        }
      );
      // Model name not available for this key - try the next one.
      if (res.status === 404) continue;
      if (!res.ok) {
        console.warn(`[translate] gemini http ${res.status} (${model})`);
        return null;
      }
      const data = await res.json();
      const raw = (data?.candidates?.[0]?.content?.parts ?? [])
        .map((p: any) => p?.text || '')
        .join('');
      const out = cleanTranslation(raw);
      if (out && out !== text) return out;
      return null;
    } catch (e) {
      console.warn(
        `[translate] gemini error (${model}): ${e instanceof Error ? e.message : e}`
      );
    }
  }
  return null;
}

/** Official Google Cloud Translation v2 (needs GOOGLE_TRANSLATE_API_KEY). */
async function tryGoogleCloud(
  text: string,
  target: string,
  source: string,
  key: string | null,
): Promise<string | null> {
  if (!key) return null;
  try {
    const body: Record<string, string> = { q: text, target, format: 'text' };
    if (source && source !== 'auto') body.source = source;
    const res = await fetch(
      'https://translation.googleapis.com/language/translate/v2',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-Goog-Api-Key': key },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(8000),
      }
    );
    if (!res.ok) {
      console.warn(`[translate] google-cloud http ${res.status}`);
      return null;
    }
    const data = await res.json();
    const t = cleanTranslation(data?.data?.translations?.[0]?.translatedText ?? '');
    if (t && t !== text) return t;
  } catch (e) {
    console.warn(
      `[translate] google-cloud error: ${e instanceof Error ? e.message : e}`
    );
  }
  return null;
}

/** Unofficial Google endpoint — no key, no signup, good coverage. */
async function tryGoogleGtx(
  text: string,
  target: string,
  source: string,
): Promise<string | null> {
  try {
    const src = source === 'auto' ? 'auto' : source;
    const params = new URLSearchParams({
      client: 'gtx',
      sl: src,
      tl: target,
      dt: 't',
      q: text,
    });
    const res = await fetch(
      `https://translate.googleapis.com/translate_a/single?${params.toString()}`,
      {
        headers: { 'User-Agent': 'Mozilla/5.0' },
        signal: AbortSignal.timeout(8000),
      }
    );
    if (!res.ok) return null;
    const raw = await res.text();
    if (raw.includes('<html') || !raw.startsWith('[[')) return null;
    const data = JSON.parse(raw);
    const translated = data?.[0]
      ?.map((s: any) => s?.[0] || '')
      .filter(Boolean)
      .join('');
    if (translated && translated !== text) return cleanTranslation(translated);
  } catch {}
  return null;
}

/** Last-resort community memory (limited characters/day). */
async function tryMyMemory(
  text: string,
  target: string,
  source: string,
): Promise<string | null> {
  const src = source === 'auto' ? 'en' : source;
  try {
    const res = await fetch(
      `https://api.mymemory.translated.net/get?q=${encodeURIComponent(text)}&langpair=${src}|${target}`,
      { signal: AbortSignal.timeout(8000) }
    );
    if (!res.ok) return null;
    const data = await res.json();
    const t = data?.responseData?.translatedText;
    if (t && t !== text && !t.includes('<html') && !t.includes('MYMEMORY')) {
      return cleanTranslation(t);
    }
  } catch {}
  return null;
}

/**
 * Provider order. Each provider may hold several keys; the next key is tried
 * when one fails (rotated keys, 401s or 429 rate limits).
 *
 * NOTE: Groq rate limits are per account/project, not per key — a second key
 * from the same account only guards against a revoked key. Use a second
 * account for real extra capacity. Gemini free tier is per project as well.
 */
const providers: Provider[] = [
  {
    name: 'groq',
    requiresKey: true,
    keys: envKeys('GROQ_API_KEY', 'GROQ_API_KEY_2', 'GROQ_API_KEY_3'),
    translate: tryGroq,
  },
  {
    name: 'gemini',
    requiresKey: true,
    keys: envKeys('GEMINI_API_KEY', 'GEMINI_API_KEY_2'),
    translate: tryGemini,
  },
  {
    name: 'google-cloud',
    requiresKey: true,
    keys: envKeys('GOOGLE_TRANSLATE_API_KEY', 'GOOGLE_TRANSLATE_API_KEY_2'),
    translate: tryGoogleCloud,
  },
  { name: 'google-gtx', requiresKey: false, keys: [], translate: tryGoogleGtx },
  { name: 'mymemory', requiresKey: false, keys: [], translate: tryMyMemory },
];

async function translateWithFailover(text: string, target: string, source: string) {
  const failures: string[] = [];

  for (const p of providers) {
    if (p.requiresKey && p.keys.length === 0) {
      failures.push(`${p.name}:no-key`);
      continue;
    }
    const keys: (string | null)[] = p.keys.length > 0 ? p.keys : [null];
    for (const key of keys) {
      try {
        const out = await p.translate(text, target, source, key);
        if (out && out !== text) {
          console.log(`[translate] served-by=${p.name}`);
          return { text: out, provider: p.name };
        }
        failures.push(`${p.name}:empty`);
      } catch (e) {
        failures.push(`${p.name}:error`);
        console.warn(
          `[translate] ${p.name} failed: ${e instanceof Error ? e.message : e}`
        );
      }
    }
  }

  console.warn(`[translate] all providers failed -> ${failures.join(', ')}`);
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
          }
        );
      }
    }

    // ---- Serve repeated phrases from cache (no provider call = no cost) ----
    const cached = await getCachedTranslation(text, targetLang, sourceLang);
    if (cached) {
      console.log('[translate] served-by=cache');
      return Response.json({ text: cached, provider: 'cache' });
    }

    const result = await translateWithFailover(text, targetLang, sourceLang);

    if (!result) {
      // The request failed on every provider - don't burn the user's quota.
      if (subject && limit > 0) await releaseQuota(subject);
      return Response.json(
        {
          error: 'UNAVAILABLE',
          message:
            'Translation is temporarily unavailable. Please try again in a moment.',
        },
        { status: 503 }
      );
    }

    await cacheTranslation(text, targetLang, sourceLang, result.text);
    return Response.json(result);
  } catch {
    return Response.json({ error: 'Translation failed' }, { status: 500 });
  }
}
