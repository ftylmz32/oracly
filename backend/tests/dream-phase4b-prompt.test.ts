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

  it('en: states the relational bridge, optional reflection and natural close', () => {
    const roles = DREAM_FIELD_ROLES.en;
    expect(roles).toContain('relational bridge');
    expect(roles).toContain('one natural, cohesive reading');
    expect(roles).toContain('open a symbolic possibility');
    expect(roles).toContain('do not explain the method or merely retell the scene');
    expect(roles).toContain('never mechanically map a symbol to one fixed meaning');
    expect(roles).toContain('otherwise return an empty string');
    expect(roles).toContain('either a final thought or one open question');
    expect(roles).toContain('your work');
    expect(roles).toContain('not afraid');
  });

  it('keeps the same natural interpretation contract in tr and ru', () => {
    expect(DREAM_FIELD_ROLES.tr).toContain('doğal ve bütünlüklü bir yorum');
    expect(DREAM_FIELD_ROLES.tr).toContain('hangi sembolik ihtimali açtığını hissettir');
    expect(DREAM_FIELD_ROLES.ru).toContain('естественного, цельного толкования');
    expect(DREAM_FIELD_ROLES.ru).toContain('открывает символическую возможность');
  });

  it('keeps the JSON schema and the Phase 4A history rule in the system prompt', () => {
    const system = String(dreamMessages({ narrative: 'a red door' }, 'en')[0]!.content);
    expect(system).toContain('dailyLifeReflection');
    expect(system).toContain('Prior dream patterns');
  });
});
