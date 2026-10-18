/**
 * Stage 1G real outputs, secrets removed. No provider calls.
 * Proves the saved JSON matches the product parsers, and that a
 * missing required field is still rejected.
 */
import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { chatSystem, lunaIdentityViolation } from '../src/ai/chat-style.js';
import { narrativeSystemRules } from '../src/ai/narrative-tarot-prompt-rules.js';
import { parseNarrativeTarotResult } from '../src/ai/narrative-tarot-result.js';
import {
  NARRATIVE_POLICY_RULES,
  NARRATIVE_POLICY_VERSION,
} from '../src/ai/narrative-tarot-limits.js';
import { parseYildiznameNarrativeResult } from '../src/ai/narrative-yildizname-result.js';
import {
  YILDIZNAME_POLICY_RULES,
  YILDIZNAME_POLICY_VERSION,
} from '../src/ai/narrative-yildizname-limits.js';
import { ProxyError } from '../src/errors.js';
import { authHeader, openaiText, testApp, testConfig } from './helpers.js';

const dir = new URL('./fixtures/stage1g/', import.meta.url);

function read(name: string): string {
  return readFileSync(new URL(name, dir), 'utf8');
}

const tarotNarrative = {
  narrativeTarotVersion: 2,
  serializerVersion: 1,
  languageCode: 'tr' as const,
  question: {
    text: 'İş yerinde ertelediğim bir karar var. Bu kart bu konuda ne söylüyor?',
    topic: 'work',
    kind: 'decision',
    hasRealQuestion: true,
  },
  spread: {
    spreadId: 'classical.single',
    cardCount: 1,
    positions: [{ index: 0, positionKey: 'sign', role: 'signal', temporal: 'atemporal' }],
    interpretationOrder: [0],
    geometryHook: 'singlePoint',
    lengthBand: 'short',
  },
  cards: [{
    canonicalCardId: 'major_02',
    displayName: 'Azize',
    isReversed: false,
    positionKey: 'sign',
    positionIndex: 0,
    keywordIds: ['patience'],
    symbolTags: ['veil'],
    coreMeaning: 'threshold',
    orientationExpression: 'upright',
    transforms: [],
  }],
  relationships: [],
  recurringCards: [],
  recurringThemes: [],
  memory: { included: false, priorReadingCount: 0, entries: [] },
  policy: { version: NARRATIVE_POLICY_VERSION, rules: [...NARRATIVE_POLICY_RULES] },
};

const yildizNarrative = {
  version: 1,
  serializerVersion: 1,
  languageCode: 'tr' as const,
  scope: 'full' as const,
  fidelity: 'fullNatalEphemeris' as const,
  houseSystem: 'wholeSign',
  placements: [
    { factRef: 'placement.sun', body: 'sun', sign: 'aries', degreeWithinSign: 12.5, retrograde: false, house: 10, certainty: 'exact' },
    { factRef: 'placement.moon', body: 'moon', sign: 'cancer', degreeWithinSign: 3.1, retrograde: false, house: 1, certainty: 'exact' },
  ],
  angles: [{ factRef: 'angle.ascendant', kind: 'ascendant', sign: 'cancer', degreeWithinSign: 5, house: 1, certainty: 'exact' }],
  houses: [
    { factRef: 'house.1', number: 1, sign: 'cancer' },
    { factRef: 'house.10', number: 10, sign: 'aries' },
  ],
  aspects: [{ factRef: 'aspect.sun.moon.trine', bodyA: 'sun', bodyB: 'moon', type: 'trine', orb: 2.4, certainty: 'exact' }],
  balances: [{ factRef: 'balance.elements', kind: 'elements', counts: { fire: 2, earth: 1, air: 1, water: 2 }, dominant: 'fire' }],
  discoveryThemes: [{ themeRef: 'theme.patience', label: 'patience' }],
  omittedLayers: [],
  policy: { version: YILDIZNAME_POLICY_VERSION, rules: [...YILDIZNAME_POLICY_RULES] },
};

describe('stage 1G live contracts', () => {
  it('keeps Luna from addressing the user as Luna', () => {
    const leaked = read('luna.txt');
    expect(lunaIdentityViolation(leaked)).toBe('misaddressed_as_luna');
    expect(lunaIdentityViolation("Ben Luna'yım. Kararı ertelemen, seçimin sonucuyla yüzleşmek istemenden.")).toBeNull();
    expect(lunaIdentityViolation('Ertelemen, seçimin ağırlığından geliyor.')).toBeNull();
    expect(lunaIdentityViolation('Bunu "Sen Luna" diye çevirmek yanlış. Kararı ertelemen seçimin ağırlığından.')).toBeNull();
    expect(lunaIdentityViolation("Sana 'Sen Luna' demem. Karar hâlâ senin.")).toBeNull();
    expect(chatSystem('tr')).toContain('Kimliğini sorduklarında');
    expect(chatSystem('tr')).not.toMatch(/her mesajda/i);
    expect(chatSystem('tr')).not.toMatch(/^Sen Luna/);
  });

  it('lets a user mention Luna without blocking a normal reply', async () => {
    const app = await testApp(
      testConfig(),
      openaiText('Ertelemen, seçimin ağırlığından geliyor.'),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: {
        operation: 'chat',
        model: 'gpt-4o',
        payload: { userMessage: 'Luna, "Sen Luna" diye bir cümle duydum. Bu kararı neden erteledim?' },
      },
    });
    const body = res.json() as { success: boolean; data?: { text?: string } };
    expect(body.success).toBe(true);
    expect(body.data?.text).toContain('Ertelemen');
    expect(JSON.stringify(body)).not.toMatch(/gem|premium|debit/i);
    await app.close();
  });

  it('does not return the leaked Luna sentence to the client', async () => {
    const app = await testApp(testConfig(), openaiText(read('luna.txt').trim()));
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: { operation: 'chat', model: 'gpt-4o', payload: { userMessage: 'Kimsin?' } },
    });
    expect(res.json()).toMatchObject({ success: false, error: { code: 'invalid_response' } });
    expect(JSON.stringify(res.json())).not.toContain('Sen Luna');
    await app.close();
  });

  it('parses the real tarot JSON and still rejects a missing closing', () => {
    const raw = read('tarot.json');
    const parsed = parseNarrativeTarotResult(raw, tarotNarrative);
    expect(parsed.cardReadings[0]?.cardId).toBe('major_02');
    expect(parsed.synthesis.length).toBeGreaterThan(80);
    expect(narrativeSystemRules().join('\n')).toMatch(/Never a homework list/);
    const broken = JSON.parse(raw) as Record<string, unknown>;
    delete broken.closingMessage;
    expect(() => parseNarrativeTarotResult(JSON.stringify(broken), tarotNarrative)).toThrow(ProxyError);
  });

  it('parses the fictional yıldızname chart and rejects an unknown fact', () => {
    const raw = read('yildizname.json');
    const parsed = parseYildiznameNarrativeResult(raw, yildizNarrative);
    const refs = [
      ...parsed.summary.factRefs,
      ...parsed.sections.flatMap((section) => section.factRefs),
    ];
    expect(refs).toEqual(expect.arrayContaining(['placement.sun', 'placement.moon', 'angle.ascendant']));
    expect(refs.join(' ')).not.toContain('venus');
    const broken = JSON.parse(raw) as { summary: { factRefs: string[] } };
    broken.summary.factRefs = ['placement.venus'];
    expect(() => parseYildiznameNarrativeResult(JSON.stringify(broken), yildizNarrative)).toThrow(ProxyError);
  });
});
