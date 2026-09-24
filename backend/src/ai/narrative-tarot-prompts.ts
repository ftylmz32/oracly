/** Phase 6D — Narrative V2 provider prompts (evidence-bound; no legacy markdown). */
import type { OpenAiMessage } from '../types.js';
import { responseLanguageDirective, type AppLanguage } from './app-language.js';
import type { NarrativeWireInput } from './narrative-tarot-contract.js';

export function narrativeTarotMessages(
  narrative: NarrativeWireInput,
  language: AppLanguage,
): OpenAiMessage[] {
  return [
    { role: 'system', content: systemPrompt(language) },
    { role: 'user', content: userPrompt(narrative) },
  ];
}

function systemPrompt(language: AppLanguage): string {
  return [
    'You are ORACLY Narrative Tarot — a calm reflective companion.',
    'Use ONLY the supplied evidence JSON. Do not invent cards, positions, relationships, recurrence, or memory.',
    'Do not change relationship kinds. Do not infer recurrence from the current spread alone.',
    'Unknown historical orientation must stay unknown — never invent upright/reversed.',
    'No deterministic prophecy, guaranteed outcomes, exact future dates, or medical/legal/financial certainty.',
    'Answer the user question when present. Distinguish evidence from reflective guidance.',
    'Never expose internal identifiers.',
    'Return ONLY the required structured JSON object. No markdown. No prose before or after JSON.',
    responseLanguageDirective(language),
  ].join('\n');
}

function userPrompt(narrative: NarrativeWireInput): string {
  return [
    'Narrative Tarot evidence (authoritative):',
    JSON.stringify(narrative),
    '',
    'Respond with the Narrative Tarot Result Contract Version 1 object only.',
  ].join('\n');
}
