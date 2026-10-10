import {
  toCoffeeM2WriterPayload,
  type CoffeeM2WriterPayload,
  type CoffeeM2WriterPlan,
  type CoffeeM2WriterQualifiers,
} from './coffee-m2-writer-beat-plan.js';
import { assertCoffeeV3MeaningOnly } from './coffee-v3-mark-map.js';

/**
 * W4A — DARK NATURAL TURKISH SURFACE BANK. ADDITIVE AND DARK: no live path,
 * writer, worker or route imports this.
 *
 * LANGUAGE DATA, NOT SEMANTIC DATA. Each row gives several natural ways to say
 * ONE already-licensed meaning (an M2 class, a conjecture nuance, a curated
 * relation, a scenario manifestation, a qualifier). Nothing here adds a
 * meaning, event, consequence, timing, person or history, and nothing here
 * changes what W2 plans: composition stays deterministic, while the choice
 * among equivalent wordings is left to the future writer (no phrase is
 * selected in code, so readings do not become canned).
 *
 * Roles:
 * - lead: a noun phrase that can open or carry a sentence;
 * - predicate: a finite main statement;
 * - modifier: an adverbial / adjectival piece inside another sentence;
 * - continuation: refers back to an already stated idea (elaboration beats);
 * - relational: joins the two components of a curated relation (co-development, never causal);
 * - scenario: a finite possibility clause for a scenario manifestation.
 */

export type CoffeeTurkishSurfaceRole = 'lead' | 'predicate' | 'modifier' | 'continuation' | 'relational' | 'scenario';

export type CoffeeTurkishSurfaceRow = {
  /** The licensed meaning this row realizes (documentation; never sent to a writer). */
  meaning: string;
  /** high_value rows need >= 4 alternatives, narrow rows >= 3, unless `exception` documents why not. */
  tier: 'high_value' | 'narrow';
  forms: Partial<Record<CoffeeTurkishSurfaceRole, readonly string[]>>;
  /** Row-specific wording to avoid (drift or overlap traps). */
  avoid?: readonly string[];
  exception?: string;
};

type Rows = Readonly<Record<string, CoffeeTurkishSurfaceRow>>;

// ---------------------------------------------------------------------------
// Global register guard
// ---------------------------------------------------------------------------

/** Report language, abstract nouns, AI / disclaimer wording and empty fortune clichés. */
export const COFFEE_TURKISH_GLOBAL_AVOID: readonly string[] = [
  // report / abstract register
  'seyir taşıyor', 'nitelik taşıyor', 'bir durum mevcut', 'tema', 'hareket dinamiği', 'dinamik', 'olasılık alanı', 'aynı hareketin parçası',
  'iki yüzü olarak duruyor', 'aynı gönül meselesinin iki yüzü', 'belirgin bir tablo sunuyor', 'süreç', 'hareket alanı',
  'gelişim potansiyeli', 'zemin', 'işaret ediyor', 'öne çık', 'belirginleş', 'pozitif enerji',
  // reading-about-reading / AI / disclaimer
  'bu falda', 'genel olarak', 'enerjine baktığımda', 'analize göre', 'kesin değil', 'garanti değil', 'yalnızca bir olasılık',
  'eğlence amaçlı',
  // empty clichés and decorative imagery no token licenses
  'enerjin çok yüksek', 'evren sana', 'güzel şeyler olacak', 'şans senden yana', 'her şey yoluna girecek',
  'kapılar ardına kadar', 'yıldızın parlıyor', 'rüzgâr değişiyor', 'kader seni çağırıyor',
];

// ---------------------------------------------------------------------------
// M2 classes (source of truth: COFFEE_M2_CORE_CLASS / MODIFIER_FACET / CONSEQUENCE_FACET)
// ---------------------------------------------------------------------------

export const COFFEE_TURKISH_CLASS_WORDING: Rows = {
  FORWARD: {
    meaning: 'a matter keeps moving forward on its own course (or, as a quality, steadily)',
    tier: 'high_value',
    forms: {
      predicate: ['yerinde saymıyor', 'kendi akışında ilerliyor', 'kendi akışında adım adım ilerliyor', 'yoluna devam ediyor', 'kendi yolunda yürüyor'],
      lead: ['kendi akışında ilerleyen bir gidişat', 'yoluna devam eden bir konu', 'adım adım ilerleyen bir yol'],
      modifier: ['istikrarla', 'adım adım', 'yerinde saymadan'],
    },
    avoid: ['sağlam', 'hız kesmeden', 'kesintisiz'],
  },
  MULTIPLICITY: {
    meaning: 'a matter opens into several separate possibilities / directions',
    tier: 'high_value',
    forms: {
      predicate: ['birkaç ayrı ihtimale açılıyor', 'önünde birkaç ayrı ihtimal beliriyor', 'tek bir yolda kalmıyor, birkaç yöne ayrılıyor', 'birden fazla yol beliriyor', 'birkaç seçenek birden ortaya çıkıyor'],
      lead: ['birkaç ayrı ihtimal', 'birden fazla yol', 'birkaç farklı seçenek'],
      continuation: ['bu ihtimaller', 'bu seçenekler', 'açılan bu yollar'],
    },
    avoid: ['doğru seçenek', 'yanlış seçenek', 'dallan'],
  },
  UNEVEN: {
    meaning: 'progress comes intermittently, moving and pausing (no obstacle, delay or failure)',
    tier: 'high_value',
    forms: {
      predicate: ['ara ara hareketleniyor', 'bir ilerleyip bir duruyor', 'tek solukta değil, aralıklarla ilerliyor', 'kesik kesik ilerliyor', 'bazen hızlanıp bazen yavaşlıyor'],
      modifier: ['ara ara', 'aralıklarla', 'tek solukta değil', 'kesik kesik'],
    },
    avoid: ['seyir taşıyor', 'engel', 'gecikme', 'takıl', 'inişli çıkışlı', 'zorluk'],
  },
  OPENING: {
    meaning: 'an opening / access that clears the way',
    tier: 'high_value',
    forms: {
      predicate: ['önün açılıyor', 'yolun açılıyor', 'bir yol açılıyor', 'önünü açan bir gelişme beliriyor'],
      lead: ['önünü açan bir gelişme', 'açılan bir yol', 'önünde açılan bir yol'],
      continuation: ['açılan bu yol', 'bu açılan yol'],
    },
    avoid: ['geçit', 'açılım', 'ferahl', 'rahatla', 'kapılar ardına kadar'],
  },
  CHANGE: {
    meaning: 'a change of direction / a turn',
    tier: 'high_value',
    forms: {
      predicate: ['yön değiştiriyor', 'başka bir yöne dönüyor', 'yönünü çeviriyor', 'farklı bir yöne kıvrılıyor'],
      lead: ['yeni bir yön', 'bir yön değişikliği', 'bir dönüş', 'başka bir yöne dönüş'],
    },
    avoid: ['taşın', 'yolculuk', 'seyahat'],
  },
  OPPORTUNITY: {
    meaning: 'a kısmet / opportunity',
    tier: 'high_value',
    forms: {
      lead: ['bir kısmet', 'bir fırsat', 'önüne çıkabilecek bir imkân', 'bir nasip'],
      predicate: ['önüne bir kısmet çıkıyor', 'bir fırsat beliriyor', 'kısmetin açılıyor'],
      continuation: ['bu kısmet', 'gelen fırsat'],
    },
    avoid: ['kesin', 'para gelecek', 'zengin'],
  },
  GROWTH: {
    meaning: 'something that grows gradually over time',
    tier: 'high_value',
    forms: {
      predicate: ['zamanla büyüyor', 'yavaş yavaş çoğalıyor', 'gitgide genişliyor', 'zaman içinde artıyor'],
      lead: ['zamanla büyüyen bir gelişme', 'yavaş yavaş büyüyen bir kısmet'],
      modifier: ['zamanla', 'yavaş yavaş', 'gitgide'],
      continuation: ['bu büyüme', 'büyümesi'],
    },
    avoid: ['hızla', 'birden'],
  },
  COMMUNICATION: {
    meaning: 'news / a communication movement (no sender, no certainty that it arrives)',
    tier: 'high_value',
    forms: {
      lead: ['bir haber', 'bir iletişim', 'bir haberleşme'],
      predicate: ['bir haber gündeme geliyor', 'iletişim tarafı hareketleniyor', 'bir haber kıpırdanıyor', 'haberleşme canlanıyor'],
      continuation: ['bu hareket', 'bu iletişim'],
    },
    avoid: ['arayacak', 'yazacak', 'dönecek', 'haber yolda'],
  },
  WRITTEN_COMMUNICATION: {
    meaning: 'written news / correspondence',
    tier: 'narrow',
    forms: {
      lead: ['yazılı bir haber', 'bir yazışma', 'bir mesaj'],
      predicate: ['yazılı bir haber gündeme geliyor', 'bir yazışma hareketleniyor', 'bir mesajlaşma canlanıyor'],
    },
    avoid: ['yazacak'],
  },
  COMMITMENT: {
    meaning: 'a possibility of a lasting, serious bond',
    tier: 'high_value',
    forms: {
      lead: ['kalıcı bir bağ', 'ciddi bir bağ', 'uzun soluklu bir bağ', 'kalıcı bir bağ ihtimali'],
      predicate: ['kalıcı bir bağa doğru gidiyor', 'ciddi bir bağa dönüşebilir', 'kalıcı bir hâl almaya doğru gidiyor'],
      continuation: ['bu bağ', 'bu bağ ihtimali'],
    },
    avoid: ['sağlam', 'evlilik', 'nişan', 'köklü', 'meylediyor'],
  },
  FEELING: {
    meaning: 'feelings deepen (the user\'s; never another person\'s)',
    tier: 'high_value',
    forms: {
      predicate: ['duyguların derinleşiyor', 'hislerin yoğunlaşıyor', 'içindeki duygu derinleşiyor', 'hislerin daha derine iniyor'],
      continuation: ['derinleşen duyguların', 'bu duygular'],
    },
    avoid: ['seni seviyor', 'özlüyor', 'karşı tarafın duyguları'],
  },
  PEOPLE: {
    meaning: 'people are present around the user (presence only, never their actions)',
    tier: 'narrow',
    forms: {
      predicate: ['çevrende insanlar beliriyor', 'etrafında insanlar oluyor', 'çevrende kalabalık bir hava var'],
    },
    avoid: ['destek oluyor', 'konuşuyorlar', 'seni seçiyor'],
  },
  MOMENTUM: {
    meaning: 'active, gaining momentum',
    tier: 'narrow',
    forms: {
      predicate: ['hareketleniyor', 'hız kazanıyor', 'canlanıyor', 'giderek hız kazanıyor'],
      modifier: ['hareketli', 'canlı', 'hız kazanan'],
    },
  },
  QUIET: {
    meaning: 'quiet, not yet opened up',
    tier: 'narrow',
    forms: {
      predicate: ['henüz sessiz', 'henüz açılmamış', 'kendini henüz tam göstermemiş'],
      modifier: ['sessiz', 'henüz açılmamış'],
    },
    avoid: ['şimdilik', 'sakin', 'durgun', 'tıkalı'],
  },
  DIRECT: {
    meaning: 'open, straightforward',
    tier: 'narrow',
    forms: { modifier: ['açık', 'dolambaçsız', 'doğrudan'] },
  },
  REACHING: {
    meaning: 'coming towards the user',
    tier: 'narrow',
    forms: { modifier: ['sana doğru gelen', 'sana uzanan', 'senin tarafına yönelen'] },
  },
  RECURRENCE: {
    meaning: 'comes up more than once',
    tier: 'narrow',
    forms: { modifier: ['birden fazla kez beliren', 'birkaç kez karşına çıkan', 'bir kereyle kalmayan'] },
    avoid: ['tekrar', 'yeniden'],
  },
  MULTI_STREAM: {
    meaning: 'from several separate sources, not a single one',
    tier: 'narrow',
    forms: { modifier: ['birkaç ayrı koldan', 'tek bir koldan değil, birkaç ayrı koldan', 'farklı yerlerden', 'birden fazla yoldan'] },
  },
  CLOSE_CIRCLE: {
    meaning: 'in the user\'s close circle',
    tier: 'narrow',
    forms: { modifier: ['sana yakın çevrede', 'yakın çevrende', 'kendi çevrende'] },
  },
  SINGULAR: {
    meaning: 'focused on a single place / one direction',
    tier: 'narrow',
    forms: { modifier: ['tek bir yere yönelen', 'tek bir noktada toplanan', 'dağılmadan tek bir yerde toplanan', 'tek bir yöne bakan'] },
  },
  DURABLE: {
    meaning: 'whole, intact, solid',
    tier: 'narrow',
    forms: { modifier: ['bütün', 'sağlam', 'kopukluk olmadan bütün', 'bölünmeden duran'] },
  },
  LEANING: {
    meaning: 'inclining to one side',
    tier: 'narrow',
    forms: {
      predicate: ['bir yana meylediyor', 'bir tarafa doğru eğiliyor', 'bir yöne kayıyor'],
      modifier: ['bir yana meyleden'],
    },
  },
  GATHERING: {
    meaning: 'people gathering together (presence only)',
    tier: 'narrow',
    forms: { lead: ['bir araya gelen insanlar', 'toplanan bir kalabalık', 'bir arada olan insanlar'] },
  },
  SMALL_DETAILS: {
    meaning: 'several small details',
    tier: 'narrow',
    forms: { lead: ['birkaç küçük ayrıntı', 'ufak tefek ayrıntılar', 'küçük küçük ayrıntılar'] },
  },
  PHASE: {
    meaning: 'within one bounded stage (reachable since V3G1: cup-wall closed loop)',
    tier: 'narrow',
    // W4A.1: never dönem / zaman — those are horizon words ("önümüzdeki dönemde … tek bir dönem içinde").
    forms: { modifier: ['tek bir aşamada', 'tek bir aşamanın içinde'] },
    avoid: ['dönem içinde', 'dönemin içinde', 'zaman diliminde', 'aynı aşama', 'aşamaya yayılmadan'],
    exception: 'Only two stage forms are genuinely equivalent: "aynı aşama" presupposes an unstated reference stage, "evre" is bookish, "aşamaya yayılmadan" adds an all-at-once completion claim.',
  },
};

/**
 * Conjecture tokens whose nuance goes beyond their class (a class row must not
 * claim it when the token is absent: "güzel" only with beautiful_kismet,
 * "bereket" only with abundance).
 */
export const COFFEE_TURKISH_TOKEN_WORDING: Rows = {
  beautiful_kismet: { meaning: 'a beautiful / auspicious kısmet', tier: 'narrow', forms: { lead: ['güzel bir kısmet', 'hayırlı bir kısmet', 'iyi bir fırsat'] } },
  abundance: { meaning: 'abundance, bereket', tier: 'narrow', forms: { predicate: ['bereketleniyor', 'bereketi artıyor', 'bereketli bir hâl alıyor'], lead: ['bereket'] } },
  new_beginning: { meaning: 'a new beginning', tier: 'narrow', forms: { lead: ['yeni bir başlangıç', 'yeni bir sayfa', 'taze bir başlangıç'] } },
  usable_opening: { meaning: 'an opening that is genuinely usable', tier: 'narrow', forms: { modifier: ['gerçekten işine yarayacak', 'işine yarayacak türden', 'kullanabileceğin'] } },
  way_through: { meaning: 'a way through', tier: 'narrow', forms: { lead: ['geçebileceğin bir yol', 'önünü açan bir yol', 'ilerleyebileceğin bir yol'] } },
  serious_heart_kismet_possibility: { meaning: 'a possibility of a serious heart kısmet', tier: 'narrow', forms: { lead: ['ciddi bir gönül kısmeti', 'gönül tarafında ciddi bir kısmet', 'ciddi bir aşk kısmeti'] } },
  heart_inclines: { meaning: 'the heart inclines to one side', tier: 'narrow', forms: { predicate: ['gönlün bir yana meylediyor', 'kalbin bir tarafa çekiliyor', 'gönlün bir yöne kayıyor'] } },
  options_clarify: { meaning: 'options become clearer', tier: 'narrow', forms: { predicate: ['seçenekler daha net görünmeye başlıyor', 'önündeki seçenekler berraklaşıyor', 'seçenekler daha açık seçiliyor'] } },
  upward_progression: { meaning: 'progressing upward', tier: 'narrow', forms: { modifier: ['yukarı doğru', 'yükselerek', 'bir basamak yukarı çıkarak'] } },
  long_running: { meaning: 'long-running, continuing', tier: 'narrow', forms: { modifier: ['uzun soluklu', 'kısa sürmeyen', 'süreklilik taşıyan'] } },
};

// ---------------------------------------------------------------------------
// Curated relations (co-development; never causal)
// ---------------------------------------------------------------------------

export const COFFEE_TURKISH_RELATION_WORDING: Rows = {
  course_opens_into_alternatives: {
    meaning: 'the matter is moving and, as it moves, opens into several possibilities',
    tier: 'high_value',
    forms: {
      relational: [
        'yol aldıkça birkaç ayrı ihtimale açılıyor',
        'ilerledikçe tek bir hatta kalmıyor, birkaç yöne ayrılıyor',
        'yürüdükçe önünde birden fazla yol beliriyor',
        'yerinde saymıyor; ilerledikçe önüne birkaç seçenek birden çıkıyor',
        'kendi akışında ilerlerken birkaç ayrı ihtimale açılıyor',
      ],
    },
    avoid: ['sağlayabilir', 'yüzünden', 'sayesinde', 'netleşmesini sağla'],
  },
  opportunity_with_gradual_growth: {
    meaning: 'growing_kismet: the opened kısmet grows over time',
    tier: 'high_value',
    forms: {
      relational: [
        'bu kısmet zamanla büyüyor',
        'kısmetin, zaman içinde büyüyen cinsten',
        'gelen fırsat yavaş yavaş genişliyor',
        'kısmet açıldıkça büyüyor',
        'bu fırsat, zamanla çoğalan bir kısmet',
      ],
    },
    avoid: ['önce', 'sonra', 'sayesinde'],
  },
  access_through_direction: {
    meaning: 'the opening comes from within a change of direction',
    tier: 'high_value',
    forms: {
      relational: [
        'önünü açan şey yeni bir yönün içinden geliyor',
        'bu yol, yeni bir yönün içinden geçiyor',
        'yolun döndüğü yerde önün de açılıyor',
        'önündeki yol açılırken yeni bir yöne de kıvrılıyor',
        'yeni bir yöne dönüşle birlikte önün açılıyor',
      ],
    },
    avoid: ['yön değiştirirsen', 'sayesinde'],
  },
  commitment_with_emotion: {
    meaning: 'a lasting bond and deepening feeling belong together (heartfelt_lasting_bond_possibility)',
    tier: 'high_value',
    forms: {
      relational: [
        'duyguların derinleşirken bağ da kalıcı bir hâl almaya doğru gidiyor',
        'kalıcı bir bağ ihtimali, derinleşen duygularla birlikte geliyor',
        'bağ ciddileşirken duyguların da derinleşiyor',
        'duyguların derinleştikçe bağ da daha kalıcı bir hâl alıyor',
      ],
    },
    avoid: ['iki yüzü', 'gönül meselesi', 'seni seviyor'],
  },
  choice_with_direction: {
    meaning: 'options and a direction take shape together',
    tier: 'high_value',
    forms: {
      relational: [
        'önündeki seçeneklerle birlikte yönün de değişiyor',
        'seçenekler belirirken yön de başka bir yana dönüyor',
        'seçeneklerin arasından yeni bir yön beliriyor',
        'seçenekler ile yeni yön birlikte şekilleniyor',
      ],
    },
    avoid: ['doğru seçenek', 'şekillendiriyor'],
  },
  direction_with_growth: {
    meaning: 'a change of direction that develops over time',
    tier: 'high_value',
    forms: {
      relational: [
        'yeni yön zamanla büyüyen bir değişime dönüşüyor',
        'bu dönüş yavaş yavaş genişliyor',
        'yön değişikliği zaman içinde büyüyor',
        'başlayan değişim zamanla gelişiyor',
      ],
    },
  },
  contact_with_opportunity: {
    meaning: 'a kısmet comes together with news',
    tier: 'high_value',
    forms: {
      relational: [
        'kısmet bir haberle birlikte geliyor',
        'fırsat bir haberin içinde beliriyor',
        'bir haberle birlikte bir kısmet de beliriyor',
        'gelen haber ile kısmet aynı yerden kıpırdanıyor',
      ],
    },
    avoid: ['arayacak', 'haber gelince'],
  },
  written_contact_with_opportunity: {
    meaning: 'a kısmet comes together with written news',
    tier: 'high_value',
    forms: {
      relational: [
        'kısmet yazılı bir haberle birlikte geliyor',
        'fırsat yazılı bir haberin içinde beliriyor',
        'yazılı bir haberle birlikte bir kısmet de beliriyor',
        'bir yazışma ile kısmet aynı yerden kıpırdanıyor',
      ],
    },
    avoid: ['yazacak'],
  },
  stalled_course_finds_room: {
    meaning: 'a stop-start course and an opening develop together (no obstacle, no relief)',
    tier: 'high_value',
    // W4A.1: fortune wording ("önün / bir yol açılıyor"), never a description of empty space.
    forms: {
      relational: [
        'bir ilerleyip bir duran konuda bir yol da açılıyor',
        'tek solukta ilerlemeyen konuda önün de açılıyor',
        'ara ara hareketlenen konuda önünü açan bir gelişme de beliriyor',
        'kesik kesik ilerleyen konuda bir yol açılıyor',
        'konu aralıklarla ilerliyor; önün de açılıyor',
      ],
    },
    avoid: ['açık bir alan', 'alan bul', 'boşluk', 'açıklık', 'kendine yer', 'nihayet', 'sonunda', 'rağmen'],
  },
  opening_moves_forward: {
    meaning: 'the matter keeps moving and an opening also emerges (each group keeps its own horizon)',
    tier: 'high_value',
    // W4A.1: two finite clauses, no "-ken": the components may carry different horizons.
    // W4A.2: the carrier is the user's own "yol" (the fortune idiom of OPENING), never a
    // generic konu / işler / gidişat; no belir- so the verb can stay free for the next beat.
    forms: {
      relational: [
        'yolun yerinde saymıyor; önün de açılıyor',
        'yolun adım adım ilerliyor; önün de açılıyor',
        'yolun yerinde saymıyor; açılıyor da',
        'yolun adım adım ilerliyor; açılıyor da',
      ],
    },
    avoid: ['açılırken', 'ilerlerken', 'aynı anda', 'eşzamanlı', 'o sırada', 'açık bir alan', 'boşluk'],
  },
  possibilities_become_visible: {
    meaning: 'an opening and several possibilities becoming visible develop together',
    tier: 'high_value',
    forms: {
      relational: [
        'önün açılıyor, birkaç ihtimal de görünür hâle geliyor',
        'önün açılırken birden fazla yol da beliriyor',
        'açılan konuda birkaç seçenek birden ortaya çıkıyor',
        'açıldıkça birkaç ayrı ihtimal de görünüyor',
      ],
    },
    // W4A.1: "açılan yerde" was a spatial locative echoing the physical clear area.
    avoid: ['açılan yer', 'açık bir alan', 'boşluk'],
  },
};

// ---------------------------------------------------------------------------
// Scenario manifestations (finite possibility clauses; never certainty)
// ---------------------------------------------------------------------------

const scenario = (meaning: string, lead: string[], clause: string[], avoid?: string[]): CoffeeTurkishSurfaceRow => ({
  meaning,
  tier: 'narrow',
  forms: { lead, scenario: clause },
  ...(avoid ? { avoid } : {}),
});

export const COFFEE_TURKISH_SCENARIO_WORDING: Rows = {
  // career
  new_responsibility: scenario('a new responsibility', ['yeni bir sorumluluk', 'üstlenebileceğin yeni bir sorumluluk'], ['üstüne yeni bir sorumluluk gelebilir', 'yeni bir sorumluluk alabilirsin', 'eline yeni bir sorumluluk geçebilir']),
  different_role: scenario('a different role', ['farklı bir rol', 'başka bir görev'], ['farklı bir rol üstlenebilirsin', 'kendini başka bir görevde bulabilirsin', 'farklı bir rolde yer alabilirsin']),
  different_way_of_working: scenario('a change in the way of working', ['çalışma biçiminde bir değişiklik', 'başka bir çalışma düzeni'], ['çalışma biçimin değişebilir', 'işini başka bir düzende yapmaya başlayabilirsin', 'çalışma düzeninde bir değişiklik olabilir']),
  professional_direction_change: scenario('a change in professional direction', ['mesleki yönünde bir değişiklik', 'işinde başka bir yön'], ['mesleki yönün değişebilir', 'işinde başka bir yöne dönebilirsin', 'kariyerinde yön değiştirebilirsin']),
  other_professional_route: scenario('another professional route becomes relevant', ['başka bir mesleki yol', 'farklı bir iş yolu'], ['başka bir mesleki yol gündeme gelebilir', 'işinde farklı bir yol karşına çıkabilir', 'başka bir iş yolu önüne gelebilir']),
  multiple_professional_options: scenario('several professional options', ['birkaç farklı iş seçeneği', 'birden fazla mesleki seçenek'], ['iş tarafında birden fazla seçenek önüne gelebilir', 'birkaç farklı iş seçeneği belirebilir', 'işte elinde birkaç seçenek olabilir']),
  steady_professional_progress: scenario('steady professional progress', ['işlerinde düzenli bir ilerleme', 'adım adım bir ilerleme'], ['işlerin istikrarla ilerleyebilir', 'işinde düzenli bir ilerleme olabilir', 'iş tarafında adım adım yol alabilirsin']),
  // money
  new_financial_opportunity: scenario('a new financial opportunity', ['yeni bir kazanç fırsatı', 'yeni bir maddi fırsat', 'para tarafında yeni bir imkân'], ['yeni bir maddi fırsat çıkabilir', 'para tarafında yeni bir imkân doğabilir', 'eline yeni bir kazanç fırsatı geçebilir']),
  another_earning_channel: scenario('another earning channel', ['başka bir gelir kapısı', 'başka bir kazanç yolu'], ['başka bir kazanç yolu açılabilir', 'ek bir gelir kapısı belirebilir', 'kazancın başka bir koldan da gelebilir']),
  financial_side_strengthened: scenario('something that strengthens the financial side', ['maddi tarafını güçlendirecek bir imkân', 'maddi yanını destekleyecek bir imkân'], ['maddi tarafını güçlendirecek bir imkân çıkabilir', 'maddi yanını destekleyecek bir imkân belirebilir', 'parasal açıdan güç kazanabilirsin'], ['rahatlat', 'toparla', 'borç']),
  gradual_financial_improvement: scenario('gradual financial improvement', ['maddi tarafta yavaş yavaş bir iyileşme', 'adım adım bir iyileşme'], ['maddi tarafın yavaş yavaş iyileşebilir', 'para tarafında yavaş yavaş bir iyileşme olabilir', 'maddi durumun adım adım iyiye gidebilir'], ['düzel', 'sıkıntı']),
  multiple_supporting_channels: scenario('several supporting channels', ['birkaç destekleyici kol', 'farklı yerlerden gelen destek'], ['birkaç ayrı kol seni destekleyebilir', 'destek birkaç farklı yerden gelebilir', 'maddi tarafta birden fazla destek kolu oluşabilir']),
  additional_financial_possibility: scenario('an additional financial possibility', ['ek bir maddi ihtimal', 'para tarafında ek bir imkân'], ['ek bir maddi ihtimal belirebilir', 'para tarafında ek bir imkân çıkabilir', 'maddi olarak ekstra bir seçenek doğabilir']),
  option_affecting_money_setup: scenario('an option that could change the money setup', ['para düzenini değiştirebilecek bir seçenek', 'maddi düzenini etkileyebilecek bir seçenek'], ['para düzenini değiştirebilecek bir seçenek de çıkabilir', 'maddi düzenini etkileyebilecek bir seçenek gündeme gelebilir', 'maddi düzeninde bir şeyleri değiştirebilecek bir yol belirebilir']),
  // love
  new_connection_becoming_serious_or_existing_bond_clearer: scenario(
    'a new connection becoming serious, or an existing bond becoming clearer (one item with an internal "or")',
    ['ciddileşen yeni bir tanışıklık ya da netleşen bir bağ'],
    ['yeni bir tanışıklık ciddileşebilir ya da hayatındaki bir bağ netleşebilir', 'hayatında olan bir bağ daha net bir hâl alabilir ya da yeni bir tanışıklık ciddiye binebilir', 'ya yeni biriyle tanışıklık ciddileşebilir ya da var olan bir bağ netleşebilir'],
  ),
  declared_relationship_more_serious: scenario('the declared relationship becomes more serious', ['daha ciddi bir ilişki', 'ciddileşen bir ilişki'], ['ilişkin daha ciddi bir hâl alabilir', 'aranızdaki bağ daha ciddi bir yere gidebilir', 'bağınız daha ciddi, kalıcı bir hâl alabilir']),
  bond_more_visible: scenario('the bond takes a more visible place in the user\'s life', ['hayatında daha görünür bir yer', 'gündelik hayatında daha fazla yer'], ['bu bağ hayatında daha görünür bir yer tutabilir', 'ilişkin gündelik hayatında daha fazla yer alabilir', 'ilişkin hayatında daha çok yer kaplayabilir'], ['saklı', 'gizli']),
  // decision
  secondary_option_gaining_weight: scenario('one of the options gains weight', ['ağır basan bir seçenek', 'ağırlık kazanan bir seçenek'], ['seçeneklerden biri ağır basmaya başlayabilir', 'bir seçenek diğerlerine göre daha ağır basabilir', 'seçeneklerden biri gözünde ağırlık kazanabilir'], ['doğru seçenek', 'ağır gel']),
  another_option_relevant: scenario('another option becomes relevant', ['başka bir seçenek', 'gündeme gelen bir seçenek'], ['başka bir seçenek de gündeme gelebilir', 'aklına başka bir seçenek düşebilir', 'masaya başka bir seçenek gelebilir']),
  options_separating: scenario('the options separate more clearly from one another', ['birbirinden ayrılan seçenekler'], ['seçenekler birbirinden daha net ayrılabilir', 'hangi yolun ne olduğu daha açık seçilebilir', 'seçenekler arasındaki fark daha net görünebilir']),
  direction_change_worth_considering: scenario('turning to a different direction gains meaning', ['başka bir yön'], ['farklı bir yöne dönmek anlam kazanabilir', 'başka bir yön de düşünülecek hâle gelebilir', 'farklı bir yön aklına yatmaya başlayabilir'], ['doğru', 'mantıklı']),
  // awaited topic
  communication_around_awaited_matter: scenario('communication moves around the awaited matter (not a reply)', ['beklediğin konu etrafında bir iletişim'], ['beklediğin konu etrafında iletişim hareketlenebilir', 'o konuyla ilgili haberleşme canlanabilir', 'beklediğin meseleyle ilgili konuşmalar kıpırdanabilir'], ['cevap gelecek', 'olumlu dönüş']),
  written_information_relevant: scenario('written information becomes relevant', ['yazılı bir bilgi', 'bir belge ya da yazı'], ['yazılı bir bilgi gündeme gelebilir', 'bir belge ya da yazı önüne gelebilir', 'yazılı bir şey konuşulur hâle gelebilir']),
  // chosen person (Contract B: about the person, never their act or feeling)
  communication_around_chosen_person: scenario('communication relating to the chosen person', ['o kişiyle ilgili bir haber', 'o kişiyle ilgili bir haberleşme'], ['aklındaki kişiyle ilgili bir iletişim gündeme gelebilir', 'o kişiyle ilgili bir haberleşme kıpırdanabilir', 'o kişi etrafında iletişim hareketlenebilir'], ['seni arayacak', 'sana yazacak', 'geri dönecek', 'seni özlüyor']),
  conversation_about_person_relevant: scenario('a conversation about the person becomes relevant', ['o kişiyle ilgili bir konuşma', 'onun hakkında bir sohbet'], ['bu kişiyle ilgili bir konuşma gündeme gelebilir', 'o kişi hakkında bir sohbet açılabilir', 'onunla ilgili bir konuşmaya denk gelebilirsin'], ['barışma', 'seni seviyor']),
  // general
  another_direction: scenario('another direction', ['başka bir yön', 'farklı bir yön'], ['başka bir yön görünebilir', 'farklı bir yön belirebilir', 'farklı bir yol gündeme gelebilir']),
  another_option_visible: scenario('another option becomes visible', ['başka bir seçenek', 'farklı bir seçenek'], ['başka bir seçenek görünür olabilir', 'önüne başka bir seçenek çıkabilir', 'farklı bir seçenek belirebilir']),
  single_track_gaining_alternatives: scenario('a single-track matter gains alternatives', ['tek yönlü giden bir konu'], ['tek yönlü giden bir konu alternatif kazanabilir', 'tek yolda ilerleyen bir konuya yeni seçenekler eklenebilir', 'tek bir hatta giden bir iş başka seçeneklere de açılabilir']),
  matter_opening: scenario('a matter opens', ['açılan bir konu'], ['bir konu açılabilir', 'bir konunun önü açılabilir', 'bir mesele açılmaya başlayabilir'], ['kapalı duran', 'gizli']),
};

/**
 * Scenario cluster realization. Every multi-item M2 cluster is a set of
 * ALTERNATIVE concrete realizations of one development, not a checklist: the
 * writer uses ONE or TWO of them (the scenario group itself is never dropped).
 * Keys are the cluster's manifestations joined with "|" in M2 order.
 */
export type CoffeeTurkishScenarioClusterMode = { mode: 'alternatives' | 'complementary' | 'single'; choose: { min: number; max: number } };

const ALT = { mode: 'alternatives', choose: { min: 1, max: 2 } } as const;
const ONE = { mode: 'single', choose: { min: 1, max: 1 } } as const;

export const COFFEE_TURKISH_SCENARIO_CLUSTERS: Readonly<Record<string, CoffeeTurkishScenarioClusterMode>> = {
  'new_responsibility|different_role|different_way_of_working': ALT,
  'professional_direction_change|other_professional_route': ALT,
  'multiple_professional_options': ONE,
  'steady_professional_progress': ONE,
  'new_financial_opportunity|another_earning_channel|financial_side_strengthened': ALT,
  'new_financial_opportunity|financial_side_strengthened': ALT,
  'gradual_financial_improvement|multiple_supporting_channels': ALT,
  'additional_financial_possibility|option_affecting_money_setup': ALT,
  'new_connection_becoming_serious_or_existing_bond_clearer': ONE,
  'declared_relationship_more_serious|bond_more_visible': ALT,
  'secondary_option_gaining_weight|another_option_relevant|options_separating': ALT,
  'direction_change_worth_considering': ONE,
  'options_separating': ONE,
  'communication_around_awaited_matter': ONE,
  'communication_around_awaited_matter|written_information_relevant': ALT,
  'communication_around_chosen_person|conversation_about_person_relevant': ALT,
  'another_direction': ONE,
  'another_option_visible|single_track_gaining_alternatives': ALT,
  'matter_opening': ONE,
};

// ---------------------------------------------------------------------------
// Qualifiers
// ---------------------------------------------------------------------------

type Domain = NonNullable<CoffeeM2WriterQualifiers['domain']>['domain'];
type Binding = CoffeeM2WriterQualifiers['context'][number]['binding'];
type Horizon = 'nearer_term' | 'coming_period' | 'further_out';

export const COFFEE_TURKISH_DOMAIN_WORDING: Readonly<Record<Domain, CoffeeTurkishSurfaceRow>> = {
  financial: { meaning: 'the money / financial side', tier: 'narrow', forms: { modifier: ['maddi tarafta', 'para tarafında', 'maddi konularda', 'maddi açıdan'] } },
  career: { meaning: 'work and career', tier: 'narrow', forms: { modifier: ['iş tarafında', 'iş ve kariyer tarafında', 'işinde', 'kariyerinde', 'mesleki tarafta'] } },
  love: { meaning: 'the heart / love side', tier: 'narrow', forms: { modifier: ['gönül tarafında', 'aşk tarafında', 'duygusal tarafta', 'gönül işlerinde'] } },
};

export const COFFEE_TURKISH_CONTEXT_WORDING: Readonly<Record<Binding, CoffeeTurkishSurfaceRow>> = {
  user_decision: {
    meaning: 'the decision the user said they face (never its options or the right answer)',
    tier: 'narrow',
    forms: { lead: ['önündeki karar', 'vermen gereken karar'], modifier: ['önündeki karar konusunda', 'vermen gereken kararda', 'karar meselende'] },
    avoid: ['doğru karar', 'yanlış karar'],
  },
  current_relationship: {
    meaning: 'the relationship the user declared (never the partner\'s feelings or acts)',
    tier: 'narrow',
    forms: { lead: ['ilişkin', 'aranızdaki bağ'], modifier: ['ilişkinde', 'ilişkin tarafında', 'ilişkinle ilgili'] },
    avoid: ['partnerin', 'sevgilin seni'],
  },
  chosen_person: {
    meaning: 'the person the user has in mind (Contract B)',
    tier: 'narrow',
    forms: { lead: ['aklındaki kişi', 'o kişi'], modifier: ['aklındaki kişiyle ilgili', 'aklındaki kişi konusunda', 'o kişiyle ilgili'] },
    avoid: ['seni düşünüyor', 'seni özlüyor', 'geri dönecek'],
  },
  awaited_topic: {
    meaning: 'the matter the user says they are waiting on',
    tier: 'narrow',
    forms: { lead: ['beklediğin konu', 'beklediğin mesele'], modifier: ['beklediğin konuda', 'beklediğin meselede', 'beklediğin konuyla ilgili'] },
    avoid: ['cevap gelecek', 'olumlu dönüş'],
  },
};

export const COFFEE_TURKISH_HORIZON_WORDING: Readonly<Record<Horizon, CoffeeTurkishSurfaceRow>> = {
  nearer_term: { meaning: 'the nearer term', tier: 'narrow', forms: { modifier: ['yakın zamanda', 'yakında', 'çok geçmeden', 'kısa süre içinde'] } },
  coming_period: { meaning: 'the coming period', tier: 'narrow', forms: { modifier: ['önümüzdeki dönemde', 'önündeki günlerde', 'bundan sonraki zamanda', 'yaklaşan dönemde'] } },
  further_out: { meaning: 'somewhat further out', tier: 'narrow', forms: { modifier: ['biraz daha ileride', 'daha ileride', 'ilerleyen zamanlarda', 'biraz daha uzak bir zamanda'] } },
};

// ---------------------------------------------------------------------------
// Public surface overlap (dark lexical data; never changes M2 classes)
// ---------------------------------------------------------------------------

export type CoffeeTurkishSurfaceOverlap = {
  /** Two DISTINCT M2 classes that tend to sound alike in Turkish (sorted, unique). */
  classes: readonly [string, string];
  guidance: string;
  /** Wording that keeps each class on its own, non-overlapping facet when both appear. */
  distinct: Readonly<Record<string, readonly string[]>>;
};

export const COFFEE_TURKISH_SURFACE_OVERLAPS: readonly CoffeeTurkishSurfaceOverlap[] = [
  {
    classes: ['COMMITMENT', 'DURABLE'],
    guidance: 'Both easily become "kalıcı / sağlam bağ". Say lasting/serious for COMMITMENT once; give DURABLE only its wholeness facet, never "kalıcı" or "sağlam" again.',
    distinct: {
      COMMITMENT: ['kalıcı bir bağ', 'ciddi bir bağ', 'uzun soluklu bir bağ'],
      DURABLE: ['kopukluk olmadan bütün', 'bölünmeden duran', 'bütün'],
    },
  },
  {
    classes: ['LEANING', 'SINGULAR'],
    guidance: 'Both easily become "bir yere yönelmek". Give SINGULAR only its focus facet (one place, not scattered); give LEANING only its inclination facet (tilting to one side).',
    distinct: {
      SINGULAR: ['dağılmadan tek bir yerde toplanan', 'tek bir noktada toplanan'],
      LEANING: ['bir yana meylediyor', 'bir tarafa doğru eğiliyor'],
    },
  },
];

// ---------------------------------------------------------------------------
// Enriched writer payload
// ---------------------------------------------------------------------------

/** A row's wording by role, plus that row's own avoid list (kept per row: avoid lists may conflict across rows). */
type Forms = Partial<Record<CoffeeTurkishSurfaceRole | 'avoid', string[]>>;

export type CoffeeM2TurkishWriterPayload = CoffeeM2WriterPayload & {
  wording: {
    classes: Record<string, Forms>;
    tokens: Record<string, Forms>;
    relations: Record<string, Forms>;
    scenarios: Record<string, Forms>;
    scenarioClusters: Array<{ manifestations: string[] } & CoffeeTurkishScenarioClusterMode>;
    domains: Record<string, string[]>;
    contexts: Record<string, Forms>;
    horizons: Record<string, string[]>;
    overlaps: Array<{ classes: string[]; guidance: string; distinct: Record<string, string[]> }>;
    avoid: string[];
  };
};

const copyForms = (row: CoffeeTurkishSurfaceRow): Forms => ({
  ...(Object.fromEntries(Object.entries(row.forms).map(([role, list]) => [role, [...(list ?? [])]])) as Forms),
  ...(row.avoid ? { avoid: [...row.avoid] } : {}),
});

/**
 * W2 writer payload + ONLY the wording rows its beats actually use. Never the
 * whole bank, the W2 audit, raw user text or private evidence. No phrase is
 * selected here: the writer keeps controlled freedom among equivalents.
 */
export function toCoffeeM2TurkishWriterPayload(plan: CoffeeM2WriterPlan): CoffeeM2TurkishWriterPayload {
  const base = toCoffeeM2WriterPayload(plan); // refuses an insufficient plan, runs the guard
  const wording: CoffeeM2TurkishWriterPayload['wording'] = {
    classes: {}, tokens: {}, relations: {}, scenarios: {}, scenarioClusters: [], domains: {}, contexts: {}, horizons: {}, overlaps: [], avoid: [],
  };

  for (const beat of base.beats) {
    for (const group of beat.groups) {
      for (const cls of [group.cls, group.about]) {
        const row = cls ? COFFEE_TURKISH_CLASS_WORDING[cls] : undefined;
        if (cls && row && !wording.classes[cls]) {
          wording.classes[cls] = copyForms(row);
        }
      }
      for (const token of group.tokens) {
        const row = COFFEE_TURKISH_TOKEN_WORDING[token];
        if (row && !wording.tokens[token]) {
          wording.tokens[token] = copyForms(row);
        }
      }
      if (group.horizon && group.horizon !== 'unspecified' && !wording.horizons[group.horizon]) {
        wording.horizons[group.horizon] = [...(COFFEE_TURKISH_HORIZON_WORDING[group.horizon].forms.modifier ?? [])];
      }
    }
    if (beat.relation) {
      const row = COFFEE_TURKISH_RELATION_WORDING[beat.relation.combination];
      if (row && !wording.relations[beat.relation.combination]) {
        wording.relations[beat.relation.combination] = copyForms(row);
      }
    }
    if (beat.scenario) {
      for (const m of beat.scenario.manifestations) {
        const row = COFFEE_TURKISH_SCENARIO_WORDING[m];
        if (row && !wording.scenarios[m]) {
          wording.scenarios[m] = copyForms(row);
        }
      }
      const cluster = COFFEE_TURKISH_SCENARIO_CLUSTERS[beat.scenario.manifestations.join('|')]
        ?? { mode: 'alternatives', choose: { min: 1, max: Math.min(2, beat.scenario.manifestations.length) } };
      wording.scenarioClusters.push({ manifestations: [...beat.scenario.manifestations], mode: cluster.mode, choose: { ...cluster.choose } });
    }
    const domain = beat.qualifiers.domain?.domain;
    if (domain && !wording.domains[domain]) wording.domains[domain] = [...(COFFEE_TURKISH_DOMAIN_WORDING[domain].forms.modifier ?? [])];
    for (const { binding } of beat.qualifiers.context) {
      if (!wording.contexts[binding]) {
        wording.contexts[binding] = copyForms(COFFEE_TURKISH_CONTEXT_WORDING[binding]);
      }
    }
  }

  const present = new Set(Object.keys(wording.classes));
  for (const overlap of COFFEE_TURKISH_SURFACE_OVERLAPS) {
    if (overlap.classes.every((c) => present.has(c))) {
      wording.overlaps.push({
        classes: [...overlap.classes],
        guidance: overlap.guidance,
        distinct: Object.fromEntries(Object.entries(overlap.distinct).map(([k, v]) => [k, [...v]])),
      });
    }
  }
  wording.avoid = [...COFFEE_TURKISH_GLOBAL_AVOID];

  const payload: CoffeeM2TurkishWriterPayload = { ...base, wording };
  assertCoffeeV3MeaningOnly(payload);
  return payload;
}
