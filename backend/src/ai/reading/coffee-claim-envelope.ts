import { coffeeReadingSelfReference, foldTr, type HumanQualityFailure } from '../human-quality.js';
import { coffeeForbiddenFortuneSpecificFailure } from './coffee-public-language.js';
import type { CoffeeNarrative } from './types.js';
import type { CoffeePropositionKind } from './coffee-semantic-propositions.js';
import type { CoffeeStoryPlanV2 } from './coffee-story-plan.js';

function fold(value: string): string {
  return value.normalize('NFC').toLocaleLowerCase('tr-TR');
}

const ABSTRACT_RESTATEMENT: Record<CoffeePropositionKind, RegExp> = {
  exchange_emergence: /hayatında iletişim (önem kazan|öne çık|belirginleş)|iletişim hayatında belirleyici/,
  opening_availability: /fırsatlar? (öne çık|belirginleş)|hayatında .*fırsat (bulunuyor|doğuyor|beliriyor)/,
  connection_continuity: /hayatında .*bağ (öne çık|belirginleş)|ana (vurgu|sonuç).*bağ/,
  felt_significance: /duygusal (bir )?(konu|mesele) (gündeme|belirginleş)|duyguların .*belirleyici/,
  resolution_availability: /(çözüm|netlik) (öne çık|belirginleş)|ana sonuç.*çözüm/,
  directional_change: /(hareket|ilerleme|hareket alanı) (öne çık|belirginleş)|ana sonuç.*hareket/,
  alternative_distinction: /ana vurgu.*(seçim|tercih)|belirleyici bir seçim/,
  gradual_expansion: /(büyüme|gelişme|gelişim) (öne çık|belirginleş)|ana tema.*büyüme/,
  social_presence: /sosyal (alan|çevre|bağlar) (öne çık|belirginleş)/,
  proximate_context: /(ev ve yakın çevre|evin ve yakın çevren).*(öne çık|belirgin|ağırlık)|ana vurgu.*(ev|yakın çevre)/,
};

const COMPONENT_MENTION: Record<CoffeePropositionKind, RegExp> = {
  exchange_emergence: /iletişim|konuşma|haber|mesaj/,
  opening_availability: /fırsat|açılım|imkân|imkan/,
  connection_continuity: /bağ|bağlantı|devamlılık/,
  felt_significance: /duygu|duygusal|his/,
  resolution_availability: /çözüm|netlik|açıklık/,
  directional_change: /hareket|ilerleme|yön değişimi/,
  alternative_distinction: /seçim|seçenek|alternatif|tercih/,
  gradual_expansion: /büyüme|gelişme|genişleme/,
  social_presence: /sosyal|çevre|kişi/,
  proximate_context: /ev|yakın çevre|yakın halka/,
};

/**
 * C2.7C.1 — internal-only realization vocabulary for the inter-proposition
 * causation gate (never sent to the writer). Word-initial stems, matched
 * against tr-TR folded words, so inflections ("paylaşımın", "doğrultuyu",
 * "yönünü", "netliği") resolve to their proposition kind.
 */
const REALIZATION_STEM: Record<CoffeePropositionKind, RegExp> = {
  exchange_emergence: /^(iletişim|konuşma|haber|mesaj|paylaşım|alışveriş)/,
  opening_availability: /^(fırsat|açılım|imkân|imkan)/,
  connection_continuity: /^(bağlantı|devamlılı)/,
  felt_significance: /^(duygu|duygusal)/,
  resolution_availability: /^(çözüm|netli[kğ]|açıklı[kğ])/,
  directional_change: /^(yön(?!elik|etim|etici)|doğrultu|hareket|ilerleme)/,
  alternative_distinction: /^(seçenek|seçim|alternatif|tercih)/,
  gradual_expansion: /^(büyüme|genişleme|gelişim)/,
  social_presence: /^(sosyal)/,
  proximate_context: /^ev(in|ine|de|den|i|e)?$/,
};

/** A acts on B: transitive / causative change predicates (word-initial). */
const CAUSATIVE_PREDICATE =
  /^(çevir|değiştir|döndür|yönlendir|dönüştür|netleştir|belirginleştir|aydınlat|hareketlendir|yarat|oluştur|doğur|getir|sağla|tetikle|kolaylaştır|genişlet|büyüt|güçlendir|it(er|ebil|ecek|iyor|ti|mesi)|aç(ar|abil|acak|ıyor|tı|ması|tığ|mış))/;
/** B changes because of A: intransitive change predicates (word-initial). */
const CHANGE_PREDICATE =
  /^(değiş|dönüş|netleş|belirginleş|açıl|hareketlen|genişle|büyü|güçlen|kolaylaş|şekillen|yönel)/;
/** "because of / through / by means of A". */
const CAUSAL_POSTPOSITION = /^(sayesinde|yüzünden|nedeniyle|sebebiyle|etkisiyle|aracılığıyla|sonucunda)$/;
/** Coordination makes two kinds co-subjects, never agent and patient. */
const COORDINATION = /^(ve|ile|veya|ya|hem|birlikte|beraber)$/;
const ACCUSATIVE = /(y[ıiuü]|n[ıiuü]|[^l][ıiuü])$/;
const INSTRUMENTAL = /(y?l[ae])$/;

function kindOf(word: string, planned: CoffeePropositionKind[]): CoffeePropositionKind | null {
  return planned.find((kind) => REALIZATION_STEM[kind].test(word)) ?? null;
}

/**
 * One planned proposition's realization grammatically acts on another
 * planned proposition's realization ("paylaşımın mevcut doğrultuyu başka
 * bir tarafa çevirebileceğini", "paylaşımla yönün değişebilir") while the
 * story plan relates them only as co-occurring. Plan-aware: needs two
 * DIFFERENT planned kinds in one sentence, so a single-proposition reading
 * and ordinary use of these verbs elsewhere are never affected.
 */
function unsupportedPropositionCausation(texts: string[], plan: CoffeeStoryPlanV2): boolean {
  const planned = [...new Set([plan.lead.kind, ...plan.supporting.map((item) => item.kind)])];
  if (planned.length < 2) return false;
  if (!plan.supporting.every((item) => item.relation === 'co_occurring')) return false;
  for (const sentence of texts.flatMap((text) => text.split(/[.!?;]+/u))) {
    const words = sentence.split(/[^\p{L}]+/u).filter(Boolean);
    for (let i = 0; i < words.length; i++) {
      const agent = kindOf(words[i], planned);
      if (!agent) continue;
      if (INSTRUMENTAL.test(words[i]) && /^(birlikte|beraber)$/.test(words[i + 1] ?? '')) continue;
      const agentIsInstrumental = INSTRUMENTAL.test(words[i]) || CAUSAL_POSTPOSITION.test(words[i + 1] ?? '');
      for (let j = i + 1; j < words.length; j++) {
        if (COORDINATION.test(words[j])) break;
        const patient = kindOf(words[j], planned);
        if (!patient || patient === agent) continue;
        const window = words.slice(j + 1, j + 7);
        // A + B-accusative (or its head noun, "çözüm alanını") + causative.
        const accusative = ACCUSATIVE.test(words[j]) || ACCUSATIVE.test(words[j + 1] ?? '');
        if (accusative && window.some((word, index) =>
          CAUSATIVE_PREDICATE.test(word) || (word === 'yol' && /^aç/.test(window[index + 1] ?? '')))) {
          return true;
        }
        // "A ile / A sayesinde" + B + intransitive change.
        if (agentIsInstrumental && window.some((word) => CHANGE_PREDICATE.test(word))) return true;
      }
    }
  }
  return false;
}

// Letter-aware word edges: JS word boundaries are ASCII-only and misfires on Turkish letters.
const S = '(?<![\\p{L}])';
const E = '(?![\\p{L}])';
const re = (source: string) => new RegExp(source, 'u');

/**
 * C2.9 — PERSON-OF-INTEREST protections. "Aklımdaki kişi" declares only that
 * the user has someone in mind: never a relationship, a mutual bond, that
 * person's feelings or thoughts, or their future action toward the user.
 * Subject-aware: these words stay legal in every other context.
 */
const PERSON_EXISTING_BOND = re(`${S}aranızda\\p{L}*`);
const PERSON_MUTUALITY = re(
  `${S}(iki taraf(ın|ı)? da|her iki taraf\\p{L}*|karşılıklı|o da|birbiriniz\\p{L}*)${E}`,
);
const PERSON_MIND_READING = re(
  `${S}(onun|o kişinin|aklındaki kişinin|karşındakinin|karşı tarafın) (duygu|his|niyet|düşünce|tavr|kalb|ilgi)\\p{L}*`
  + `|${S}(duyguları|hisleri|niyeti)${E}|${S}sana karşı (bir )?(his|duygu|ilgi)\\p{L}*`,
);
const PERSON_AGENCY = re(
  `${S}sana (yaklaş|ulaş|yaz|mesaj at|dön|açıl|gel|ilgi göster)\\p{L}*`
  + `|${S}seni (ara|düşün|özle|sev|iste|bekle|merak ed)\\p{L}*`
  + `|${S}o (seni|sana)${E}`
  + `|${S}aklındaki kişi\\p{L}*[^.!?]{0,50}${S}(arayacak|yazacak|gelecek|dönecek|yaklaşacak|açılacak|düşünüyor|hissediyor|istiyor|özlüyor|seviyor|adım atacak|ilk adım)`,
);

export function coffeePersonIntentionClaim(texts: string[]): HumanQualityFailure | null {
  const text = texts.map(fold).join(' ');
  if (PERSON_EXISTING_BOND.test(text)) return 'unsupported_existing_fact';
  if (PERSON_MUTUALITY.test(text) || PERSON_MIND_READING.test(text) || PERSON_AGENCY.test(text)) {
    return 'unsupported_other_agency';
  }
  return null;
}

/**
 * C2.9 — META-NARRATION. Behaviour classes, not sentences:
 * (A) the prose talks about the reading itself (this interpretation, its
 *     focus, the general impression, what the analysis shows);
 * (B) the prose explains the story plan's synthesis rules (two abstract
 *     tendencies merely side by side, one not creating the other, both
 *     forming one whole). Ordinary "yan yana", "yorum", "izlenim" stay legal.
 */
const META_SELF_REFERENCE = [
  re(`${S}(bu|şu) (yorum|okuma|fal|değerlendirme|analiz)\\p{L}*[^.!?]{0,40}(odağ|merkez|özü|ana fikr|vurgu|gösteriyor|anlatıyor|söylüyor|işaret ediyor|ortaya koyuyor|odaklan)`),
  re(`${S}yorumun (odağ|merkez|özü|ana fikr)`),
  re(`${S}genel (izlenim|tablo|görünüm|değerlendirme)\\p{L}*[^.!?]{0,80}(anlatıyor|gösteriyor|söylüyor|işaret ediyor|ortaya koyuyor|yansıtıyor)`),
  // C2.11: analyst summary nouns as a sentence subject ("… ana sonucu",
  // "öne çıkan sonuç", "temel vurgu"), passive emphasis, naming the request.
  re(`${S}(ana|asıl|temel|esas|öne çıkan) (sonu[çc]|vurgu|mesaj|çizgi)\\p{L}*`),
  re(`${S}vurgulan(ıyor|mış|maktadır|an)${E}`),
  re(`${S}(kariyer|iş|maddi|aşk|ilişki|para)\\p{L}* (niyet|talep|soru)\\p{L}*`),
  // A demonstrative gloss: "Bu, … bir hâli anlatıyor / … anlamına geliyor."
  re(`^\\s*bu(,| da| ise)\\s[^.!?]{0,200}(anlatıyor|ifade ediyor|anlamına geliyor|demek oluyor)\\s*$`),
];
const META_CONSTRAINT = [
  re(`${S}iki (eğilim|anlam|unsur|bileşen|tema|olgu|his|imkân|imkan|gelişme|durum)\\p{L}*[^.!?]{0,60}(yan yana|bir arada|aynı bütün|tek bir (anlam|bütün)|birbirini (zorla|yarat|doğur|etkile|tetikle))`),
  re(`${S}(biri|birisi|hiçbiri) (diğerini|ötekini|öbürünü) (yarat|doğur|tetikle)\\p{L}*`),
  re(`${S}(biri|hiçbiri)[^.!?]{0,20}(diğerine|ötekine) (neden|sebep) ol(madan|muyor|maz)`),
  re(`${S}ikisi( de)? aynı bütün`),
  re(`aynı bütün(ün)? içinde (yan yana|duruyor|yer alıyor|buluşuyor)`),
  re(`${S}(eğilim|anlam|imkân|imkan|açıklık|çözüm|his|duygu|fırsat)\\p{L}*[^.!?]{0,60}yan yana (dur|bulun|yer al|var ol)\\p{L}*`),
  re(`${S}tek bir (anlamda|bütünde|gelişme halinde) (buluş|birleş|belir)\\p{L}*`),
  re(`${S}birbirinden ayrılmadan[^.!?]{0,40}(birleş|buluş)\\p{L}*`),
  // C2.11: two coordinated meanings that "meet in one place" or "cannot be
  // separated", "carried within one whole", and disclaimers that narrate a
  // forbidden claim ("… vaadinden çok", "… dair bir anlam taşımadan").
  re(`${S}ile${E}[^.!?]{0,100}(aynı|tek) (yer|nokta|zemin|bütün)\\p{L}* (buluş|birleş)\\p{L}*`),
  re(`${S}ile${E}[^.!?]{0,100}birbirinden ayrıl(mıyor|maz|madan)`),
  re(`aynı bütün(ün)? içinde (taşı|yer al|dur|buluş|birleş)\\p{L}*`),
  re(`${S}\\p{L}+ vaadinden çok`),
  re(`${S}(vaat|garanti) (etmese|etmeden|etmiyor)\\p{L}*`),
  re(`(belirli bir kişi|kesin bir sonu)\\p{L}*[^.!?]{0,40}(işaret etme|vaat etme|ya da sonu)\\p{L}*`),
  re(`${S}\\p{L}+ (dair|ilişkin) (bir )?(anlam|iddia|vaat)\\p{L}* taşı(madan|mıyor|maz)`),
  // C2.11A: analysis nouns narrated as such ("buradaki anlam", "bu iki anlam",
  // "bu hâl/durum … anlam taşıyor / anlatıyor").
  re(`${S}buradaki (anlam|mesaj|vurgu|tema)\\p{L}*`),
  re(`${S}bu iki (anlam|eğilim|tema|unsur|bileşen)\\p{L}*`),
  re(`${S}bu (hâl|hal|durum)\\p{L}*[^.!?]{0,40}(anlam taşı|anlatıyor|işaret ediyor|ifade ediyor)\\p{L}*`),
];

export function coffeeMetaNarration(texts: string[]): string | null {
  for (const sentence of texts.map(fold).flatMap((text) => text.split(/[.!?]+/u))) {
    if (!sentence.trim()) continue;
    if (META_SELF_REFERENCE.some((rule) => rule.test(sentence))) return sentence.trim();
    if (META_CONSTRAINT.some((rule) => rule.test(sentence))) return sentence.trim();
    if (coffeeReadingSelfReference(foldTr(sentence))) return sentence.trim();
  }
  return null;
}

/** C2.9 — broad subject vocabulary (word-initial); never exact intention wording. */
const SUBJECT_ANCHOR: Record<'love' | 'career' | 'money' | 'person' | 'decision', RegExp> = {
  love: /^(aşk|ilişki|sevgi|sevdi|kalp|kalb|gönül|gönl|romantik|yakınlı|yakınlaş|duygusal)/u,
  career: /^(kariyer|meslek|çalışma|çalışt|proje|profesyonel|görev|ekib|ekip|iş(im|in|imde|inde|te|le|ler|leri|lerin|lerinde|ine|ini|i|e|yeri\p{L}*|hayat\p{L}*)?$)/u,
  money: /^(para|parasal|maddi|kazanç|kazanc|gelir|bütçe|harcama|birikim|finans|bolluk)/u,
  person: /^(aklındaki|kişi|onunla|ona$|onu$|onun$)/u,
  decision: /^(karar|seçenek|seçim|tercih)/u,
};
const SUBJECT_DENIAL =
  /(tek|herhangi|belirli) bir (alan|konu)\p{L}*[^.!?]{0,25}(bağlanma|sınırlı kalma|sınırlanma)\p{L}*/u;

function hasAnchor(texts: string[], anchor: RegExp): boolean {
  return texts.some((text) => (fold(text).match(/\p{L}+/gu) ?? []).some((word) => anchor.test(word)));
}

/** C2.9 — the trusted subject must be answered, never dropped or denied. */
export function coffeeSubjectAlignmentFailure(
  narrative: CoffeeNarrative,
  plan: CoffeeStoryPlanV2,
): 'missing_intention_subject' | 'intention_subject_drift' | null {
  const subject = plan.subject;
  if (!subject) return null;
  const section = subject.requiredSection;
  if (section && !narrative[section].text.trim()) return 'missing_intention_subject';
  const carriers = [narrative.overall.text, narrative.takeaway.text];
  const anchor = subject.kind === 'person_of_interest'
    ? new RegExp(`${SUBJECT_ANCHOR.person.source}|${SUBJECT_ANCHOR.love.source}`, 'u')
    : subject.kind === 'custom_decision'
      ? SUBJECT_ANCHOR.decision
      : section
        ? SUBJECT_ANCHOR[section]
        : null;
  if (!anchor) return null;
  if (section && SUBJECT_DENIAL.test(fold([...carriers, narrative.visualObservation.text].join(' ')))) {
    return 'intention_subject_drift';
  }
  return hasAnchor(carriers, anchor) ? null : 'intention_subject_drift';
}

/**
 * C2.11 — IMPLIED EXISTING BOND. Under a plan that forbids an existing
 * relationship (every intention except a literal current-relationship
 * declaration), prose may promise a bond forming, never one being kept,
 * continuing, or preserved. Ordinary "bağ" stays legal.
 */
const IMPLIED_EXISTING_BOND = [
  re(`${S}(bağ|ilişki|yakınlı)(ın|in|ğın|ınız|iniz|ının|inin|ğınız|nin|nın|niz|nız)? (korunma|sürme|devam|süreklili|devamlılı|kopma)\\p{L}*`),
  re(`${S}(mevcut|süregelen|var olan|sürdürdüğün) (bir )?(bağ|ilişki|birliktelik)\\p{L}*`),
  re(`${S}(bağ|ilişki)\\p{L}*[^.!?]{0,40}(varlığını|özünü|yerini|değerini) (koruyor|sürdürüyor|kaybetmeden|kaybetmiyor)`),
];

/** C2.11 — subject LABEL openings (mechanical restatement of the request). */
const SUBJECT_LABEL: Record<'career' | 'money' | 'love' | 'person' | 'decision', RegExp> = {
  career: re(`^(iş ve kariyer|kariyer|iş (hayatı|yaşamı)|mesleki (alan|yön|çizgi|hareket|gündem)|çalışma hayatı|profesyonel alan)\\p{L}*`),
  money: re(`^(maddi|para konusu|mali (alan|durum|kapasite)|finansal)\\p{L}*`),
  love: re(`^(aşk ve ilişki|aşk (hayatı|alanı|konusu)|aşkta|ilişkiler(in)?(de)?|duygusal (dünya|alan)|kalbin)\\p{L}*`),
  person: re(`^(aklındaki kişi|bu kişi)\\p{L}*`),
  decision: re(`^(vermen gereken karar|kararın|senin kararın)\\p{L}*`),
};
/** Abstract restatement nouns that a label is mechanically glued to. */
const ABSTRACT_NOUN = re(
  `${S}(alan|alanı|açıklı|imkân|imkan|pay|karşılı|anlam|önem|ağırlı|değer|süreklili|devamlılı|bütünlü|çözüm|erişilebilir|ulaşılabilir|esneklik|kapasite|hareket|odak|yön|potansiyel|netli|ayrım|fark)\\p{L}*`,
);
const INTENTION_STOPWORDS = new Set(['hakkında', 'ilgili', 'olan', 'gereken', 'nasıl', 'olarak', 'genel', 'dönem']);

function sentencesOf(texts: string[]): string[] {
  return texts.map(fold).flatMap((text) => text.split(/[.!?;]+/u)).map((sentence) => sentence.trim()).filter(Boolean);
}

function subjectLabel(plan: CoffeeStoryPlanV2): RegExp | null {
  const subject = plan.subject;
  if (!subject) return null;
  if (subject.kind === 'person_of_interest') return SUBJECT_LABEL.person;
  if (subject.kind === 'custom_decision') return SUBJECT_LABEL.decision;
  if (subject.kind === 'general') return null;
  const domain = subject.requiredSection ? SUBJECT_LABEL[subject.requiredSection] : null;
  // Custom text: two of the request's own content words opening a sentence.
  const own = (fold(subject.intention).match(/\p{L}+/gu) ?? [])
    .filter((word) => word.length >= 4 && !INTENTION_STOPWORDS.has(word))
    .map((word) => word.slice(0, 4));
  if (own.length < 2) return domain;
  const stem = `(${own.map((value) => `${value}\\p{L}*`).join('|')})`;
  const ownLabel = re(`^${stem}( \\p{L}+){0,2} ${stem}`);
  return domain ? re(`${domain.source}|${ownLabel.source}`) : ownLabel;
}

/**
 * C2.11 — INTENTION PARROTING: sentences that open with the request's label
 * and glue an abstract noun to it ("İş ve kariyerinde … alan", "Maddi
 * durumunda … imkân"). A natural mention of work/love/money is fine; the
 * failure is the label carrying the reading (three or more such sentences).
 */
export function coffeeIntentionParroting(narrative: CoffeeNarrative, plan: CoffeeStoryPlanV2): string[] {
  const label = subjectLabel(plan);
  if (!label) return [];
  return sentencesOf([
    narrative.visualObservation.text, narrative.overall.text, narrative.love.text,
    narrative.career.text, narrative.money.text, narrative.takeaway.text,
  ]).filter((sentence) =>
    label.test(sentence.replace(/^(senin için|sende|sana göre),? /u, '')) && ABSTRACT_NOUN.test(sentence));
}

/**
 * C2.11A — the FIRST sentence of overall opens with the request's label,
 * glues an abstract noun to it, and tells no development ("İş ve kariyer
 * alanında erişilebilir bir açılım bulunuyor."). Development-first openings
 * that mention the subject naturally pass.
 */
export function coffeeLabelLedOpening(narrative: CoffeeNarrative, plan: CoffeeStoryPlanV2): boolean {
  const label = subjectLabel(plan);
  const first = sentencesOf([narrative.overall.text])[0];
  if (!label || !first) return false;
  return label.test(first.replace(/^(senin için|sende|sana göre),? /u, ''))
    && ABSTRACT_NOUN.test(first)
    && !DEVELOPMENT.test(first);
}

/** Proposition-definition vocabulary (private; never sent to the writer). */
const DEFINITION_STEM: Record<CoffeePropositionKind, RegExp> = {
  exchange_emergence: re(`${S}(iletişim|paylaşım|alışveriş|karşılıklı|etkileşim)\\p{L}*`),
  opening_availability: re(`${S}(imkân|imkan|fırsat|açıklı|açılım|hareket payı|alan)\\p{L}*`),
  connection_continuity: re(`${S}(bağ|devamlılı|süreklili|kalıcı|kopmadan)\\p{L}*`),
  felt_significance: re(`${S}(anlam|önem|ağırlı|değer|derin)\\p{L}*`),
  resolution_availability: re(`${S}(çözüm|çıkış|netli|çözülme)\\p{L}*`),
  directional_change: re(`${S}(yön|doğrultu|hareket)\\p{L}*`),
  alternative_distinction: re(`${S}(seçenek|ayrım|fark|ayrış|ihtimaller)\\p{L}*`),
  gradual_expansion: re(`${S}(genişle|büyü|kapasite|gelişim)\\p{L}*`),
  social_presence: re(`${S}(çevre|sosyal)\\p{L}*`),
  proximate_context: re(`${S}(ev|yakın çevre)\\p{L}*`),
};
/** A stative close: the sentence only asserts that the meaning exists. */
const STATIVE_CLOSE = re(
  '(durumda|bulunuyor|var|mevcut|taşıyor|koruyor|sürüyor|belirgin|değil|duruyor|kalıyor|sahip|beliriyor|öne çıkıyor|belirginleşiyor|belirginleştiriyor|ayrışıyor|yatıyor|sunuyor|elverişli|açık|güçlü|derin|yer alıyor|karşılık geliyor|ağırlık kazanıyor)$',
);
/** A development: something arrives, moves, opens, or is about to happen. */
const DEVELOPMENT = re(
  `(acak|ecek|acağ|eceğ)\\p{L}*${E}|(?<!karşılık )${S}(gel|ulaş|açıl(?!ım)|başla|kıpırda|hareketlen|yaklaş|düş|çık|dön|kapı|haber|ses|söz)\\p{L}*`,
);

/**
 * C2.11 — SEMANTIC RESTATEMENT: the prose merely asserts that the planned
 * meaning exists (definition stem + stative close, no development) instead of
 * telling a development. Plan-aware; fails only when it carries the reading.
 */
export function coffeeSemanticRestatement(narrative: CoffeeNarrative, plan: CoffeeStoryPlanV2): string[] {
  const kinds = [plan.lead.kind, ...plan.supporting.map((item) => item.kind)];
  const lane = plan.subject?.requiredSection ? narrative[plan.subject.requiredSection].text : '';
  const sentences = sentencesOf([narrative.visualObservation.text, narrative.overall.text, lane, narrative.takeaway.text]);
  const restating = sentences.filter((sentence) =>
    kinds.some((kind) => DEFINITION_STEM[kind].test(sentence))
    && STATIVE_CLOSE.test(sentence)
    && !DEVELOPMENT.test(sentence));
  return restating.length >= 3 && restating.length * 2 >= sentences.length ? restating : [];
}

/**
 * C2.11 SAFETY TIER — serious unsupported claims. Runs before every style or
 * length diagnostic so a stylistic failure can never hide one of these.
 */
export function coffeeClaimSafetyFailure(
  narrative: CoffeeNarrative,
  plan: CoffeeStoryPlanV2,
): HumanQualityFailure | null {
  const texts = [
    narrative.visualObservation.text,
    narrative.overall.text,
    narrative.love.text,
    narrative.career.text,
    narrative.money.text,
    narrative.nearFuture.text,
    narrative.takeaway.text,
  ].map(fold);
  const text = texts.join(' ');
  const forbidden = new Set(plan.claimEnvelope.forbiddenAssumptions);

  if (forbidden.has('awaited_topic') && /beklediğin|beklemekte olduğun|önem verdiğin bir iletişim/.test(text)) {
    return 'presumed_user_state';
  }
  if (forbidden.has('prior_problem') && /uzun süredir.{0,45}(zor|çöz|uğraş|meşgul)|seni (zorlayan|uğraştıran)|zihnini meşgul eden|aradığın (karşılık|çözüm|çıkış|cevap)/.test(text)) {
    return 'unsupported_existing_fact';
  }
  if (forbidden.has('existing_relationship') && /\b(partnerin|ilişkin|ilişkinizde|aranızdaki)\b/.test(text)) {
    return 'unsupported_existing_fact';
  }
  if (forbidden.has('existing_relationship') && IMPLIED_EXISTING_BOND.some((rule) => rule.test(text))) {
    return 'unsupported_existing_fact';
  }
  if (plan.subject?.kind === 'person_of_interest') {
    const personClaim = coffeePersonIntentionClaim(texts);
    if (personClaim) return personClaim;
  }
  if (forbidden.has('reciprocal_feeling') && /karşılıklı (yakınlık|duygu|his|bağlılık)|birbirinizi|birbirinize/.test(text)) {
    return 'unsupported_other_agency';
  }
  if (forbidden.has('prior_stagnation') && /durgun(luk| giden)|bekleyen (konu|süreç)|aynı çerçevede kalan/.test(text)) {
    return 'unsupported_existing_fact';
  }
  if (forbidden.has('current_major_decision') && /bir seçimle karşı karşıya|vereceğin karar|kararını netleştir|doğru seçimi/.test(text)) {
    return 'presumed_user_state';
  }
  if (forbidden.has('options_assumption') && /seçenekler(in)? arasında|kararın|kuru bir hesap|ihtimallerden ayır/.test(text)) {
    return 'presumed_user_state';
  }
  if (forbidden.has('travel') && /yolculuk|seyahat/.test(text)) return 'unsupported_existing_fact';
  if (forbidden.has('relocation') && /taşın|yer değiştir/.test(text)) return 'unsupported_existing_fact';
  if (forbidden.has('family_event') && /ziyaretçi|misafir|aile içinde .*olacak|evde .*yaşanacak/.test(text)) {
    return 'context_event';
  }
  // C2.11A: external specifics the active fortune plan forbids (sender,
  // employer/company, payment event, amount, salary/debt, date, another
  // person's feelings) — after the more specific relationship/agency codes,
  // before causation/chronology/certainty.
  const specific = coffeeForbiddenFortuneSpecificFailure(narrative, plan);
  if (specific) return specific;
  if (forbidden.has('causation') && /(?:iletişim|konuşma|haber|mesaj|çözüm|netlik|hareket|fırsat).{0,45}(sağlayacak|yol açacak|neden olacak|tetikleyecek|doğuracak|beraberinde getirecek)|\b(böylece|bu nedenle|bu yüzden|dolayısıyla|sayesinde|sonucunda)\b/.test(text)) {
    return 'unsupported_source_causation';
  }
  if (forbidden.has('causation') && unsupportedPropositionCausation(texts, plan)) {
    return 'unsupported_source_causation';
  }
  // A literal waiting declaration carries its own "after …" (the user wrote
  // it); only sentences that restate that waiting are exempt from chronology.
  const awaiting = plan.subject?.declaredFacts.includes('awaiting_response') ?? false;
  const declaredStems = awaiting
    ? (fold(plan.subject!.intention).match(/\p{L}+/gu) ?? []).filter((word) => word.length >= 5).map((word) => word.slice(0, 5))
    : [];
  const chronologyText = awaiting
    ? texts.flatMap((value) => value.split(/[.!?;]+/u))
      .filter((sentence) => !/bekl/u.test(sentence) && !declaredStems.some((stem) => sentence.includes(stem)))
      .join(' ')
    : text;
  if (forbidden.has('chronology') && /önce\b.{1,70}\bsonra|ilk olarak|ardından|akabinde|devamında|sonrasında|daha sonra|bir sonraki adımda/.test(chronologyText)) {
    return 'unsupported_chronology';
  }
  // C2.11A: "… olacak gibi" is an explicit hedge, not a guarantee; bare
  // "olacak", "kesinlikle", "mutlaka" stay certainty.
  if (forbidden.has('guaranteed_outcome') && /kesinlikle|mutlaka|olacak(?! gibi)\b|yapacaksın\b|edeceksin\b|bir sonuç taşıyor|sonuca (ulaşacak|bağlanacak)/.test(text)) {
    return 'unsupported_certainty';
  }
  return null;
}

/**
 * C2.11 REALIZATION TIER, in precedence order: subject alignment →
 * meta-narration → intention parroting → semantic restatement.
 */
export function coffeeRealizationFailure(
  narrative: CoffeeNarrative,
  plan: CoffeeStoryPlanV2,
): HumanQualityFailure | null {
  const subjectFailure = coffeeSubjectAlignmentFailure(narrative, plan);
  if (subjectFailure) return subjectFailure;
  const texts = [
    narrative.visualObservation.text, narrative.overall.text, narrative.love.text,
    narrative.career.text, narrative.money.text, narrative.nearFuture.text, narrative.takeaway.text,
  ];
  if (coffeeMetaNarration(texts)) return 'meta_narration';
  if (coffeeIntentionParroting(narrative, plan).length >= 3 || coffeeLabelLedOpening(narrative, plan)) {
    return 'intention_parroting';
  }
  if (coffeeSemanticRestatement(narrative, plan).length > 0) return 'semantic_restatement';
  return null;
}

/** Remaining plan-aware style checks (they run after the generic quality gate). */
export function coffeeClaimStyleFailure(
  narrative: CoffeeNarrative,
  plan: CoffeeStoryPlanV2,
): HumanQualityFailure | null {
  const text = [
    narrative.visualObservation.text, narrative.overall.text, narrative.love.text,
    narrative.career.text, narrative.money.text, narrative.nearFuture.text, narrative.takeaway.text,
  ].map(fold).join(' ');
  const forbidden = new Set(plan.claimEnvelope.forbiddenAssumptions);
  const kinds = [plan.lead.kind, ...plan.supporting.map((item) => item.kind)];
  if (plan.synthesis.mode === 'unified_cooccurrence') {
    const sentences = fold(narrative.overall.text).split(/[.!?]+/u).filter((sentence) => sentence.trim());
    const singleComponentSentences = sentences
      .map((sentence) => kinds.filter((kind) => COMPONENT_MENTION[kind].test(sentence)))
      .filter((mentioned) => mentioned.length === 1)
      .map(([kind]) => kind);
    if (new Set(singleComponentSentences).size >= 2) return 'component_serialization';
  }
  if (kinds.some((kind) => ABSTRACT_RESTATEMENT[kind].test(text))) return 'abstract_reading';
  if (forbidden.has('advice') && /\b(malısın|melisin|dikkat et|gözünü açık|sana iyi gelir)\b/.test(text)) {
    return 'coaching_voice';
  }
  return null;
}

/** The whole plan-aware envelope in precedence order: safety → realization → style. */
export function coffeeClaimEnvelopeFailure(
  narrative: CoffeeNarrative,
  plan: CoffeeStoryPlanV2,
): HumanQualityFailure | null {
  return coffeeClaimSafetyFailure(narrative, plan)
    ?? coffeeRealizationFailure(narrative, plan)
    ?? coffeeClaimStyleFailure(narrative, plan);
}
