import { trGood, trNarrative } from './dream-phase2-fixtures.js';
import { golden } from './dream-phase4b-support.js';
import { bad, base, good, type CorpusBase, type CorpusCase } from './dream-phase4b-corpus-types.js';

const fromGolden = (id: string): CorpusBase => {
  const g = golden(id);
  return base(g.language, g.narrative, g.data, g.memorySummary ? { memorySummary: g.memorySummary } : {});
};

const bridge = fromGolden('tr-rich-negated-fear');
const door = fromGolden('tr-sparse-door');
const desk = fromGolden('tr-work-supported-memory');
const snake = base('tr', trNarrative, trGood, { symbols: ['yilan'] });
const cellar = base('tr', 'Rüyamda karanlık bir bodrumda merdivenden iniyordum, aşağıda bir saat tıkırdıyordu ve çok korktum.', {
  summary: 'Rüya, karanlık bir bodruma inen adımlarda büyüyen bir korkuyu taşıyor.',
  symbols: ['bodrum', 'merdiven', 'saat'],
  emotionalTheme: 'Korku, merdivenden aşağı indikçe ve saat tıkırdadıkça artıyor.',
  interpretation:
    'Karanlık bodruma merdivenden inmek, görünmeyen bir alana adım adım yaklaşmayı düşündürüyor; aşağıdaki saatin tıkırtısı ise bu inişe bir ritim veriyor ve korkunun zamanla birlikte büyüdüğünü hissettiriyor olabilir.',
  dailyLifeReflection: 'Bugün aşağıda tıkırdayan o saat gibi sessizce süren bir şeyi fark etmek iyi gelebilir.',
  conclusion: 'Merdivenin dibine vardığında saatin yanında ne bulmayı umardın?',
});
const station = base('tr', 'Rüyamda sevgilimle eski bir tren istasyonunda bekliyorduk ama tren bir türlü gelmedi. Peronda soğuk bir rüzgar vardı ve üzgündüm.', {
  summary: 'Rüya, gelmeyen bir treni beklerken soğuk bir peronda biriken sessiz bir üzüntüyü taşıyor.',
  symbols: ['tren', 'istasyon', 'peron'],
  emotionalTheme: 'Üzüntü, trenin gecikmesi ve peronda esen soğuk rüzgarla derinleşiyor.',
  interpretation:
    'Sevgilinle birlikte beklemek paylaşılan bir yolculuğu düşündürüyor; ama gelmeyen tren ve peronda esen soğuk rüzgar, bu bekleyişin hem ortak hem de biraz yalnız hissettirebileceğini gösteriyor olabilir.',
  dailyLifeReflection: 'Bugün beklediğin bir trenin gelmesini zorlamadan, peronda biraz durmak iyi gelebilir.',
  conclusion: 'O peronda sevgilinle beklerken en çok neyin gelmesini umuyordun?',
});

export const trCorpus: CorpusCase[] = [
  good('tr-g-bridge', bridge),
  good('tr-g-door-sparse-one-anchor', door),
  good('tr-g-work-present-memory', desk),
  good('tr-g-snake', snake),
  good('tr-g-stated-fear', cellar),
  good('tr-g-partner-present', station),
  good('tr-g-fear-absent-theme', bridge, { emotionalTheme: 'Korku yok; köprünün üstünde yalnızca merak var.' }),
  good('tr-g-behind-door', door, { conclusion: 'Kapının ardında ne vardı?' }),
  good('tr-g-summary-reuses-door', door, { summary: 'Kapalı kapı rüyada sessiz, sabırlı bir bekleyiş gibi duruyor.' }),
  good('tr-g-work-address-supported', desk, { dailyLifeReflection: 'Bugün işindeki masanın üstünde biriken küçük bir kumu acele etmeden toparlamak iyi gelebilir.' }),
  good('tr-g-memory-reflection', desk, { dailyLifeReflection: 'Yakın okumada anılan düzen ihtiyacı bugün küçük bir adımla karşılanabilir.' }),
  good('tr-g-hangi-question', bridge, { conclusion: 'Köprünün ortasında durunca hangi kıyıya bakmak isterdin?' }),
  good('tr-g-observed-emotion', door, { emotionalTheme: 'Kapalı kapının önünde sakin bir merak, acelesiz bir bekleyiş.' }, { emotions: ['merak'] }),
  good('tr-g-nasil-question', snake, { conclusion: 'Yilanin sessizce gitmesi sende nasıl bir his bıraktı?' }),
  good('tr-g-three-anchor-interp', bridge, {
    interpretation:
      'Köprü iki kıyıyı birbirine bağlarken altındaki bulanık nehir yolun kolay olmadığını hatırlatıyor; karşıdaki fenerin ışığı ise merakı canlı tutuyor olabilir.',
  }),
  good('tr-g-anxiety-stated', desk, { emotionalTheme: 'Tedirginlik, patronun içeri girdiği anda belirginleşiyor.' }),

  bad('tr-b-thin-theme', door, 'thin_section', { emotionalTheme: 'Sessiz bir ton.' }),
  bad('tr-b-question-summary', bridge, 'extra_question', { summary: 'Bulanık nehrin üstündeki köprü seni nereye götürüyor olabilir?' }),
  bad('tr-b-question-theme', door, 'extra_question', { emotionalTheme: 'Kapalı kapının önündeki bu bekleyiş gerçekten sakin mi?' }),
  bad('tr-b-question-interp', snake, 'extra_question', { interpretation: `${trGood.interpretation} Yilan neden sessizce gitti?` }),
  bad('tr-b-question-reflection', desk, 'extra_question', { dailyLifeReflection: 'Bugün masandaki kumu temizlerken neyi toparlamak istediğini fark edebilir misin?' }),
  bad('tr-b-symbol-dupe', bridge, 'symbol_list', { symbols: ['köprü', 'Köprü ', 'nehir'] }),
  bad('tr-b-symbol-many', bridge, 'symbol_list', {
    symbols: ['eski', 'köprünün', 'nehir', 'fener', 'kıyıda', 'bulanık', 'yürüyordum', 'merak', 'altından'],
  }),
  bad('tr-b-recap-bridge', bridge, 'plot_recap', { summary: 'Eski bir köprünün üzerinde yürüyordun, köprünün altından bulanık bir nehir akıyordu.' }),
  bad('tr-b-recap-snake', snake, 'plot_recap', { summary: 'Ruyanda uzun bir yilan evden gecti ve sessizce gitti.' }),
  bad('tr-b-fear-affirmed', bridge, 'emotion_contradiction', { emotionalTheme: 'Köprünün üstünde derin bir korku hakim.' }),
  bad('tr-b-fear-denied', cellar, 'emotion_contradiction', { emotionalTheme: 'Bodrumda korku yok, yalnızca sakin bir iniş var.' }),
  bad('tr-b-anxiety-denied', desk, 'emotion_contradiction', { emotionalTheme: 'Hiç tedirgin değil; masadaki kum rahatça temizleniyor.' }),
  bad('tr-b-sadness-denied', station, 'emotion_contradiction', { emotionalTheme: 'Üzüntü yok; istasyondaki bekleyiş hafif ve neşeli.' }),
  bad('tr-b-invented-red', door, 'invented_image', { interpretation: `Kırmızı ${door.data.interpretation.charAt(0).toLowerCase()}${door.data.interpretation.slice(1)}` }),
  bad('tr-b-invented-rain', bridge, 'invented_image', { dailyLifeReflection: 'Bugün yağmur altında köprüden geçer gibi yavaşça yürümek iyi gelebilir.' }),
  bad('tr-b-ungrounded-theme', door, 'ungrounded_section', { emotionalTheme: 'Genel bir değişim ve yeni başlangıç enerjisi hissediliyor.' }),
  bad('tr-b-ungrounded-summary', station, 'ungrounded_section', { summary: 'Dönüşüm, bitişler ve yeni başlangıçlar üzerine sakin bir anlatı.' }),
  bad('tr-b-shallow-bridge', bridge, 'weak_interpretation', { interpretation: 'Fener, yol gösteren bir ışık olarak umudu ve yönü simgeliyor olabilir; bu ışık seni kendi yoluna çağırıyor.' }),
  bad('tr-b-shallow-desk', desk, 'weak_interpretation', { interpretation: 'Patronun içeri girmesi, dışarıdan bakan bir gözü temsil ediyor olabilir; görülme hissini anlatan bir an gibi duruyor.' }),
  bad('tr-b-shallow-cellar', cellar, 'weak_interpretation', { interpretation: 'Saat, geçen zamanı hatırlatan bir işaret gibi; tıkırtısı bir şeyin yaklaştığını anlatıyor olabilir.' }),
  bad('tr-b-wellness-only', door, 'generic_reflection', { dailyLifeReflection: 'Bugün kendine güven ve sezgilerini dinle, her şey yoluna girecek.' }),
  bad('tr-b-wellness-anchored', bridge, 'generic_reflection', { dailyLifeReflection: 'Köprüden geçerken kendine güven ve kalbinin sesini dinle.' }),
  bad('tr-b-generic-rest', station, 'generic_reflection', { dailyLifeReflection: 'Bugün kendine zaman ayır ve derin bir nefes almayı unutma.' }),
  bad('tr-b-family-invented', bridge, 'unsupported_personal_fact', { dailyLifeReflection: 'Bugün ailenle ilgili bekleyen bir konuya da köprüdeki bu merakla bakabilirsin.' }),
  bad('tr-b-career-invented', door, 'unsupported_personal_fact', { interpretation: `${door.data.interpretation} Bu kapı kariyerinde açılmayı bekleyen bir fırsatı da anlatıyor olabilir.` }),
  bad('tr-b-money-invented', snake, 'unsupported_personal_fact', { dailyLifeReflection: 'Bugün paranla ilgili sessizce uzaklasan bir seyi fark etmek iyi gelebilir.' }),
  bad('tr-b-school-invented', station, 'unsupported_personal_fact', { dailyLifeReflection: 'Bugün okulundaki bir bekleyişi peronda durur gibi zorlamadan izlemek iyi gelebilir.' }),
  bad('tr-b-health-invented', cellar, 'unsupported_personal_fact', { interpretation: `${cellar.data.interpretation} Bu bodrum sağlığınla ilgili bir endişeyi de taşıyor olabilir.` }),
  bad('tr-b-childhood-invented', door, 'unsupported_personal_fact', { dailyLifeReflection: 'Bugün kapalı kapı gibi çocukluğundaki bir anıya zorlamadan bakmak iyi gelebilir.' }),
  bad('tr-b-yes-no-hazir', door, 'weak_conclusion', { conclusion: 'O kapıyı açmaya artık hazır mısın?' }),
  bad('tr-b-yes-no-gececek', bridge, 'weak_conclusion', { conclusion: 'Köprüden karşı kıyıya geçecek misin?' }),
  bad('tr-b-ungrounded-question', station, 'weak_conclusion', { conclusion: 'Hayatında gerçekten ne istiyorsun şu anda?' }),
  bad('tr-b-two-questions', snake, 'conclusion_not_question', { conclusion: 'Yilan evden neden gecti? Sen ne hissettin?' }),
];
