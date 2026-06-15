export function classNames(...classes: (string | boolean | undefined | null)[]): string {
  return classes.filter(Boolean).join(' ');
}

export const languages = [
  { code: 'auto', name: 'Auto Detect' },
  { code: 'en', name: 'English' },
  { code: 'ur', name: 'Urdu' },
  { code: 'hi', name: 'Hindi' },
  { code: 'es', name: 'Spanish' },
  { code: 'fr', name: 'French' },
  { code: 'de', name: 'German' },
  { code: 'zh', name: 'Chinese' },
  { code: 'ja', name: 'Japanese' },
  { code: 'ko', name: 'Korean' },
  { code: 'ar', name: 'Arabic' },
  { code: 'pt', name: 'Portuguese' },
  { code: 'ru', name: 'Russian' },
  { code: 'tr', name: 'Turkish' },
  { code: 'it', name: 'Italian' },
  { code: 'nl', name: 'Dutch' },
  { code: 'pl', name: 'Polish' },
  { code: 'sv', name: 'Swedish' },
  { code: 'da', name: 'Danish' },
  { code: 'fi', name: 'Finnish' },
  { code: 'th', name: 'Thai' },
  { code: 'vi', name: 'Vietnamese' },
  { code: 'ms', name: 'Malay' },
  { code: 'id', name: 'Indonesian' },
] as const;

export const fileTypes = [
  { value: 'pdf', label: 'PDF', accept: '.pdf', mime: 'application/pdf' },
  { value: 'docx', label: 'Word', accept: '.docx,.doc', mime: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' },
  { value: 'txt', label: 'Text', accept: '.txt', mime: 'text/plain' },
  { value: 'image', label: 'Image (OCR)', accept: '.png,.jpg,.jpeg,.webp', mime: 'image/*' },
] as const;
