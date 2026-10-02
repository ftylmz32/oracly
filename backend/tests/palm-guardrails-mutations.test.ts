/**
 * Palm guardrail mutations around one clean, second-person control.
 * Mutations deliberately use wording that differs from the audited real
 * output, so a class is caught by its shape rather than by a phrase list.
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { evaluatePalmQuality, type PalmQualityInput } from '../src/ai/human-quality.js';
import { bindPalmNarrative, narrativeFail } from '../src/ai/reading/evidence-bind.js';
import type { PalmNarrative } from '../src/ai/reading/types.js';
import { ErrorCode } from '../src/errors.js';

type Lane = 'overall' | 'lifeLine' | 'headLine' | 'heartLine' | 'fateLine' | 'takeaway';

const CONTROL: PalmQualityInput = {
  visualObservation:
    'Açık bir avuç içi; başparmağın çevresindeki yay ve ortadaki çizgi belirgin, üstteki çizgi daha hafif seçiliyor.',
  overall:
    'Bu avuçta önce kendi ritmini bulup sonra harekete geçen bir yapı öne çıkıyor. Yeni bir şeye hemen atılmaktan çok, onu bir süre yanında taşıyıp tanımayı seviyor olabilirsin; merak sende sessiz ama kalıcı bir yerde duruyor.',
  lifeLine:
    'Başparmağı uzun ve kesintisiz bir kavisle saran yaşam çizgin, gündelik düzenine kendi işaretini koymayı sevdiğini düşündürüyor; bir ortama alıştıkça orada daha cömert ve rahat olabilirsin.',
  headLine:
    'Avucun ortasından geçen belirgin baş çizgin, merakını somut bir işe bağladığında en iyi halini bulduğunu anlatıyor; soyut fikirler sende elle tutulur bir karşılık bulunca canlanıyor gibi.',
  heartLine:
    'Hafif ve ince seçilen kalp çizgin, sevgini büyük sözlerden çok küçük ve düzenli jestlerle gösterdiğini düşündürüyor; yakınlık sende gösterişten çok dikkat olarak yaşanıyor.',
  fateLine: '',
  takeaway:
    'Bu avuçta merak, düzen ve sevgi aynı ritimde çalışıyor: geç başlıyor, ama başladığında derin kök salıyor.',
  language: 'tr',
  trustedHandSide: true,
};

const append = (lane: Lane, sentence: string): PalmQualityInput => ({
  ...CONTROL,
  [lane]: `${CONTROL[lane]} ${sentence}`.trim(),
});
const replace = (lane: Lane, value: string): PalmQualityInput => ({ ...CONTROL, [lane]: value });

const MUTATIONS: Array<[string, PalmQualityInput, string]> = [
  ['dictionary voice (attributed)', append('headLine', 'Bu yapı somut bir merak tarzına atfedilir.'), 'dictionary_voice'],
  ['dictionary voice (corresponds)', append('heartLine', 'Bu incelik ölçülü bir sevgiye karşılık geliyor.'), 'dictionary_voice'],
  ['dictionary voice (interpreted as)', append('lifeLine', 'Bu kavis sahiplenme olarak yorumlanabilir.'), 'dictionary_voice'],
  ['invented karşı taraf', append('heartLine', 'Karşı tarafın bu küçük jestleri her zaman yakalayamayabileceğini bilirsin.'), 'unsupported_other_person'],
  ['invented partner', append('heartLine', 'Partnerin bu dikkati çoktan hissediyor olabilir.'), 'unsupported_other_person'],
  ['other-person mental state', append('overall', 'Çevrendekiler bu sakinliği bazen mesafe sanabilir.'), 'unsupported_other_person'],
  ['presumed current decision', append('headLine', 'Şu günlerde bir iş teklifini tartıyorsun.'), 'presumed_user_state'],
  ['presumed effortful choice', append('headLine', 'Seçmeye çalıştığın yol burada sabır istiyor gibi.'), 'presumed_user_state'],
  ['invented past attachment', append('lifeLine', 'Vazgeçtiğin eski bir bağın izi hâlâ sende duruyor gibi.'), 'presumed_user_state'],
  ['invented ongoing attachment', append('heartLine', 'Yıllardır sevgini sessizce taşıyor olabilirsin.'), 'presumed_user_state'],
  ['coaching directive', append('takeaway', 'Bu yüzden ritmini koru ve kimseye kendini açıklama.'), 'coaching_voice'],
  ['coaching obligation', append('takeaway', 'Duygularını daha erken paylaşmalısın.'), 'coaching_voice'],
  ['coaching homework', append('takeaway', 'Kendine her hafta biraz zaman tanı.'), 'coaching_voice'],
  ['"sana iyi gelir"', append('takeaway', 'Akşamları kısa yürüyüşler yapmak sana iyi gelir.'), 'coaching_voice'],
  ['medical inference', append('heartLine', 'Bu incelik bir sağlık sorununun habercisi olabilir.'), 'prohibited_claim'],
  ['lifespan inference', append('lifeLine', 'Bu yay uzun bir ömre işaret ediyor.'), 'prohibited_claim'],
  ['deterministic future', append('overall', 'Bu bağ mutlaka evliliğe dönüşecek.'), 'unsupported_certainty'],
  ['dated prediction', append('lifeLine', 'Önümüzdeki yıl yeni bir şehre taşınacaksın.'), 'unsupported_certainty'],
  [
    'second → third person switch',
    append('overall', 'Yeni bir ortama girdiğinde önce gözlemlemesi, sonra kendi hızında yaklaşması ve güven oluşunca bağ kurması daha olasıdır.'),
    'person_switch',
  ],
  [
    'takeaway semantic echo',
    replace('takeaway', 'Kendi ritmini bulmadan harekete geçmeyen, yeni olanı yanında taşıyan sessiz bir merak bu avucun özeti gibi.'),
    'section_redundancy',
  ],
  [
    'takeaway restates line geometry',
    replace('takeaway', 'Uzun ve kesintisiz yaşam çizgin, merakının da kök saldığını düşündürüyor.'),
    'section_redundancy',
  ],
];

const CONTROLS: Array<[string, PalmQualityInput]> = [
  ['clean control (honest empty fateLine)', CONTROL],
  ['natural second-person tendency', append('headLine', 'Karar verirken ayrıntıları tartmaya yatkın olabilirsin.')],
  ['generic relationship tendency', append('heartLine', 'İlişkilerde güveni önemseyebilirsin.')],
  ['cautious symbolic language', append('overall', 'Burada sabrın sende bir alışkanlıktan çok bir tercih gibi durduğu söylenebilir.')],
  ['evidence-linked meaning sentence', replace('lifeLine', 'Başparmağı geniş bir yayla saran yaşam çizgin, yeni bir yere alıştıkça orada kök salmayı sevdiğini anlatıyor.')],
  ['concise takeaway without advice', replace('takeaway', 'Merak sende geç uyanıyor, ama uyandığında uzun soluklu bir eğilime dönüşüyor.')],
];

describe('Palm guardrails — mutations around a clean control', () => {
  it.each(MUTATIONS)('%s is rejected', (_name, input, code) => {
    expect(evaluatePalmQuality(input)).toBe(code);
  });

  it.each(CONTROLS)('%s passes', (_name, input) => {
    expect(evaluatePalmQuality(input)).toBeNull();
  });

  it('a stated intention licenses the situation it states', () => {
    const decision = append('headLine', 'Karar vermeye çalıştığın konu, bu çizgide sabırla tartılıyor gibi.');
    expect(evaluatePalmQuality(decision)).toBe('presumed_user_state');
    expect(evaluatePalmQuality({ ...decision, hasStatedContext: true })).toBeNull();
  });
});

describe('Palm guardrails — routing to repair', () => {
  const fixture = JSON.parse(readFileSync('./tests/fixtures/batch3a/palm_good.json', 'utf8'));
  const narrative = (input: PalmQualityInput): PalmNarrative => {
    const section = (t: string) => ({ text: t, evidenceIds: t ? ['p1', 'p2', 'p3'] : [] });
    return {
      visualObservation: section(input.visualObservation),
      overall: section(input.overall),
      lifeLine: section(input.lifeLine),
      headLine: section(input.headLine),
      heartLine: section(input.heartLine),
      fateLine: section(input.fateLine),
      takeaway: section(input.takeaway),
    };
  };

  it('the clean control binds', () => {
    expect(bindPalmNarrative(narrative(CONTROL), fixture.observation, 'tr', true)).toBeNull();
  });

  it.each(MUTATIONS)('%s reaches repair by its own code and fails as quality', (_n, input, code) => {
    const bound = bindPalmNarrative(narrative(input), fixture.observation, 'tr', true);
    expect(bound).toBe(code);
    let thrown: unknown;
    try {
      narrativeFail(bound!);
    } catch (e) {
      thrown = e;
    }
    expect(thrown).toMatchObject({ code: ErrorCode.qualityUnavailable });
  });

  it('an intention in personalization reaches the stated-context exception', () => {
    const decision = append('headLine', 'Karar vermeye çalıştığın konu, bu çizgide sabırla tartılıyor gibi.');
    const n = narrative(decision);
    expect(bindPalmNarrative(n, fixture.observation, 'tr', true)).toBe('presumed_user_state');
    expect(bindPalmNarrative(n, fixture.observation, 'tr', true, { intention: 'Bir karar vermeye çalışıyorum' })).toBeNull();
  });
});
