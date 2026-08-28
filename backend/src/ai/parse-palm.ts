import { ErrorCode, fail } from '../errors.js';

export type PalmData = {
  overall: string;
  lifeLine: string;
  headLine: string;
  heartLine: string;
  fateLine: string;
  takeaway: string;
  symbols: string[];
  themes: string[];
};

const FORBIDDEN = [
  'ömrün',
  'omrun',
  'hastalığ',
  'hastalik',
  'kesin olacak',
  'kesin hayatına',
  'şu kadar yaşa',
];

export function parsePalmData(raw: string): PalmData {
  const json = extractJson(raw);
  if (!json) fail(ErrorCode.invalidResponse);
  const overall = pick(json, ['genelYapi', 'genelYapı', 'overall', 'genel'], 8);
  const takeaway = pick(json, ['sonuc', 'sonuç', 'takeaway'], 1);
  if (!overall && !takeaway) fail(ErrorCode.invalidResponse);
  const data: PalmData = {
    overall,
    lifeLine: pick(json, ['yasamCizgisi', 'yaşamÇizgisi', 'lifeLine'], 1),
    headLine: pick(json, ['zihinCizgisi', 'zihinÇizgisi', 'headLine'], 1),
    heartLine: pick(json, ['kalpCizgisi', 'kalpÇizgisi', 'heartLine'], 1),
    fateLine: pick(json, ['kaderYon', 'kaderYön', 'fateLine', 'yon'], 1),
    takeaway,
    symbols: stringList(json.semboller ?? json.symbols),
    themes: stringList(json.temalar ?? json.themes),
  };
  const blob = Object.values(data).flat().join(' ').toLowerCase();
  if (FORBIDDEN.some((w) => blob.includes(w))) fail(ErrorCode.invalidResponse);
  return data;
}

function extractJson(raw: string): Record<string, unknown> | null {
  const trimmed = raw.trim();
  try {
    const decoded = JSON.parse(trimmed) as unknown;
    if (decoded && typeof decoded === 'object' && !Array.isArray(decoded)) {
      return decoded as Record<string, unknown>;
    }
  } catch {
    /* slice */
  }
  const start = trimmed.indexOf('{');
  const end = trimmed.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    const decoded = JSON.parse(trimmed.slice(start, end + 1)) as unknown;
    if (decoded && typeof decoded === 'object' && !Array.isArray(decoded)) {
      return decoded as Record<string, unknown>;
    }
  } catch {
    return null;
  }
  return null;
}

function pick(
  json: Record<string, unknown>,
  keys: string[],
  min: number,
): string {
  for (const key of keys) {
    const value = json[key];
    if (typeof value === 'string' && value.trim().length >= min) {
      return value.trim();
    }
  }
  return '';
}

function stringList(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((item): item is string => typeof item === 'string' && item.trim().length > 0)
    .map((item) => item.trim())
    .slice(0, 8);
}
