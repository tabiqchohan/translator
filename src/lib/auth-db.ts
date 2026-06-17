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

export async function findUserByEmail(email: string) {
  try {
    const db = await getDb();
    if (!db) return null;
    const rows = await db`SELECT * FROM users WHERE LOWER(email) = ${email.toLowerCase()} LIMIT 1`;
    return rows?.[0] ?? null;
  } catch {
    return null;
  }
}

export async function findUserById(id: string) {
  try {
    const db = await getDb();
    if (!db) return null;
    const rows = await db`SELECT id, name, email, email_verified, image, created_at FROM users WHERE id = ${id} LIMIT 1`;
    return rows?.[0] ?? null;
  } catch {
    return null;
  }
}

export async function createUser(data: { id: string; name: string; email: string; passwordHash: string }) {
  try {
    const db = await getDb();
    if (!db) return null;
    const rows = await db`
      INSERT INTO users (id, name, email, password_hash)
      VALUES (${data.id}, ${data.name}, ${data.email.toLowerCase()}, ${data.passwordHash})
      RETURNING id, name, email, created_at
    `;
    return rows?.[0] ?? null;
  } catch {
    return null;
  }
}

export async function updatePassword(email: string, passwordHash: string) {
  try {
    const db = await getDb();
    if (!db) return;
    await db`UPDATE users SET password_hash = ${passwordHash}, updated_at = NOW() WHERE LOWER(email) = ${email.toLowerCase()}`;
  } catch {}
}

export async function createVerificationToken(identifier: string, token: string, expires: Date) {
  try {
    const db = await getDb();
    if (!db) return;
    await db`
      INSERT INTO verification_tokens (identifier, token, expires)
      VALUES (${identifier}, ${token}, ${expires.toISOString()})
      ON CONFLICT (identifier, token) DO UPDATE SET expires = ${expires.toISOString()}
    `;
  } catch {}
}

export async function findVerificationToken(identifier: string, token: string) {
  try {
    const db = await getDb();
    if (!db) return null;
    const rows = await db`SELECT * FROM verification_tokens WHERE identifier = ${identifier} AND token = ${token} LIMIT 1`;
    return rows?.[0] ?? null;
  } catch {
    return null;
  }
}

export async function deleteVerificationToken(identifier: string, token: string) {
  try {
    const db = await getDb();
    if (!db) return;
    await db`DELETE FROM verification_tokens WHERE identifier = ${identifier} AND token = ${token}`;
  } catch {}
}

export async function createSession(session: { id: string; userId: string; sessionToken: string; expires: Date }) {
  try {
    const db = await getDb();
    if (!db) return;
    await db`INSERT INTO sessions (id, user_id, session_token, expires) VALUES (${session.id}, ${session.userId}, ${session.sessionToken}, ${session.expires.toISOString()})`;
  } catch {}
}
