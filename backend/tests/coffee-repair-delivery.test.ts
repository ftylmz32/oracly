/**
 * Story-first closure — Coffee repair delivery. The real repairproof5 output
 * fixed the menu and the redundancy but told 6 of 7 sentences through
 * "gösteriyor / işaret ediyor / görünüyor / söylüyor / anlatıyor"; the
 * formulaic_voice gate is right to reject it. The cure is in repair
 * guidance (natural falcı delivery), not in a weaker gate.
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { coffeeRegisterProfile, coffeeInsightCollapse } from '../src/ai/human-quality.js';
import { coffeeRepairGuidance } from '../src/ai/reading/coffee-repair-guidance.js';
import { coffeeEvidenceConcentration, coffeeSingleSemanticAnchorRoots } from '../src/ai/reading/coffee-diversity.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { coffeeVoiceRepairFocus, repairWriterSystem } from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

type Packet = { evidence: ReadingEvidenceItem[]; narrative: CoffeeNarrative };
const qa = JSON.parse(
  readFileSync('./tests/fixtures/batch3a/coffee_story_first_qa.json', 'utf8'),
) as { cases: Record<string, Packet>; starRun3FirstPass: Packet };

const checks = { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, milkFoamObstruction: false, usefulRegionsVisible: true };
const observation = (evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const section = (text: string, ids = ['e1']) => ({ text, evidenceIds: text ? ids : [] });
const empty = section('');
const STAR = qa.cases.case11.evidence;
const VISUAL = 'Fincanın üst tarafında küçük, beş uçlu bir yıldız şekli seçiliyor. Dipte telve koyu dururken orta kısımda hafif yollar var.';

/** Real repairproof5 output (gpt-5.6-sol, low) — rejected formulaic_voice. */
function starReportPredicates(): CoffeeNarrative {
  return {
    visualObservation: section(VISUAL, ['e1', 'e2', 'e3']),
    overall: section('Üst iç yüzeyde açıkça beliren küçük yıldız, fincanında tek ve seçkin bir kısmeti gösteriyor. Bu işaret, seni öne çıkaracak küçük ama sevindirici bir gelişmeye; özellikle emeğinin fark edilmesine işaret ediyor. Büyük ve gösterişli bir değişimden çok, doğru yerde parlayacak belirli bir fırsat görünüyor. Yıldızın tek başına belirgin oluşu, bu fırsatın kalabalık gelişmeler arasında kaybolmayacağını, doğrudan senin payına düşen bir değer taşıdığını söylüyor. Fincanın anlattığı ana hikâye, görünür olmak ve bununla birlikte gelen temiz bir sevinç.'),
    love: empty,
    career: empty,
    money: empty,
    nearFuture: section('Yıldızın fincanın ağzına yakın oluşu, bu gelişmenin uzak zamana kalmayacağını anlatıyor.'),
    takeaway: section('Bu küçük yıldız, gelecek kısmetin değerini büyüklüğünden değil, tam sana denk düşmesinden alacağını söylüyor.'),
  };
}

/** Same grounded meaning, told directly with varied sentence shapes. */
function starDirect(): CoffeeNarrative {
  return {
    visualObservation: section(VISUAL, ['e1', 'e2', 'e3']),
    overall: section('Üstte küçük, beş uçlu bir yıldız parlıyor; bu senin öne çıktığın, sevindirici bir kısmet. Emeğin fark edilecek ve bunun karşılığını açık bir takdir olarak alacaksın. Gürültülü, büyük bir değişim beklemiyorum; tek ve seçkin bir fırsat geliyor. Bu fırsat kalabalığın içinde kaybolmuyor, doğrudan senin payına düşüyor. Yıldız fincanda tek başına durduğu için sevincin de dağılmadan, bütün hâliyle sana ulaşacak.'),
    love: empty,
    career: empty,
    money: empty,
    nearFuture: section('Üstelik çok uzakta da durmuyor; yıldız ağza yakın, bu güzel haber yakın zamanda kendini belli edecek.'),
    takeaway: section('Bu kısmetin asıl güzelliği büyüklüğünde değil, tam sana göre biçilmiş olmasında; o yüzden geldiğinde onu hemen tanıyacaksın.'),
  };
}

const REPORT_PREDICATES = ['gösteriyor', 'söylüyor', 'anlatıyor', 'işaret ediyor', 'görünüyor'];

describe('formulaic_voice gate is unchanged and correct', () => {
  it('1. a STAR repair dominated by report predicates is still rejected as formulaic_voice', () => {
    const n = starReportPredicates();
    const sections = [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway].map((s) => s.text);
    const profile = coffeeRegisterProfile(sections);
    expect(profile.sentences).toBeGreaterThanOrEqual(6);
    expect(profile.hedgeSentences / profile.sentences).toBeGreaterThanOrEqual(0.75);
    expect(coffeeQualityFailure(n, 'tr', undefined, STAR)).toBe('formulaic_voice');
    expect(bindCoffeeNarrative(n, observation(STAR), 'tr')).toBe('human_quality');
  });

  it('2. the same grounded meaning told directly passes every Coffee gate', () => {
    const n = starDirect();
    const sections = [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway].map((s) => s.text);
    expect(coffeeRegisterProfile(sections).hedgeSentences).toBe(0);
    expect(coffeeQualityFailure(n, 'tr', undefined, STAR)).toBeNull();
    expect(coffeeInsightCollapse(n.overall.text, n.nearFuture.text, n.takeaway.text, coffeeSingleSemanticAnchorRoots(STAR))).toBe(false);
    expect(coffeeEvidenceConcentration({ overall: n.overall, nearFuture: n.nearFuture, takeaway: n.takeaway }, STAR)).toBe(false);
    expect(bindCoffeeNarrative(n, observation(STAR), 'tr')).toBeNull();
  });
});

describe('Coffee repair guidance asks for natural falcı delivery', () => {
  it('3. every Coffee repair limits report predicates and bans the "Bu işaret … işaret ediyor" tautology', () => {
    const system = repairWriterSystem('coffee');
    expect(system).toContain('NATURAL FALCI DELIVERY IN REPAIR');
    for (const verb of REPORT_PREDICATES) expect(system).toContain(verb);
    expect(system).toContain('at most a minority of the interpretation sentences');
    expect(system).toContain('Never a tautology like "Bu işaret … işaret ediyor"');
    expect(system).toContain('Fincanın anlattığı ana hikâye');
    expect(system).toContain('EXAMPLES ARE NOT WORDING');
    expect(system).not.toContain('Burada senin öne çıktığın sevindirici bir gelişme var');
    expect(coffeeVoiceRepairFocus('formulaic_voice')).toContain('No "Bu işaret … işaret ediyor" tautology');
  });

  it('Palm repair is untouched by the Coffee delivery rule', () => {
    expect(repairWriterSystem('palm')).not.toContain('NATURAL FALCI DELIVERY');
  });

  it('4. section_redundancy repair: preserve substance, change the form, no verbatim nearFuture', () => {
    const injected = structuredClone(qa.starRun3FirstPass.narrative);
    injected.takeaway = {
      text: 'Yıldızın açıkça belirmesi, seni öne çıkaracak küçük ama sevindirici bir gelişmeye yorulur; dikkat çekecek tek bir kısmet var.',
      evidenceIds: ['e1'],
    };
    expect(bindCoffeeNarrative(injected, observation(STAR), 'tr')).toBe('section_redundancy');
    const g = coffeeRepairGuidance('section_redundancy', injected, STAR, 'tr')!;
    expect(g).toContain('Keep the grounded substance of overall');
    expect(g).not.toContain('70–120'); // no repair word target, sparse or not
    expect(g).toContain('Do not fix the repetition by swapping synonyms or keeping the same sentence skeleton');
    expect(g).toContain('Do not copy the rejected nearFuture verbatim');
    expect(g).toContain('Additional detected Coffee defects: possibility_menu, repeated_sentence, dictionary_voice.');
    expect(repairWriterSystem('coffee')).toContain('PRESERVE SUBSTANCE');

    // A repair that follows it keeps the full substance and passes.
    const repaired = starDirect();
    expect(repaired.overall.text.split(/\s+/).length).toBeGreaterThanOrEqual(55);
    expect(repaired.nearFuture.text).not.toBe(injected.nearFuture.text);
    expect(bindCoffeeNarrative(repaired, observation(STAR), 'tr')).toBeNull();
  });
});
