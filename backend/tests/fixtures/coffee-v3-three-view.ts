import type { CoffeeMultiViewObservationV3, CoffeeV3MapSlot } from '../../src/ai/reading/types.js';
import { c31Spec } from './coffee-c31-fixtures.js';
import type { M1FixtureSpec } from './coffee-m1-fixtures.js';

/**
 * Re-expresses a frozen M1 / C3.1 fixture observation as the live three-photo
 * capture (cup_view_a, cup_view_b, saucer) WITHOUT editing the frozen
 * fixtures: cup_handle_far → cup_view_a, cup_turn_a → cup_view_b. Clocks are
 * frame-local (handle-relative), so every mark keeps its exact geometry.
 * A fixture with evidence on a third cup view cannot be expressed in three
 * photos; it throws rather than silently dropping evidence.
 */
const LIVE: Partial<Record<CoffeeV3MapSlot, CoffeeV3MapSlot>> = {
  cup_handle_far: 'cup_view_a',
  cup_turn_a: 'cup_view_b',
  saucer: 'saucer',
};

export function toThreeViewObservation(obs: CoffeeMultiViewObservationV3): CoffeeMultiViewObservationV3 {
  if (obs.sightings.some((s) => s.slot === 'cup_turn_b')) throw new Error('fixture needs a third cup view');
  const slot = (s: CoffeeV3MapSlot): CoffeeV3MapSlot => {
    const live = LIVE[s];
    if (!live) throw new Error(`no live view for ${s}`);
    return live;
  };
  return {
    ...obs,
    views: obs.views.filter((v) => v.slot !== 'cup_turn_b').map((v) => ({ ...v, slot: slot(v.slot) })),
    sightings: obs.sightings.map((s) => ({ ...s, slot: slot(s.slot) })),
  };
}

/**
 * A plan that clears the premium substance floor: the frozen C3.1 RITAG cup
 * plus ONE clearly seen, strong object sign (a tree) on the first cup view.
 * Synthetic provider output — proves plumbing and gates, NOT reading quality.
 * Plan (frozen M2 → W2, decision intention): B1 GROWTH + CLOSE_CIRCLE,
 * B2 OPENING + FORWARD (relation), B3 MULTIPLICITY + scenario.
 */
export function coffeeV3PremiumSpec(): M1FixtureSpec {
  const ritag = c31Spec('C3F-RITAG', { clearAreas: true });
  return { ...ritag, marks: [...ritag.marks, { id: 'tree1', label: 'tree', hours: 1, band: 'rim_upper' }] };
}

/** A writer output that passes the frozen parser, scenario validator and checker for coffeeV3PremiumSpec. */
export const COFFEE_V3_PREMIUM_GOOD_BEATS = [
  { id: 'B1', scenarioItems: [] as string[], text: 'Yakın zamanda kendi çevrende yavaş yavaş büyüyen bir kısmet bereketleniyor.' },
  { id: 'B2', scenarioItems: [] as string[], text: 'Vermen gereken kararda yolun önümüzdeki dönemde adım adım ilerliyor; biraz daha ileride önün de açılıyor.' },
  {
    id: 'B3',
    scenarioItems: ['secondary_option_gaining_weight', 'options_separating'],
    text: 'Yaklaşan dönemde birden fazla yol beliriyor; seçeneklerden biri gözünde ağırlık kazanabilir, hangi yolun ne olduğu da daha açık seçilebilir.',
  },
];

/**
 * SIMULATED V3N1 narrative-writer outputs, authored offline (NOT provider
 * output). Life meaning only — no cup, shape or position narration. They pass
 * the deterministic V3N acceptance for their plans and prove plumbing / gates
 * ONLY, never real provider quality.
 */
export const COFFEE_V3N_PREMIUM_WRITER_OUTPUT = "{\"paragraphs\":[{\"claims\":[\"c1\",\"c2\"],\"text\":\"Vermen gereken kararın cevabı yakın zamanda, kendi dünyanda, sana yakın çevrende kök salmaya başlayan bir emekte saklı gibi. Acele etmeden ama kalıcı biçimde büyüyen bir gelişme seziliyor; emeklerinin zamanla meyve vereceği bir dönem bu. Yakın günlerde iş tarafında attığın adımların ivme kazandığını, çabalarının karşılık bulmaya başladığını fark edebilirsin.\"},{\"claims\":[\"c3\"],\"text\":\"Bu büyümenin içinde önüne gelen seçenekler arasındaki karar anı da kendiliğinden netleşiyor gibi.\"}]}";

/** Same, for the structure-only RITAG cup (the shape of the first real three-photo run). */
export const COFFEE_V3N_RITAG_WRITER_OUTPUT = "{\"paragraphs\":[{\"claims\":[\"c1\",\"c2\"],\"text\":\"Vermen gereken kararla ilgili yakın zamanda iş tarafında attığın adımların ivme kazandığı hissediliyor; emeklerinin görülmeye, çabalarının karşılık bulmaya başladığı bir hareket bu. Daha uzun vadede ise sıkışan bir işin çözülmeye başlaması, beklenen bir cevabın gelip içini rahatlatması olası.\"},{\"claims\":[\"c3\"],\"text\":\"Bu ilerleyişin ortasında önüne gelen seçenekler arasında bir karar anı da belirebilir gibi.\"}]}";

/**
 * Further SIMULATED scenarios: C3.1 set id, trusted intention, writer output.
 * Story contract: the core development carries the reading, support is brief,
 * a minor meaning is a short touch (human-authored, NOT provider output).
 */
export const COFFEE_V3N_SIMULATED_SCENARIOS = [
  { setId: 'C3F-GAZETA', intention: 'Önümüzdeki dönem genel olarak', output: "{\"paragraphs\":[{\"claims\":[\"c1\",\"c2\"],\"text\":\"Önümüzdeki dönemde iş tarafında sıkışan bir meselenin çözülmeye başladığı, içini ferahlatan bir rahatlama seziliyor. Tam bu açılımın içinde önüne iki teklif ya da iki yol çıkabilir; hangisinin sana iyi geleceği zamanla netleşiyor gibi ve karar anı bu ferahlıkla birlikte geliyor.\"},{\"claims\":[\"c3\"],\"text\":\"Daha ileride durgun işlerin yeniden hareketlendiği, kısa bir yolculuğun da gündeme gelebileceği görülüyor.\"}]}" },
  { setId: 'C3F-UNAL', intention: 'Aşk ve ilişkilerim hakkında', output: "{\"paragraphs\":[{\"claims\":[\"c1\",\"c2\"],\"text\":\"Aşk ve ilişkiler tarafında yakın zamanda planların son anda değişebilir; beklenmedik bir gelişme alışık olduğun dengeleri biraz oynatıyor gibi. Bu değişimle birlikte yakın günlerde araların düzelmesi, bir gerginliğin yavaş yavaş yatışması da olası; telaşın yerini daha sakin bir yakınlık alıyor.\"},{\"claims\":[\"c2\"],\"text\":\"Seni yoran o durum yumuşadıkça yakın günlerde gönlün de, günlerin de daha sakin akıyor gibi.\"}]}" },
  { setId: 'C3F-HALIL', intention: 'İşim ve kariyerim hakkında', output: "{\"paragraphs\":[{\"claims\":[\"c1\",\"c2\"],\"text\":\"İş ve kariyer tarafında yakın zamanda seni yoran bir gerginliğin yatıştığı, araların düzeldiği seziliyor; telaşın yerini dinginlik alıyor gibi. Daha uzun vadede ise planların son anda değişebilir; beklenmedik bir gelişme işlerin dengesini biraz değiştiriyor ama bu dönüş sana yabancı gelmiyor gibi.\"},{\"claims\":[\"c3\"],\"text\":\"Bu arada yakın günlerde küçük işler ve koşuşturmalar gündemini canlı tutabilir.\"}]}" },
] as const;
