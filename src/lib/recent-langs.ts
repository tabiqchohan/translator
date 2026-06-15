const STORAGE_KEY = 'recent-langs';
const MAX_ITEMS = 5;

export interface RecentPair {
  source: string;
  target: string;
}

export function getRecentPairs(): RecentPair[] {
  if (typeof window === 'undefined') return [];
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

export function addRecentPair(source: string, target: string) {
  if (typeof window === 'undefined') return;
  const pairs = getRecentPairs().filter(
    (p) => !(p.source === source && p.target === target)
  );
  pairs.unshift({ source, target });
  localStorage.setItem(STORAGE_KEY, JSON.stringify(pairs.slice(0, MAX_ITEMS)));
}
