/** Normalize OpenAI chat message content (string or content parts). */
export function extractMessageContent(content: unknown): string {
  if (typeof content === 'string') return content.trim();
  if (!Array.isArray(content)) return '';
  const parts: string[] = [];
  for (const part of content) {
    if (typeof part === 'string' && part.trim()) {
      parts.push(part.trim());
      continue;
    }
    if (!part || typeof part !== 'object' || Array.isArray(part)) continue;
    const rec = part as Record<string, unknown>;
    if (typeof rec.text === 'string' && rec.text.trim()) {
      parts.push(rec.text.trim());
    }
  }
  return parts.join('\n').trim();
}
