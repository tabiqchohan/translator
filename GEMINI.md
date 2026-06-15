"I want to build a complete Translator Application. The app must support Text, Voice, and Document translation. Please generate a full technical plan including features, tech stack, UI/UX layout, database design, and API routes. Below is the full requirement list:"

Text Translation

User enters text

Select source & target languages

Real-time output

Copy / Share option

Voice Translation

User speaks → convert speech to text

Translate text

Output as:

Text translation

Optional voice output using TTS (Text-to-Speech)

Document Translation

Upload PDF, Word, TXT or image (OCR)

Detect document language

Translate entire document

Allow user to download the translated version

User Interface (UI/UX)

Clean & minimal design

Three main tabs: Text | Voice | Documents

Language dropdown (source → target)

History page to save translations

Backend Requirements

API endpoint for text translation

API for speech-to-text

API for text-to-speech

Document parser + translator

Database to store translation history

Tech Stack

Frontend: React / Next.js Mobile: React Native optional

Backend: Node.js / Next.js API

Database: Neon / PostgreSQL

Translation API: Puter.js (free, unlimited, no API key — supports Grok, GPT, Claude, Gemini, etc.)

Speech API (STT/TTS): Puter.js AI Chat + Web Speech API (free) | Alternative: Whisper (OpenAI), Google STT

File parsing: PDFKit, Mammoth, Tesseract OCR

Extra Features

Auto language detection

Dark mode

Favorites list

Export translation as PDF / TXT

"Now generate the following:

Complete system design

Feature breakdown

API architecture

Database schema tables

Full UI wireframe description

Recommended libraries

Code structure in folders

Security best practices"

---

## Puter.js Integration (Free Translation)

### Setup
```bash
npm install @heyputer/puter.js
```
Ya CDN:
```html
<script src="https://js.puter.com/v2/"></script>
```

### Basic Translation Example
```javascript
import { puter } from '@heyputer/puter.js';

const text = "Hello, how are you?";
const targetLanguage = "Urdu";

puter.ai.chat(
  `Translate to ${targetLanguage}. Output only translation:\n\n${text}`,
  { model: 'gpt-4.1' }   // or 'x-ai/grok-4.3', 'claude-4', 'gemini-3.0-pro'
).then(response => {
  console.log(response);
});
```

### Key Benefits
- **Zero cost** — developer pays nothing, users cover their own AI usage
- **No API keys, no signup, no backend code**
- **500+ models** (Grok, GPT, Claude, Gemini, etc.)
- Translation, STT, TTS, OCR sab ke liye use kar sakte hain
- Scaling unlimited — jitne users utna free

---

## Complete System Design

### Architecture Overview
```
User (Browser)  →  Next.js App (Frontend)  →  Next.js API Routes (Backend)
                                                ↓
                                    Puter.js (Translation, STT, TTS)
                                                ↓
                                    PostgreSQL (Neon) — Translation History
```

### Data Flow
```
Text:   Input → Puter.js AI Chat → Display translation
Voice:  Mic → Web Speech API (STT) → Puter.js Translate → TTS → Audio output
Doc:    Upload file → Parse (PDFKit/Mammoth/Tesseract) → Puter.js Translate → Download
```

---

## Feature Breakdown

| Feature | Status | Priority |
|---------|--------|----------|
| Text Translation | ✅ Done | High |
| Language Selection (source → target) | ✅ Done | High |
| Copy / Share translated text | 🔜 Pending | Medium |
| Voice Translation (STT → Translate → TTS) | 🔜 Pending | High |
| Document Upload (PDF, Word, TXT, Image) | 🔜 Pending | High |
| Document OCR for images | 🔜 Pending | Medium |
| Download translated document | 🔜 Pending | Medium |
| Dark Mode | 🔜 Pending | Low |
| Translation History | 🔜 Pending | Medium |
| Favorites List | 🔜 Pending | Low |
| Auto Language Detection | 🔜 Pending | Medium |
| Export as PDF / TXT | 🔜 Pending | Low |
| Authentication (Google OAuth) | 🔜 Pending | Medium |

---

## Project Folder Structure

```
translater/
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── layout.tsx          # Root layout
│   │   ├── page.tsx            # Home page (translator)
│   │   ├── history/
│   │   │   └── page.tsx        # History page
│   │   ├── favorites/
│   │   │   └── page.tsx        # Favorites page
│   │   └── api/
│   │       ├── translate/
│   │       │   └── route.ts    # Text translation API
│   │       ├── speech-to-text/
│   │       │   └── route.ts    # STT API
│   │       ├── text-to-speech/
│   │       │   └── route.ts    # TTS API
│   │       ├── document/
│   │       │   └── route.ts    # Document upload + translate
│   │       └── history/
│   │           └── route.ts    # CRUD history
│   ├── components/
│   │   ├── TextTab.tsx         # Text translation tab
│   │   ├── VoiceTab.tsx        # Voice translation tab
│   │   ├── DocumentTab.tsx     # Document translation tab
│   │   ├── LanguageSelect.tsx  # Language dropdown pair
│   │   ├── TranslationCard.tsx # Output display card
│   │   └── ThemeToggle.tsx     # Dark mode toggle
│   ├── lib/
│   │   ├── puter.ts            # Puter.js client config
│   │   ├── db.ts               # Neon PostgreSQL connection
│   │   └── utils.ts            # Helper functions
│   ├── types/
│   │   └── index.ts            # TypeScript types
│   └── styles/
│       └── globals.css         # Global styles
├── public/                     # Static assets
├── package.json
├── tsconfig.json
├── tailwind.config.ts
├── next.config.ts
└── .env.local                  # Environment variables
```

---

## Database Schema (PostgreSQL via Neon)

### Table: `translations`
```sql
CREATE TABLE translations (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       TEXT NOT NULL DEFAULT 'anonymous',
  source_text   TEXT NOT NULL,
  translated_text TEXT NOT NULL,
  source_lang   VARCHAR(10) NOT NULL,
  target_lang   VARCHAR(10) NOT NULL,
  type          VARCHAR(20) NOT NULL DEFAULT 'text', -- 'text', 'voice', 'document'
  is_favorite   BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_translations_user_id ON translations(user_id);
CREATE INDEX idx_translations_created_at ON translations(created_at DESC);
```

### Table: `documents`
```sql
CREATE TABLE documents (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       TEXT NOT NULL DEFAULT 'anonymous',
  filename      TEXT NOT NULL,
  file_type     VARCHAR(20) NOT NULL, -- 'pdf', 'docx', 'txt', 'image'
  original_text TEXT,
  translated_text TEXT,
  source_lang   VARCHAR(10),
  target_lang   VARCHAR(10),
  file_url      TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);
```

---

## API Routes

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/translate` | Text translation (source, target, text) |
| POST | `/api/speech-to-text` | Convert audio → text (via Web Audio API) |
| POST | `/api/text-to-speech` | Convert text → audio URL |
| POST | `/api/document/upload` | Upload + parse document |
| POST | `/api/document/translate` | Translate parsed document |
| GET | `/api/history` | Get translation history |
| POST | `/api/history` | Save translation to history |
| DELETE | `/api/history/:id` | Delete history entry |
| PATCH | `/api/history/:id/favorite` | Toggle favorite |

---

## UI Wireframe Description

### Main Layout
```
┌─────────────────────────────────────────┐
│  Logo            Dark Mode Toggle  Avatar│
├─────────────────────────────────────────┤
│  [Text]  [Voice]  [Documents]  [History]│
├─────────────────────────────────────────┤
│                                         │
│  Source: [▼ English      ]  ⇄  Target: │
│         [▼ Urdu         ]              │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ Enter text here...              │    │
│  │                                 │    │
│  │                                 │    │
│  └─────────────────────────────────┘    │
│                                         │
│         [🔃 Translate]                 │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ Translated text appears here    │    │
│  │                         [📋][📤] │    │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

### Voice Tab
- Mic button (record/stop)
- Waveform visualization
- Translated text output
- 🔊 Speaker button for TTS

### Documents Tab
- Drag & drop upload area
- File type indicator
- Progress bar
- Download button

### History Page
- List of past translations (newest first)
- Search/filter
- Favorite toggle (⭐)
- Delete option

---

## Security Best Practices

1. **Input Sanitization** — Sanitize all user input before sending to Puter.js
2. **Rate Limiting** — Limit API calls per user/IP to prevent abuse
3. **HTTPS Only** — Enforce HTTPS in production
4. **Content Security Policy** — Restrict script sources
5. **File Validation** — Validate uploaded files (type, size limit — max 10MB)
6. **XSS Protection** — Escape output before rendering
7. **Environment Variables** — No secrets in code, use `.env.local`
8. **Authentication (optional)** — JWT or NextAuth.js for user sessions

---

## Environment Variables (.env.local)

```env
NEXT_PUBLIC_APP_URL=http://localhost:3000
DATABASE_URL=postgresql://...
NEXT_PUBLIC_PUTER_JS_CDN=https://js.puter.com/v2/
```

---

## Recommended Libraries (Detailed)

| Library | Purpose |
|---------|---------|
| next@15 | Framework (App Router) |
| @heyputer/puter.js | AI translation, STT, TTS |
| @neondatabase/serverless | PostgreSQL connection |
| pdf-parse | PDF text extraction |
| mammoth | DOCX text extraction |
| tesseract.js | OCR for images |
| tailwindcss | Styling |
| lucide-react | Icons |
| zustand | State management (optional) |
| next-themes | Dark mode |
| ky or axios | HTTP client"