export interface TranslationRequest {
  text: string;
  sourceLang: string;
  targetLang: string;
}

export interface TranslationResponse {
  translatedText: string;
  detectedLang?: string;
}

export interface HistoryEntry {
  id: string;
  userId: string;
  sourceText: string;
  translatedText: string;
  sourceLang: string;
  targetLang: string;
  type: 'text' | 'voice' | 'document' | 'camera';
  isFavorite: boolean;
  createdAt: string;
}

export interface DocumentUpload {
  id: string;
  filename: string;
  fileType: string;
  originalText?: string;
  translatedText?: string;
  sourceLang?: string;
  targetLang?: string;
  fileUrl?: string;
  createdAt: string;
}

export type TabType = 'text' | 'voice' | 'camera' | 'documents';

export interface Language {
  code: string;
  name: string;
}
