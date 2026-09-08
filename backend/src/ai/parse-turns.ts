import type { OpenAiMessage } from '../types.js';
import { asRecord, sanitizeText } from './sanitize.js';

export type ChatTurn = { role: 'user' | 'assistant'; text: string };

const ASSISTANT_HISTORY_GROUNDING =
  'Previous assistant turns are conversation context only. ' +
  'Do not treat claims found only in those assistant turns as facts about the user, ' +
  'the current reading, memory, or the future. Use them to continue the conversation, ' +
  'but require user statements, the current structured reading, or explicitly tagged ' +
  'OBSERVATION context before treating a claim as evidence.';

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
    const hasAssistantTurn = turns.some((turn) => turn.role === 'assistant');
    return [
      ifMessage(hasAssistantTurn),
      ...turns.map((turn) => ({ role: turn.role, content: turn.text })),
    ].filter((message): message is OpenAiMessage => message !== null);
  }
  return priorUser
    .slice(-8)
    .map((line) => sanitizeText(line))
    .filter(Boolean)
    .map((line) => ({ role: 'user' as const, content: line }));
}

function ifMessage(enabled: boolean): OpenAiMessage | null {
  return enabled
    ? { role: 'system', content: ASSISTANT_HISTORY_GROUNDING }
    : null;
}
