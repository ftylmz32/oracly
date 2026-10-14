import type { AppLanguage } from './app-language.js';
import { responseLanguageDirective } from './app-language.js';
import type { OpenAiMessage } from '../types.js';
import { sanitizeText } from './sanitize.js';
import {
  describeSoulmateIdentity,
  type SoulmateIdentity,
  type SoulmatePromptInput,
} from './soulmate-prompt.js';
import {
  assessSoulmateInterpretation,
  type SoulmateGateReason,
  type SoulmateSections,
} from './soulmate-interpretation-gate.js';

export type SoulmateInterpretationInput = SoulmatePromptInput & {
  language: AppLanguage;
  identity?: SoulmateIdentity;
  memorySummary?: string;
};

const KEYS = [
  'personality',
  'dynamic',
  'attraction',
  'challenge',
  'meeting',
  'feeling',
] as const;

export function soulmateInterpretationMessages(
  input: SoulmateInterpretationInput,
  repair?: SoulmateGateReason,
): OpenAiMessage[] {
  const identity =
    input.identity ??
    describeSoulmateIdentity(input, 'pending');
  const facts = [
    `givenName=${sanitizeText(input.name, 80)}`,
    `birthDate=${input.birthDate}`,
    input.gender ? `desiredPresentation=${input.gender}` : '',
    input.intention ? `statedPreference=${sanitizeText(input.intention, 200)}` : '',
    `portraitPresence=${identity.presence}`,
    `relationalTone=${identity.relationshipArchetype || identity.mood}`,
  ]
    .filter(Boolean)
    .join('\n');
  const repairLine = repair === 'adjective_list'
    ? 'Previous draft flattened several sections into comma-heavy trait lists. Rewrite once: give each section a distinct relational insight in flowing sentences, and do not recycle the same calm/trust/balance description across sections.'
    : repair
      ? `Previous draft was rejected for ${repair}. Rewrite once. Do not repeat that defect.`
      : '';
  const memory = sanitizeText(input.memorySummary, 220);
  const memoryLine = memory
    ? `Relevant sourced history (use only when the current stated intention supports it; otherwise ignore):\n${memory}`
    : '';
  return [
    {
      role: 'system',
      content: [
        'You write a symbolic Soulmate reflection for ORACLY.',
        'This is not a real person, not a prediction, and not a guaranteed meeting.',
        responseLanguageDirective(input.language),
        'Use only the supplied facts. Do not invent a city, date, profession, name, or past relationship.',
        'Current portrait identity and stated intention are primary. Historical context is optional and uncertain.',
        'Shared identity is relational tone only. Do not describe face, hair, eyes, or skin, and do not treat visual traits as personality facts.',
        'Use natural uncertainty. Never claim certainty, an exact date, or a guaranteed meeting.',
        'Do not start sections with "bu kisi" or "this person". Do not repeat the given name in every section.',
        'Keep the six angles distinct: personality shows inner character; dynamic shows how two people relate; attraction shows what draws them together; challenge shows a specific friction; meeting shows the encounter energy without inventing a place or date; feeling closes with the atmosphere they create together. Do not recycle one trait across sections.',
        'Treat the supplied relational tone as an opening note for personality, not the subject of the remaining sections. Then let the reading move like a romantic story through interaction, a source of attraction, a real tension, an evocative symbolic encounter, and the atmosphere created together; develop each new moment instead of redescribing the character.',
        'Let each section use the natural length and rhythm its distinct insight needs. Keep it specific to this identity, not a generic romance slogan.',
        'Return JSON only with keys personality, dynamic, attraction, challenge, meeting, feeling.',
        repairLine,
      ]
        .filter(Boolean)
        .join(' '),
    },
    { role: 'user', content: [facts, memoryLine].filter(Boolean).join('\n\n') },
  ];
}

export function parseSoulmateSections(raw: string): SoulmateSections | null {
  const trimmed = raw.trim().replace(/^```json\s*|```$/g, '');
  let parsed: unknown;
  try {
    parsed = JSON.parse(trimmed);
  } catch {
    return null;
  }
  if (!parsed || typeof parsed !== 'object') return null;
  const record = parsed as Record<string, unknown>;
  const out = {} as SoulmateSections;
  for (const key of KEYS) {
    const value = record[key];
    if (typeof value !== 'string' || !value.trim()) return null;
    out[key] = value.trim();
  }
  return out;
}

export function acceptSoulmateSections(
  sections: SoulmateSections,
  input: SoulmateInterpretationInput,
): SoulmateGateReason | null {
  const identity = input.identity ?? describeSoulmateIdentity(input, 'pending');
  return assessSoulmateInterpretation(sections, {
    name: input.name,
    presence: identity.presence,
    mood: identity.mood,
  });
}
