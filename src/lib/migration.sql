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
