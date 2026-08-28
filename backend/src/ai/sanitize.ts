const MAX_TEXT = 8000;

export function sanitizeText(input: unknown, max = MAX_TEXT): string {
  if (typeof input !== 'string') return '';
  let text = input.trim();
  if (text.length > max) text = text.slice(0, max);
  return text.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F]/g, '');
}

export function stringList(input: unknown, maxItems = 24): string[] {
  if (!Array.isArray(input)) return [];
  const out: string[] = [];
  for (const item of input) {
    const value = sanitizeText(item, 200);
    if (value) out.push(value);
    if (out.length >= maxItems) break;
  }
  return out;
}

export function asRecord(input: unknown): Record<string, unknown> | null {
  if (input && typeof input === 'object' && !Array.isArray(input)) {
    return input as Record<string, unknown>;
  }
  return null;
}
