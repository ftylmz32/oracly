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
export const COFFEE_V3N_PREMIUM_WRITER_OUTPUT = JSON.stringify({
  "paragraphs": [
    {
      "claims": [
        "c1",
        "c2"
      ],
      "text": "Yakın zamanda, yakın çevrende ve kendi dünyanda zamanla büyüyen, kök salan bir gelişme seziliyor. Acele eden bir hareket değil bu; yavaş ama sağlam bir büyüme, emeklerinin zamanla filizlendiği bir dönem gibi görünüyor. Aynı dönemde vermen gereken kararla ilgili gündemindeki meselenin de ivme kazanabileceği, adım adım güçlenerek ilerleyebileceği hissediliyor."
    },
    {
      "claims": [
        "c3",
        "c4"
      ],
      "text": "Önümüzdeki dönemde önünde birden fazla seçeneğin belirebileceği görülüyor; bu seçenekler birbirinden ayrıştıkça hangisinin sana daha yakın olduğu kendiliğinden belirginleşebilir. Daha uzun vadede ise önünün açılabileceği, sana nefes aldıran ferah bir aralığın oluşabileceği seziliyor. Bu açılım, şu an üzerinde düşündüğün kararın daha rahat, daha az sıkıştırılmış bir yerden verilebileceği bir alan gibi; kararın zamanla kendine uygun bir yere oturabilir."
    }
  ]
});

/** Same, for the structure-only RITAG cup (the shape of the first real three-photo run). */
export const COFFEE_V3N_RITAG_WRITER_OUTPUT = JSON.stringify({
  "paragraphs": [
    {
      "claims": [
        "c1",
        "c2"
      ],
      "text": "Vermen gereken kararla ilgili bir konunun yakın zamanda ivme kazanabileceği hissediliyor. Bu hareket aceleyle gelen bir sıçrama gibi değil; kesintisiz ama zamana yayılan, adım adım güçlenen bir ilerleme gibi görünüyor. Daha uzun vadede ise önünün açılabileceğini, sana nefes aldıran ferah bir aralık oluşabileceğini sezdiriyor. İçinde taşıdığın bu kararın, zorlamadan kendi ritminde rahatlayabileceği bir dönem gibi."
    },
    {
      "claims": [
        "c3"
      ],
      "text": "Önümüzdeki dönemde önünde birden fazla seçeneğin belirebileceği görülüyor. Bu seçenekler birbirinden ayrıştıkça hangisinin sana daha yakın olduğunu hissetmen kolaylaşabilir. Hangi yönün ağır basacağı şimdilik açık değil; seçenekler çoğaldıkça kararın da daha net bir yön bulabilir."
    }
  ]
});

/** Further SIMULATED scenarios: C3.1 set id, trusted intention, writer output. */
export const COFFEE_V3N_SIMULATED_SCENARIOS = [
  {
    "setId": "C3F-GAZETA",
    "intention": "Önümüzdeki dönem genel olarak",
    "output": "{\"paragraphs\":[{\"claims\":[\"c1\",\"c2\"],\"text\":\"Önümüzdeki dönemde bir konunun önünün açılabileceği, sana daha rahat hareket edebileceğin ferah bir alan bırakabileceği hissediliyor. Bu açılımın içinde birden fazla seçenek de belirebilir; sanki rahatladıkça önündeki yönler çoğalıyor. Seçenekler birbirinden ayrıştıkça neyin sana iyi geldiğini daha net görebilirsin.\"},{\"claims\":[\"c3\"],\"text\":\"Daha uzun vadede bir konunun yavaş yavaş hareketlenip yol alabileceği seziliyor. Bu ilerleme kesintisiz bir akış gibi görünüyor; duraksamadan, kendi temposunda devam eden bir gidişat. Gösterişli değil ama istikrarlı; belki de ancak dönüp baktığında ne kadar yol aldığını fark edeceğin sakin bir ilerleme olabilir.\"}]}"
  },
  {
    "setId": "C3F-UNAL",
    "intention": "Aşk ve ilişkilerim hakkında",
    "output": "{\"paragraphs\":[{\"claims\":[\"c1\",\"c2\"],\"text\":\"Aşk ve ilişkiler tarafında yakın zamanda beklenmedik bir dönüş, planladığından biraz farklı bir yöne değişim hissediliyor. Bu değişimle birlikte hareketli günlerinin yavaş yavaş durulup sakinleşeceği de seziliyor. Telaşın azaldığı, gönlünün daha sakin bir yerde dinlenebileceği bir dönem gibi görünüyor.\"},{\"claims\":[\"c3\"],\"text\":\"Belli belirsiz de olsa içindeki meselenin kendi içinde tamamlanıp yerine oturacağı hissediliyor. Bir dönemin sessizce toparlanması, ilişkiler tarafında daha olgun ve daha netleşmiş bir hâle geçiş gibi; zorlamadan, kendi zamanında olgunlaşan bir kapanış. Bu toparlanmayla birlikte gönlündeki bir meselenin de zamanla netleşebileceği seziliyor.\"}]}"
  },
  {
    "setId": "C3F-HALIL",
    "intention": "İşim ve kariyerim hakkında",
    "output": "{\"paragraphs\":[{\"claims\":[\"c1\",\"c2\"],\"text\":\"İş ve kariyer tarafında yakın zamanda hareketli bir konunun yavaş yavaş durulup sakinleşebileceği seziliyor. Bu sakinleşme bir anda değil, zamana yayılan ve kesintisiz bir yatışma gibi görünüyor. Daha uzun vadede ise bununla bağlantılı bir dönüş, planladığından biraz farklı bir yöne değişim belirebilir.\"},{\"claims\":[\"c3\"],\"text\":\"Yakın dönemde gündeminin küçük işlerle ve ayrıntılarla dolabileceği hissediliyor. Birçok iş aynı anda ilerleyebilir; kalabalık ama dağınık olmayan, hareketli bir tempo gibi. Bu yoğunluk yorucu olmaktan çok, işlerinin akışını canlı tutan bir hareketlilik gibi hissedilebilir.\"}]}"
  }
] as const;
