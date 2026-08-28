import {
  applyProsody,
  markEmphasis,
  spokenHeadings,
  prepareSpokenNumbers,
} from './speech-prosody.js';

const EMOJI =
  /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]/gu;

/** Spoken form of a visible OR reply. Never reads markdown or URLs. */
export function prepareSpeech(raw: string): string {
  let text = markEmphasis(raw);
  text = spokenHeadings(text);
  text = clean(text);
  text = prepareSpokenNumbers(text);
  return applyProsody(text);
}

function clean(raw: string): string {
  let text = raw.trim();
  if (!text) return '';
  text = text.replace(/^#{1,6}\s*/gm, '');
  text = text.replace(/^\s*[-*•]\s+/gm, '');
  text = text.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '$1');
  text = text.replace(/https?:\/\/\S+/gi, '');
  text = text.replace(/`{1,3}/g, '');
  text = text.replace(/[*_~]{1,3}/g, '');
  text = text.replace(EMOJI, '');
  text = text.replace(/\u2026/g, '...');
  text = text.replace(/\.{4,}/g, '...');
  text = text.replace(/!{2,}/g, '!');
  text = text.replace(/\?{2,}/g, '?');
  text = text.replace(/[ \t]+/g, ' ');
  text = text.replace(/\n{3,}/g, '\n\n');
  return text.trim();
}
