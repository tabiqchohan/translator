import { createHash } from 'crypto';
import { neon } from '@neondatabase/serverless';

let neonSql: any = null;

async function getDb() {
  if (neonSql) return neonSql;
  const url = process.env.DATABASE_URL;
  if (!url) return null;
  try {
    neonSql = neon(url);
    return neonSql;
  } catch {
    return null;
  }
}

/** Entries older than this are ignored (and can be cleaned up periodically). */
const TTL_DAYS = Math.max(
  1,
  Number(process.env.TRANSLATION_CACHE_TTL_DAYS || 90)
);

/** Longer inputs are not cached (avoid storing whole documents). */
const MAX_LEN = Math.max(
  0,
  Number(process.env.TRANSLATION_CACHE_MAX_LEN || 1000)
);

function cacheHash(text: string, target: string, source: string): string {
  return createHash('sha256')
    .update(`${source}|${target}|${text}`)
    .digest('hex');
}

/**
 * Returns a previously stored translation, or null.
 * Fails open: any cache/DB problem simply means "no cache".
 */
export async function getCachedTranslation(
  text: string,
  target: string,
  source: string
): Promise<string | null> {
  if (MAX_LEN > 0 && text.length > MAX_LEN) return null;
  const db = await getDb();
  if (!db) return null;

  const hash = cacheHash(text, target, source);
  try {
    const rows = await db`
      SELECT translation
      FROM translation_cache
      WHERE hash = ${hash}
        AND created_at > NOW() - (${TTL_DAYS}::int * INTERVAL '1 day')
      LIMIT 1
    `;
    if (rows && rows.length > 0) {
      // Update hit stats without blocking the response.
      Promise.resolve(
        db`
          UPDATE translation_cache
          SET hits = hits + 1, last_used = NOW()
          WHERE hash = ${hash}
        `
      ).catch(() => {});
      return rows[0].translation as string;
    }
  } catch {
    // ignore
  }
  return null;
}

/** Stores a translation for reuse. Best effort, never throws. */
export async function cacheTranslation(
  text: string,
  target: string,
  source: string,
  translation: string
): Promise<void> {
  if (MAX_LEN > 0 && text.length > MAX_LEN) return;
  if (!translation || translation === text) return;

  const db = await getDb();
  if (!db) return;

  const hash = cacheHash(text, target, source);
  try {
    await db`
      INSERT INTO translation_cache (hash, source_lang, target_lang, translation)
      VALUES (${hash}, ${source}, ${target}, ${translation})
      ON CONFLICT (hash) DO UPDATE
        SET translation = EXCLUDED.translation,
            hits = translation_cache.hits + 1,
            last_used = NOW()
    `;
  } catch {
    // ignore
  }
}
