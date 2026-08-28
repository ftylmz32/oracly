import type { OpenAiMessage } from '../types.js';
import { asRecord, sanitizeText } from './sanitize.js';

export type ChatTurn = { role: 'user' | 'assistant'; text: string };

export function parseTurns(input: unknown, maxItems = 8): ChatTurn[] {
  if (!Array.isArray(input)) return [];
  const out: ChatTurn[] = [];
  for (const item of input) {
    const record = asRecord(item);
    if (!record) continue;
    const role = record.role === 'assistant' ? 'assistant' : record.role;
    if (role !== 'user' && role !== 'assistant') continue;
    const text = sanitizeText(record.text ?? record.content, 800);
    if (!text) continue;
    out.push({ role, text });
  }
  return out.length <= maxItems ? out : out.slice(-maxItems);
}

export function historyMessages(
  turns: ChatTurn[],
  priorUser: string[],
): OpenAiMessage[] {
  if (turns.length) {
    return turns.map((turn) => ({ role: turn.role, content: turn.text }));
  }
  return priorUser
    .slice(-8)
    .map((line) => sanitizeText(line))
    .filter(Boolean)
    .map((line) => ({ role: 'user' as const, content: line }));
}
