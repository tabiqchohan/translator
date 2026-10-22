-- ============================================
-- TRANSLATER - Complete Database Schema
-- ============================================

-- Users table (for auth)
CREATE TABLE IF NOT EXISTS users (
  id              TEXT PRIMARY KEY,
  name            TEXT,
  email           TEXT UNIQUE NOT NULL,
  password_hash   TEXT NOT NULL,
  email_verified  TIMESTAMPTZ,
  image           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Sessions table (for auth)
CREATE TABLE IF NOT EXISTS sessions (
  id              TEXT PRIMARY KEY,
  user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires         TIMESTAMPTZ NOT NULL,
  session_token   TEXT UNIQUE NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_session_token ON sessions(session_token);

-- Verification tokens (for password reset)
CREATE TABLE IF NOT EXISTS verification_tokens (
  identifier    TEXT NOT NULL,
  token         TEXT NOT NULL,
  expires       TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (identifier, token)
);

-- Translations table
CREATE TABLE IF NOT EXISTS translations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         TEXT NOT NULL DEFAULT 'anonymous',
  source_text     TEXT NOT NULL,
  translated_text TEXT NOT NULL,
  source_lang     VARCHAR(10) NOT NULL,
  target_lang     VARCHAR(10) NOT NULL,
  type            VARCHAR(20) NOT NULL DEFAULT 'text',
  is_favorite     BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_translations_user_id ON translations(user_id);
CREATE INDEX IF NOT EXISTS idx_translations_created_at ON translations(created_at DESC);

-- Documents table
CREATE TABLE IF NOT EXISTS documents (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         TEXT NOT NULL DEFAULT 'anonymous',
  filename        TEXT NOT NULL,
  file_type       VARCHAR(20) NOT NULL,
  original_text   TEXT,
  translated_text TEXT,
  source_lang     VARCHAR(10),
  target_lang     VARCHAR(10),
  file_url        TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Plan / subscription fields (monetization)
ALTER TABLE users ADD COLUMN IF NOT EXISTS plan TEXT NOT NULL DEFAULT 'free';
ALTER TABLE users ADD COLUMN IF NOT EXISTS plan_expires TIMESTAMPTZ;

-- Daily usage counter (free-tier quota). One row per subject per day.
CREATE TABLE IF NOT EXISTS usage_daily (
  subject     TEXT NOT NULL,
  day         DATE NOT NULL DEFAULT CURRENT_DATE,
  count       INTEGER NOT NULL DEFAULT 0,
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (subject, day)
);

CREATE INDEX IF NOT EXISTS idx_usage_daily_day ON usage_daily(day);

-- Shared translation cache. Repeated phrases (very common in chats) are served
-- from here instead of calling an AI provider, cutting cost and latency.
CREATE TABLE IF NOT EXISTS translation_cache (
  hash          TEXT PRIMARY KEY,
  source_lang   VARCHAR(10) NOT NULL,
  target_lang   VARCHAR(10) NOT NULL,
  translation   TEXT NOT NULL,
  hits          INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_used     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_translation_cache_last_used ON translation_cache(last_used);
CREATE INDEX IF NOT EXISTS idx_translation_cache_created_at ON translation_cache(created_at);
