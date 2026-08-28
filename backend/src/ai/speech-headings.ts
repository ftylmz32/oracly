const SIDES = new Set([
  'aşk',
  'iş',
  'kariyer',
  'para',
  'sağlık',
  'genel',
  'uyarı',
  'özet',
  'ilişki',
  'enerji',
]);

export function spokenHeading(raw: string): string {
  const line = raw.trim();
  if (!line || line.length > 28) return line;
  const words = line.split(/\s+/);
  if (words.length > 3) return line;
  const lower = trLower(line);
  if (!looksLikeLabel(line, lower)) return line;
  const title = titleCase(lower);
  return SIDES.has(lower) ? `${title} tarafında,` : `${title}.`;
}

function looksLikeLabel(line: string, lower: string): boolean {
  if (SIDES.has(lower)) return true;
  const letters = line.replace(/[^A-Za-zÇĞİÖŞÜçğıöşü]/g, '');
  return letters.length >= 3 && letters === letters.toUpperCase();
}

function trLower(value: string): string {
  return value.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
}

function titleCase(lower: string): string {
  const map: Record<string, string> = {
    i: 'İ',
    ı: 'I',
    ş: 'Ş',
    ğ: 'Ğ',
    ü: 'Ü',
    ö: 'Ö',
    ç: 'Ç',
  };
  const first = lower.slice(0, 1);
  return `${map[first] ?? first.toUpperCase()}${lower.slice(1)}`;
}
