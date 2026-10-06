/**
 * Story-first final closure — real full12_run9 (gpt-5.6-sol, low):
 *   1. geometry_inference false positive on ROAD ("yönünü belirleyecek
 *      gelişme"): direction / control is flagged only when one side acts on
 *      ANOTHER ("ötekinin yönünü", "biri diğerini yönlendiriyor");
 *   2. no repair word target (70–120) for any Coffee repair;
 *   3. normal floors 50/30 -> 42/22 (133 saved non-sparse stages; takeaway 10);
 *   4. presumed_user_state covers current beliefs / organisation
 *      ("ayrı ayrı sanabilirsin", "ayrı tuttuğun").
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { coffeeGeometryInference, coffeePresumedUserState } from '../src/ai/human-quality.js';
import { coffeeRepairGuidance } from '../src/ai/reading/coffee-repair-guidance.js';
import { coffeeNarrativelySparse } from '../src/ai/reading/coffee-diversity.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import {
  coffeeVoiceRepairFocus,
  palmWriterSystem,
  repairWriterSystem,
} from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

type Stage = { kind: string; quality: string | null; narrative: CoffeeNarrative };
type Case = { label: string; evidence: ReadingEvidenceItem[]; stages: Stage[] };
const run9 = JSON.parse(
  readFileSync('./tests/fixtures/batch3a/coffee_qa_full12_run9.json', 'utf8'),
) as { cases: Record<string, Case> };
const BIRD = run9.cases.case2;
const ROAD = run9.cases.case4;
const TREE = run9.cases.case7;
const LOW = run9.cases.case10;
const last = (c: Case) => c.stages[c.stages.length - 1].narrative;

const checks = { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, milkFoamObstruction: false, usefulRegionsVisible: true };
const observation = (evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const meaning = (n: CoffeeNarrative) => [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway].map((s) => s.text);
const empty = { text: '', evidenceIds: [] as string[] };

describe('1/2. geometry_inference: only one side acting on another', () => {
  it('1. ROAD "yönünü belirleyecek gelişme" passes (the full12_run9 writer)', () => {
    const writer = ROAD.stages[0].narrative;
    expect(ROAD.stages[0].quality).toBe('geometry_inference');
    expect(writer.overall.text).toContain('yönünü belirleyecek gelişme');
    expect(coffeeGeometryInference(meaning(writer))).toBeNull();
    expect(coffeeQualityFailure(writer, 'tr', undefined, ROAD.evidence)).toBe('evidence_leak');
    // The long-standing evidence-concentration rule (all three sections on the
    // road, the clean rim band unused) still applies — a separate, repairable
    // check, not the geometry false positive.
    expect(bindCoffeeNarrative(writer, observation(ROAD.evidence), 'tr')).toBe('evidence_leak');
    const publicWriter = structuredClone(writer);
    publicWriter.visualObservation = { text: 'Önündeki süreç kesilmeden ilerliyor ve yakın zamanda görünür hâle geliyor.', evidenceIds: ['e1'] };
    publicWriter.overall = { text: 'Hayatındaki gelişmeler birkaç aşamadan geçerek kendi yönünü bulacak. Önündeki süreç kesilmeden ilerliyor ve gerçek bir devam alanı kazanıyor. Aradaki değişimler sonucu bozmayacak; ilerleyişin farklı biçimde şekillenmesine ve yeni bir açılım kazanmasına yardım edecek. Her aşama bir sonrakini daha anlaşılır hâle getirecek.', evidenceIds: ['e1'] };
    publicWriter.nearFuture = { text: 'Yönünü belirleyecek gelişme uzak görünmüyor; kısa zamanda günlük hayatında belirginleşecek.', evidenceIds: ['e1'] };
    publicWriter.takeaway = { text: 'Sonuca doğrudan değil, birkaç değişimden geçerek ama bağlantıyı kaybetmeden ulaşacaksın.', evidenceIds: ['e1'] };
    expect(bindCoffeeNarrative(publicWriter, observation(ROAD.evidence), 'tr')).toBe('insight_collapse');
    // The delivered-shape repair (takeaway on the rim band) binds cleanly.
    const repaired = structuredClone(publicWriter);
    repaired.takeaway = { text: 'Bu ilerleyişin sonunda önünde açık ve kullanışlı bir fırsat alanı belirginleşecek.', evidenceIds: ['e3'] };
    expect(bindCoffeeNarrative(repaired, observation(ROAD.evidence), 'tr')).toBeNull();
  });

  it('2. LOW-SYMBOL one-side-controls-the-other still fails', () => {
    expect(coffeeGeometryInference(['İki taraf arasında ince bir bağlantı kuruluyor. Birindeki hareket, ötekinin yönünü de belirleyecek.'])).not.toBeNull();
    expect(coffeeGeometryInference(['Aradaki çizgiyle biri diğerini kendi tarafına yönlendirecek.'])).not.toBeNull();
  });
});

describe('3/4. normal floors 42 / 22', () => {
  it('3. the full12_run9 BIRD first pass (overall 23, lead 43) passes', () => {
    const writer = BIRD.stages[0].narrative;
    expect(BIRD.stages[0].quality).toBe('too_short');
    expect(writer.overall.text.split(/\s+/).length).toBe(23);
    expect(coffeeQualityFailure(writer, 'tr', undefined, BIRD.evidence)).toBe('evidence_leak');
    expect(bindCoffeeNarrative(writer, observation(BIRD.evidence), 'tr')).toBe('evidence_leak');
  });

  it('4. a trivial short non-sparse reading still fails', () => {
    const n: CoffeeNarrative = {
      visualObservation: { text: 'Ağza yakın küçük bir kuş var.', evidenceIds: ['e1'] },
      overall: { text: 'Kuş sana güzel bir haber getiriyor, her şey yoluna girecek.', evidenceIds: ['e1'] },
      love: empty,
      career: empty,
      money: empty,
      nearFuture: empty,
      takeaway: { text: 'Haber yakında gelecek ve seni çok sevindirecek, merak etme.', evidenceIds: ['e1'] },
    };
    expect(coffeeQualityFailure(n, 'tr', undefined, BIRD.evidence)).toBe('too_short');
  });
});

describe('5. no repair word target', () => {
  it('neither the too_short focus nor any Coffee repair guidance carries 70–120', () => {
    expect(coffeeVoiceRepairFocus('too_short')).not.toContain('70–120');
    expect(repairWriterSystem('coffee')).not.toContain('70–120');
    for (const c of [BIRD, ROAD, TREE, LOW]) {
      const g = coffeeRepairGuidance('section_redundancy', c.stages[0].narrative, c.evidence, 'tr') ?? '';
      expect(g).not.toContain('70–120');
    }
  });
});

describe('6–9. presumed beliefs / organisation', () => {
  it('6. TREE "ayrı ayrı sanabilirsin" is presumed_user_state', () => {
    expect(last(TREE).overall.text).toContain('ayrı ayrı sanabilirsin');
    expect(coffeePresumedUserState(meaning(last(TREE)))).toContain('sanabilirsin');
    expect(coffeeQualityFailure(last(TREE), 'tr', undefined, TREE.evidence)).toBe('presumed_user_state');
  });

  it('7. LOW-SYMBOL "ayrı tuttuğun" is presumed_user_state', () => {
    expect(last(LOW).overall.text).toContain('Hayatında ayrı tuttuğun iki taraf');
    expect(coffeeQualityFailure(last(LOW), 'tr', undefined, LOW.evidence)).toBe('presumed_user_state');
  });

  it('8. the same TREE told without the presumption passes', () => {
    const n = structuredClone(last(TREE));
    n.overall.text = n.overall.text.replace(
      'Dolayısıyla önüne gelen gelişmeleri ayrı ayrı sanabilirsin ama hepsinin merkezinde aynı bağ bulunacak.',
      'Önüne gelen gelişmeler ayrı görünse de hepsinin merkezinde aynı bağ bulunacak.',
    );
    expect(coffeeQualityFailure(n, 'tr', undefined, TREE.evidence)).toBe('evidence_leak');
    expect(bindCoffeeNarrative(n, observation(TREE.evidence), 'tr')).toBe('evidence_leak');
  });

  it('9. the same LOW-SYMBOL told without the presumption passes', () => {
    const n = structuredClone(last(LOW));
    n.overall.text = n.overall.text.replace('Hayatında ayrı tuttuğun iki taraf', 'Ayrı duran iki taraf');
    expect(coffeeQualityFailure(n, 'tr', undefined, LOW.evidence)).toBe('evidence_leak');
    expect(bindCoffeeNarrative(n, observation(LOW.evidence), 'tr')).toBe('evidence_leak');
  });

  it('ordinary future predictions and direct address are not presumptions', () => {
    for (const s of ['Sana ulaşacak bir haber var.', 'Yakında bu bağın adını koyacaksın.', 'Bak, bu yol kıvrılarak yükseliyor.']) {
      expect(coffeePresumedUserState([s])).toBeNull();
    }
  });
});

describe('10. sparse classification unchanged; 11. Palm untouched', () => {
  it('only SPARSE / HANDLE / DOTS are narratively sparse in the fixed corpus', () => {
    const sparse = Object.entries(run9.cases).filter(([, c]) => coffeeNarrativelySparse(c.evidence)).map(([k]) => k);
    expect(sparse.sort()).toEqual(['case1', 'case5', 'case9']);
  });

  it('Palm prompts carry no Coffee closure rule', () => {
    for (const text of [palmWriterSystem('tr'), repairWriterSystem('palm')]) {
      expect(text).not.toContain('PRESUME THE PERSON');
      expect(text).not.toContain('NARRATIVELY SPARSE');
    }
  });
});
