/** Phase 5 — Yıldızname natal narrative provider prompts (evidence-bound). */
import type { OpenAiMessage } from '../types.js';
import { responseLanguageDirective, type AppLanguage } from './app-language.js';
import type { YildiznameWireNarrative } from './narrative-yildizname-contract.js';
import {
  yildiznameEvidenceLegend,
  yildiznameResultContractDirective,
  yildiznameSystemRules,
} from './narrative-yildizname-prompt-rules.js';

export function yildiznameNarrativeMessages(
  narrative: YildiznameWireNarrative,
  language: AppLanguage,
): OpenAiMessage[] {
  return [
    { role: 'system', content: systemPrompt(language) },
    { role: 'user', content: userPrompt(narrative) },
  ];
}

function systemPrompt(language: AppLanguage): string {
  return [
    ...yildiznameSystemRules(),
    responseLanguageDirective(language),
  ].join('\n');
}

function userPrompt(narrative: YildiznameWireNarrative): string {
  return [
    'Yıldızname natal evidence (authoritative):',
    JSON.stringify(narrative),
    '',
    yildiznameEvidenceLegend(narrative),
    '',
    yildiznameResultContractDirective(),
  ].join('\n');
}
