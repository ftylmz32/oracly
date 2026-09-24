/** Phase 6D/6E.3 — Narrative V2 provider prompts (evidence-bound). */
import type { OpenAiMessage } from '../types.js';
import { responseLanguageDirective, type AppLanguage } from './app-language.js';
import type { NarrativeWireInput } from './narrative-tarot-contract.js';
import {
  memoryIndexLegend,
  narrativeSystemRules,
  resultContractDirective,
} from './narrative-tarot-prompt-rules.js';

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
    ...narrativeSystemRules(),
    responseLanguageDirective(language),
  ].join('\n');
}

function userPrompt(narrative: NarrativeWireInput): string {
  return [
    'Narrative Tarot evidence (authoritative):',
    JSON.stringify(narrative),
    '',
    memoryIndexLegend(narrative),
    '',
    resultContractDirective(),
  ].join('\n');
}
