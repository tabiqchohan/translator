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

function mapRow(row: any) {
  if (!row) return row;
  return {
    id: row.id,
    userId: row.user_id,
    sourceText: row.source_text,
    translatedText: row.translated_text,
    sourceLang: row.source_lang,
    targetLang: row.target_lang,
    type: row.type,
    isFavorite: row.is_favorite,
    createdAt: row.created_at,
  };
}

export async function getTranslations(userId = 'anonymous') {
  try {
    const db = await getDb();
    if (!db) return [];
    const rows = await db`SELECT * FROM translations WHERE user_id = ${userId} ORDER BY created_at DESC LIMIT 50`;
    return (rows || []).map(mapRow);
  } catch {
    return [];
  }
}

export async function saveTranslation(data: {
  userId?: string;
  sourceText: string;
  translatedText: string;
  sourceLang: string;
  targetLang: string;
  type?: string;
}) {
  try {
    const db = await getDb();
    if (!db) return null;
    const rows = await db`
      INSERT INTO translations (user_id, source_text, translated_text, source_lang, target_lang, type)
      VALUES (${data.userId ?? 'anonymous'}, ${data.sourceText}, ${data.translatedText}, ${data.sourceLang}, ${data.targetLang}, ${data.type ?? 'text'})
      RETURNING *
    `;
    return mapRow(rows?.[0]) ?? null;
  } catch {
    return null;
  }
}

export async function toggleFavorite(id: string) {
  try {
    const db = await getDb();
    if (!db) return null;
    const rows = await db`UPDATE translations SET is_favorite = NOT is_favorite, updated_at = NOW() WHERE id = ${id} RETURNING *`;
    return mapRow(rows?.[0]) ?? null;
  } catch {
    return null;
  }
}

export async function deleteTranslation(id: string) {
  try {
    const db = await getDb();
    if (!db) return;
    await db`DELETE FROM translations WHERE id = ${id}`;
  } catch {}
}

export async function deleteUserTranslations(userId: string) {
  try {
    const db = await getDb();
    if (!db) return;
    await db`DELETE FROM translations WHERE user_id = ${userId}`;
  } catch {}
}
