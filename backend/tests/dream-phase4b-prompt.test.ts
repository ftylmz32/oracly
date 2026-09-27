import { describe, expect, it } from 'vitest';
import type { AppLanguage } from '../src/ai/app-language.js';
import { DREAM_FIELD_ROLES } from '../src/ai/dream-prompt-roles.js';
import { dreamMessages } from '../src/ai/dream-prompts.js';

const LANGS: AppLanguage[] = ['tr', 'en', 'ru'];

describe('Dream Phase 4B — prompt field roles', () => {
  it.each(LANGS)('%s: roles follow safety + history and precede the language directive', (language) => {
    const system = String(dreamMessages({ narrative: 'a red door' }, language)[0]!.content);
    const at = system.indexOf(DREAM_FIELD_ROLES[language]);
    expect(at).toBeGreaterThan(0);
    for (const field of ['summary', 'emotionalTheme', 'interpretation', 'dailyLifeReflection', 'conclusion']) {
      expect(DREAM_FIELD_ROLES[language]).toContain(field);
    }
    expect(system.slice(at + DREAM_FIELD_ROLES[language].length).trim().length).toBeGreaterThan(0);
  });

  it('en: states the relational bridge, one open question and no invented life domain', () => {
    const roles = DREAM_FIELD_ROLES.en;
    expect(roles).toContain('relational bridge');
    expect(roles).toContain('never a yes/no question');
    expect(roles).toContain('your work');
    expect(roles).toContain('not afraid');
  });

  it('keeps the JSON schema and the Phase 4A history rule in the system prompt', () => {
    const system = String(dreamMessages({ narrative: 'a red door' }, 'en')[0]!.content);
    expect(system).toContain('dailyLifeReflection');
    expect(system).toContain('Prior dream patterns');
  });
});
