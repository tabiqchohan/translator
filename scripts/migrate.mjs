import { neon } from '@neondatabase/serverless';
import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const sql = neon(process.env.DATABASE_URL);

const migration = readFileSync(resolve(__dirname, '../src/lib/migration.sql'), 'utf-8');

// Split by semicolons, handling multi-line statements
const statements = migration
  .split('\n')
  .filter(line => !line.trim().startsWith('--') && !line.trim().startsWith('#'))
  .join('\n')
  .split(';')
  .map(s => s.trim())
  .filter(s => s.length > 0);

for (const stmt of statements) {
  try {
    await sql(stmt + ';');
    console.log('OK');
  } catch (err) {
    console.error('FAIL:', err.message.slice(0, 80));
  }
}

console.log('Migration complete');
