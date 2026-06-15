let neonSql: any = null;

async function getDb() {
  if (neonSql) return neonSql;
  const url = process.env.DATABASE_URL;
  if (!url || url.startsWith('postgresql://your-')) return null;
  const { neon } = await import('@neondatabase/serverless');
  neonSql = neon(url);
  return neonSql;
}

export async function getTranslations(userId = 'anonymous') {
  const db = await getDb();
  if (!db) return [];
  return await db`SELECT * FROM translations WHERE user_id = ${userId} ORDER BY created_at DESC LIMIT 50`;
}

export async function saveTranslation(data: {
  userId?: string;
  sourceText: string;
  translatedText: string;
  sourceLang: string;
  targetLang: string;
  type?: string;
}) {
  const db = await getDb();
  if (!db) return null;
  const rows = await db`
    INSERT INTO translations (user_id, source_text, translated_text, source_lang, target_lang, type)
    VALUES (${data.userId ?? 'anonymous'}, ${data.sourceText}, ${data.translatedText}, ${data.sourceLang}, ${data.targetLang}, ${data.type ?? 'text'})
    RETURNING *
  `;
  return rows[0];
}

export async function toggleFavorite(id: string) {
  const db = await getDb();
  if (!db) return null;
  const rows = await db`UPDATE translations SET is_favorite = NOT is_favorite, updated_at = NOW() WHERE id = ${id} RETURNING *`;
  return rows[0];
}

export async function deleteTranslation(id: string) {
  const db = await getDb();
  if (!db) return;
  await db`DELETE FROM translations WHERE id = ${id}`;
}
