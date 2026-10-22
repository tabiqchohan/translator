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

/** Free daily translation allowance for logged-in users. */
export const FREE_DAILY_LIMIT = Number(process.env.FREE_DAILY_LIMIT || 50);

/** Daily allowance for anonymous / device requests (covers Live Chat). */
export const ANON_DAILY_LIMIT = Number(process.env.ANON_DAILY_LIMIT || 100);

export interface QuotaResult {
  allowed: boolean;
  limit: number;
  used: number;
  remaining: number;
}

/**
 * Atomically consume one unit of today's quota for `subject`.
 *
 * The INSERT ... ON CONFLICT DO UPDATE ... WHERE count < limit returns a row
 * only when the increment actually happened, so a single round trip both
 * checks and increments without race conditions.
 *
 * Fails open (allowed) if the database is unavailable, so a DB hiccup never
 * takes translation offline.
 */
export async function consumeQuota(
  subject: string,
  limit: number,
): Promise<QuotaResult> {
  const db = await getDb();
  if (!db) return { allowed: true, limit, used: 0, remaining: limit };

  try {
    const rows = await db`
      INSERT INTO usage_daily (subject, day, count)
      VALUES (${subject}, CURRENT_DATE, 1)
      ON CONFLICT (subject, day)
      DO UPDATE SET count = usage_daily.count + 1, updated_at = NOW()
      WHERE usage_daily.count < ${limit}
      RETURNING count
    `;
    if (rows && rows.length > 0) {
      const used = Number(rows[0].count);
      return { allowed: true, limit, used, remaining: Math.max(0, limit - used) };
    }
    return { allowed: false, limit, used: limit, remaining: 0 };
  } catch {
    return { allowed: true, limit, used: 0, remaining: limit };
  }
}

export async function usageToday(subject: string): Promise<number> {
  try {
    const db = await getDb();
    if (!db) return 0;
    const rows = await db`
      SELECT count FROM usage_daily WHERE subject = ${subject} AND day = CURRENT_DATE LIMIT 1
    `;
    return Number(rows?.[0]?.count || 0);
  } catch {
    return 0;
  }
}

/**
 * Give one unit of quota back. Used when a translation fails on every
 * provider so the user is not charged for a request that produced nothing.
 */
export async function releaseQuota(subject: string): Promise<void> {
  const db = await getDb();
  if (!db) return;
  try {
    await db`
      UPDATE usage_daily
      SET count = GREATEST(count - 1, 0), updated_at = NOW()
      WHERE subject = ${subject} AND day = CURRENT_DATE
    `;
  } catch {
    // best effort
  }
}
