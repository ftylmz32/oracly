/**
 * Story-first closure — coffeeInsightCollapse must not count the cup's ONE
 * evidence-grounded sign name (star -> "yıldız") as a repeated stem, while
 * every meaning stem still counts. Exemption is evidence-derived only.
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { coffeeInsightCollapse } from '../src/ai/human-quality.js';
import { coffeeSingleSemanticAnchorRoots } from '../src/ai/reading/coffee-diversity.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

type Packet = { evidence: ReadingEvidenceItem[]; narrative: CoffeeNarrative };
const qa = JSON.parse(
  readFileSync('./tests/fixtures/batch3a/coffee_story_first_qa.json', 'utf8'),
) as { cases: Record<string, Packet> };

const checks = { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, milkFoamObstruction: false, usefulRegionsVisible: true };
const observation = (evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const section = (text: string, ids = ['e1']) => ({ text, evidenceIds: text ? ids : [] });
const empty = section('');

const STAR = qa.cases.case11.evidence;
const RING = qa.cases.case3.evidence;
const TWO_SIGN = qa.cases.case6.evidence;

/** Real repairproof3 output (gpt-5.6-sol, low): shared stems = yildiz* (sign) + sevindi* (meaning). */
function starRepaired(): CoffeeNarrative {
  return {
    visualObservation: section('Fincanın üst tarafında küçük, beş uçlu bir yıldız şekli seçiliyor. Dipte telve koyu dururken orta kısımda hafif yollar var.', ['e1', 'e2', 'e3']),
    overall: section('Üstte beliren küçük yıldız, seni öne çıkaracak sevindirici bir kısmeti gösteriyor. Fincanın anlattığı ana gelişme, emeğinin fark edilmesi ve bunun sana belirgin bir takdir olarak dönmesi. Bu işaret büyük, karmaşık olaylardan çok, doğrudan sana yönelen tek bir fırsatı öne çıkarıyor. Yıldızın seçilir oluşu, bu fırsat geldiğinde değerinin anlaşılacağını da söylüyor. Buradaki sevinç yalnız şanstan değil; senin ortaya koyduğun şeyin görünür hâle gelmesinden doğacak.'),
    love: empty,
    career: empty,
    money: empty,
    nearFuture: section('Yıldızın fincanın üst kısmında görünmesi, bu sevindirici gelişmenin yakın zamanda kendini göstereceğini anlatıyor.'),
    takeaway: section('Beş uçlu yıldızın ince müjdesi şu: gelecek takdir yalnızca sevindirmekle kalmayacak, kendi ışığının başkaları tarafından da görüldüğünü sana gösterecek.'),
  };
}

describe('coffeeSingleSemanticAnchorRoots — evidence-derived only', () => {
  it('single real sign → its own name roots', () => {
    expect(coffeeSingleSemanticAnchorRoots(STAR)).toEqual(['yildiz']);
    expect(coffeeSingleSemanticAnchorRoots(RING)).toEqual(['yuzuk', 'yuzug', 'halka']);
    expect(coffeeSingleSemanticAnchorRoots(qa.cases.case2.evidence)).toEqual(['kus']);
  });

  it('multi-sign cup → no exemption', () => {
    expect(coffeeSingleSemanticAnchorRoots(TWO_SIGN)).toEqual([]);
    expect(coffeeSingleSemanticAnchorRoots(qa.cases.case4.evidence)).toEqual([]); // road + clean band
  });

  it('density/context-only evidence → no exemption', () => {
    const contextOnly: ReadingEvidenceItem[] = [
      { id: 'e1', region: 'base', description: 'A thick dark mass of grounds covering most of the base.', confidence: 'high', visibility: 'clear', resemblance: null },
      { id: 'e2', region: 'middle_wall', description: 'Light uneven smears across the middle wall.', confidence: 'medium', visibility: 'partial', resemblance: null },
      { id: 'e3', region: 'upper_wall', description: 'A few sparse dots on the upper inner surface.', confidence: 'low', visibility: 'partial', resemblance: null },
    ] as ReadingEvidenceItem[];
    expect(coffeeSingleSemanticAnchorRoots(contextOnly)).toEqual([]);
    expect(coffeeSingleSemanticAnchorRoots(qa.cases.case9.evidence)).toEqual([]);
    expect(coffeeSingleSemanticAnchorRoots(qa.cases.case10.evidence)).toEqual([]);
  });
});

describe('coffeeInsightCollapse — single-sign anchor is not repetition', () => {
  it('1. STAR: "yıldız" in all three + ONE meaning repeat → not section_redundancy', () => {
    const n = starRepaired();
    const roots = coffeeSingleSemanticAnchorRoots(STAR);
    expect(coffeeInsightCollapse(n.overall.text, n.nearFuture.text, n.takeaway.text)).toBe(true); // old behaviour
    expect(coffeeInsightCollapse(n.overall.text, n.nearFuture.text, n.takeaway.text, roots)).toBe(false);
    expect(coffeeQualityFailure(n, 'tr', undefined, STAR)).toBeNull();
    expect(bindCoffeeNarrative(n, observation(STAR), 'tr')).toBeNull();
  });

  it('2. STAR: "yıldız" + TWO genuine meaning repeats → still section_redundancy', () => {
    const n = starRepaired();
    n.overall.text = n.overall.text.replace('tek bir fırsatı', 'tek bir fırsatını');
    n.nearFuture.text = 'Yıldızın fincanın üst kısmında görünmesi, bu sevindirici fırsatının yakın zamanda kendini göstereceğini anlatıyor.';
    n.takeaway.text = 'Beş uçlu yıldızın ince müjdesi şu: fırsatının getirdiği takdir yalnızca sevindirmekle kalmayacak, kendi ışığını başkalarına da gösterecek.';
    expect(coffeeInsightCollapse(n.overall.text, n.nearFuture.text, n.takeaway.text, ['yildiz'])).toBe(true);
    expect(coffeeQualityFailure(n, 'tr', undefined, STAR)).toBe('section_redundancy');
  });

  it('3. single RING: its own name alone is not semantic collapse', () => {
    const overall = 'Orta kısımdaki küçük yüzüğün kapalı halkası, bir kavuşmanın habercisi; aradığın sözün sonunda verileceğini anlatıyor.';
    const near = 'Yüzüğün fincanın ortasında durması, bu kavuşmanın uzağa kalmayacağını gösteriyor.';
    const take = 'Yüzüğün ince yanı şu: bu kavuşma bir başlangıçtan çok, zaten bağlı olanın adını koymak.';
    expect(coffeeInsightCollapse(overall, near, take)).toBe(true); // yuzugu + kavusm without exemption
    expect(coffeeInsightCollapse(overall, near, take, coffeeSingleSemanticAnchorRoots(RING))).toBe(false);
  });

  it('4. multi-sign cup: sign name + one meaning stem still collapses (no exemption)', () => {
    const overall = 'Ağza yakın balığın görünmesi kısmetin yaklaştığını anlatıyor; ayrılan yollar da bir seçimi.';
    const near = 'Balığın kenara yakınlığı bu kısmetin yakında geleceğini söylüyor.';
    const take = 'Balığın asıl müjdesi, kısmetin seçimle birlikte gelmesi.';
    expect(coffeeInsightCollapse(overall, near, take, coffeeSingleSemanticAnchorRoots(TWO_SIGN))).toBe(true);
  });

  it('5. density-only evidence: a repeated base word is never exempted', () => {
    const overall = 'Dipteki yoğunluğun koyu kütlesi sevindirici bir haberi anlatıyor.';
    const near = 'Yoğunluğun dipte toplanması bu sevindirici haberin yakın olduğunu söylüyor.';
    const take = 'Yoğunluğun ince yanı, sevindirici olanın sessizce gelmesi.';
    expect(coffeeInsightCollapse(overall, near, take, coffeeSingleSemanticAnchorRoots(qa.cases.case9.evidence))).toBe(true);
  });

  it('6. prose cannot invent a sign name to exempt itself', () => {
    // STAR evidence; the prose repeats "kuşların" (a bird the cup never showed) + a meaning stem.
    const overall = 'Kuşların getirdiği sevindirici bir haber üstte beliren yıldızla birlikte geliyor.';
    const near = 'Kuşların yakında getireceği sevindirici haber uzak değil.';
    const take = 'Kuşların asıl müjdesi, sevindirici haberin seni öne çıkarması.';
    expect(coffeeInsightCollapse(overall, near, take, coffeeSingleSemanticAnchorRoots(STAR))).toBe(true);
  });
});
