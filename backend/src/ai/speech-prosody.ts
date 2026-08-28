import { spokenHeading } from './speech-headings.js';
import { prepareSpokenNumbers } from './speech-numbers.js';

const ELLIPSIS = '\uE000';
const MAX_SPOKEN = 460;

const ASK =
  /(?:değil\s+mi|acaba|(?:^|\s)m[ıiuü]|mısın|misin|musun|müsün|mısınız|misiniz|musunuz|müsünüz|mıyım|miyim|muyum|müyüm|mıyız|miyiz|muyuz|müyüz|mıydı|miydi|muydu|müydü|mıdır|midir|mudur|müdür|nedir|nasılsınız|nasılsın|ne yapardın|ne dersin)\s*\.?$/i;

const OPENS = /^(?:nasıl|neden(?!\s+sonra)|niçin|acaba)\b/i;

export function applyProsody(cleaned: string): string {
  let text = cleaned.replace(/\.{4,}/g, '...');
  text = text.replace(/(\.\.\.){2,}/g, '...');
  text = joinBrokenLines(text);
  text = restoreQuestions(text);
  text = groupThoughts(text);
  text = shorten(text);
  return text.replace(/[ \t]+/g, ' ').trim();
}

export function markEmphasis(raw: string): string {
  return raw.replace(/\*\*([^*]+)\*\*/g, (_, word: string) => {
    const value = String(word).trim();
    if (!value || value.split(/\s+/).length > 4) return value;
    return `, ${value},`;
  });
}

export function spokenHeadings(raw: string): string {
  return raw.replace(/^#{1,6}\s*(.+)$/gm, (_, line: string) =>
    spokenHeading(String(line)),
  );
}

export { prepareSpokenNumbers };

function joinBrokenLines(text: string): string {
  return text
    .split(/\n{2,}/)
    .map((block) =>
      block
        .split('\n')
        .map((line) => line.trim())
        .filter(Boolean)
        .join(' '),
    )
    .filter(Boolean)
    .join(' ... ');
}

function restoreQuestions(text: string): string {
  return text
    .split(/(?<=[.!?])\s+/)
    .map((part) => {
      const value = part.trim();
      if (value.includes('?') || (!ASK.test(value) && !OPENS.test(value))) {
        return value;
      }
      return value.replace(/\.\s*$/, '') + '?';
    })
    .join(' ');
}

function groupThoughts(text: string): string {
  const guarded = text.replaceAll('...', ELLIPSIS);
  const chunks = guarded
    .split(/(?<=[.!?])\s+/)
    .map((s) => s.trim())
    .filter(Boolean);
  if (chunks.length < 2) return text;
  const out: string[] = [];
  for (let i = 0; i < chunks.length; i++) {
    let current = chunks[i] ?? '';
    let joined = 1;
    while (
      i + 1 < chunks.length &&
      joined < 3 &&
      shortClause(current) &&
      shortClause(chunks[i + 1] ?? '') &&
      !isQuestion(current) &&
      !isQuestion(chunks[i + 1] ?? '') &&
      !current.includes(ELLIPSIS)
    ) {
      current = attach(current, chunks[++i] ?? '');
      joined++;
    }
    out.push(current);
  }
  return out.join(' ').replaceAll(ELLIPSIS, '...');
}

function isQuestion(value: string): boolean {
  return value.includes('?') || value.includes(ELLIPSIS);
}

function shortClause(value: string): boolean {
  const words = value.replaceAll(ELLIPSIS, ' ').trim().split(/\s+/);
  return words.length <= 8;
}

function attach(left: string, right: string): string {
  const lead = left.replace(/\.\s*$/, '');
  const next = right.charAt(0).toLowerCase() + right.slice(1);
  return `${lead}, ${next}`;
}

function shorten(text: string): string {
  if (text.length <= MAX_SPOKEN) return text;
  const parts = text.split(/(?<=[.!?])\s+/);
  let spoken = '';
  for (const part of parts) {
    const next = spoken ? `${spoken} ${part}` : part;
    if (next.length > MAX_SPOKEN && spoken) break;
    spoken = next;
    if (spoken.length >= MAX_SPOKEN) break;
  }
  return spoken.trim() || text.slice(0, MAX_SPOKEN).trim();
}
