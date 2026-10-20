import { describe, expect, it } from 'vitest';
import { acceptDreamData } from '../src/ai/dream-acceptance.js';
import { touchesTold } from '../src/ai/dream-client-parity.js';
import { isPlotRecap, isRichNarrative } from '../src/ai/dream-narrative-anchors.js';
import { evaluateDreamQuality } from '../src/ai/dream-quality.js';
import type { DreamData } from '../src/ai/parse-provider.js';

const grasshopper = 'Rüyamda çekirge gördüm';
const train =
  'Kalabalık bir tren istasyonunda eski bir arkadaşımı gördüm ama ona yetişemedim. Tren kapıları kapandı.';
const detailed =
  'Rüyamda eski evin bahçesindeydim. Gökyüzü açıktı. Önümde altın bir kapı belirdi ve hafif yağmur başladı. Kapıyı açınca içeride çocukluğumdan tanıdığım bir masa vardı ve üzerinde üç çekirge duruyordu. Korkmadım, sadece baktım.';

const seen: DreamData = {
  summary: 'Rüyanın odağında bir çekirge var.',
  symbols: ['çekirge'],
  emotionalTheme: 'Çekirge görüntüsü, doğadan bir canlıyla karşılaşma havası taşıyor; belirli bir duygu öne çıkmıyor.',
  interpretation:
    'Çekirge, bu sahnede yalnızca görülmesiyle öne çıkıyor. Bu görüntü, küçük bir canlının dikkat alanını doldurması üzerinden, kolayca gözden kaçabilecek bir şeyin fark edilir hâle gelmesi olarak okunabilir.',
  dailyLifeReflection: '',
  conclusion: 'Çekirgeyi düşündüğünde aklına gelen ilk çağrışım ne?',
};

function read(narrative: string, data: DreamData) {
  return acceptDreamData(data, { narrative, symbols: [], emotions: [], language: 'tr' });
}

describe('dream echo reading', () => {
  it('proves a restatement passed because a shared word was treated as a reading', () => {
    expect(touchesTold(seen.interpretation, grasshopper, [], 'tr')).toBe(true);
    expect(isPlotRecap(grasshopper, seen.summary)).toBe(false);
    expect(isRichNarrative(grasshopper)).toBe(false);
    expect(evaluateDreamQuality(seen, { narrative: grasshopper, symbols: [], emotions: [], language: 'tr' })).toBeNull();
  });

  it('rejects the accepted grasshopper restatement and the handback question', () => {
    expect(read(grasshopper, seen).failure).toBe('echo_reading');
  });

  it('rejects a train plot retold in other words', () => {
    const data: DreamData = {
      ...seen,
      summary: 'Eski bir arkadaşa tren istasyonunda yetişilemeyen bir an.',
      symbols: ['tren istasyonu', 'eski bir arkadaş'],
      emotionalTheme: 'Tren kapılarının kapandığı sahnede belirli bir duygu söylenmedi.',
      interpretation:
        'Kalabalık tren istasyonunda eski arkadaşını gördün ama ona yetişemedin. Tren kapıları kapandı.',
      conclusion: 'Tren kapıları kapanınca arkadaşın içeride kaldı.',
    };
    expect(read(train, data).failure).toBe('echo_reading');
  });

  it('rejects a detailed dream that only lists its objects again', () => {
    const data: DreamData = {
      ...seen,
      summary: 'Bahçede altın bir kapı, yağmur, bir masa ve üç çekirge var.',
      symbols: ['altın bir kapı', 'yağmur', 'masa'],
      emotionalTheme: 'Çekirgelere korkmadan bakılmış; korku yok.',
      interpretation:
        'Eski evin bahçesinde altın bir kapı belirdi, hafif yağmur başladı, çocukluğundan tanıdığın masa göründü ve üzerinde üç çekirge duruyordu.',
      conclusion: 'Masada üç çekirge duruyordu ve sen baktın.',
    };
    expect(read(detailed, data).failure).toBe('echo_reading');
  });

  it('keeps two different symbolic readings of the same grasshopper', () => {
    const movement: DreamData = {
      ...seen,
      emotionalTheme: 'Çekirge görüntüsünde telaş yok; belirli bir duygu söylenmedi.',
      interpretation:
        'Çekirge, yerinde uzun kalmayan ve ansızın yön değiştirebilen bir canlı olarak, kısa bir karşılaşmanın da tek bir çizgide bağlanmak zorunda olmadığını düşündürür. Sıçradığı anlatılmadığı için bu yalnızca bir olasılıktır.',
      conclusion: 'Çekirge burada sabit bir anlamdan çok, yönün değişebileceği bir olasılık bırakıyor.',
    };
    const guest: DreamData = {
      ...movement,
      interpretation:
        'Çekirge, beklenmedik bir anda beliren küçük bir konuk gibi, planlanmamış bir karşılaşmanın da ciddiye alınabileceğini düşündürür. Bu bir kehanet değil, imgenin çağrışımıdır.',
      conclusion: 'Çekirge, davetsiz de olsa fark edilen bir karşılaşmanın olasılığını taşıyor.',
    };
    expect(read(grasshopper, movement).failure).toBeNull();
    expect(read(grasshopper, guest).failure).toBeNull();
  });

  it('keeps a train interval and a relation between the familiar table and the insects', () => {
    const missed: DreamData = {
      ...seen,
      summary: 'Trende tanıdık birine doğru kapanan bir aralık.',
      symbols: ['tren istasyonu', 'eski bir arkadaş', 'tren kapıları'],
      emotionalTheme: 'Tren istasyonunda yetişememenin havası var; belirli bir duygu söylenmedi.',
      interpretation:
        'Yetişemeden kapanan tren aralığı, eski arkadaşın görünür kalırken temasın kurulamadığı bir mesafeyi düşündürür. Bu, uyanık hayatta bir şeyin kaçtığı anlamına gelmez; rüyada yaklaşmanın yarım kalmış bir olasılık olarak durur.',
      conclusion: 'Tren kapısının kapanması, temas kurulmadan kalan mesafeyi görünür kılıyor.',
    };
    const table: DreamData = {
      ...seen,
      summary: 'Tanıdık bir masanın üstünde yabancı duran üç çekirge.',
      symbols: ['altın bir kapı', 'masa', 'çekirge'],
      emotionalTheme: 'Masanın üstündeki çekirgelere korkmadan bakılmış.',
      interpretation:
        'Altın kapının ardındaki tanıdık masa, yabancı çekirgeleri bildiğin bir zemine oturtuyor. Korkmadan bakmak bu karşılaşmayı kaçışa çevirmiyor; hafif yağmur da sahneyi silmeden ona eşlik ediyor olabilir.',
      conclusion: 'Tanıdık masa, üstündeki çekirgeleri silmeden başka bir görünürlük kazandırıyor.',
    };
    expect(read(train, missed).failure).toBeNull();
    expect(read(detailed, table).failure).toBeNull();
  });

  it('still rejects a dictionary gloss and an invented waking-life domain', () => {
    const gloss: DreamData = {
      ...seen,
      interpretation:
        'Çekirge = haber. Yerinde uzun kalmayan bir canlı, kısa bir karşılaşmanın da tek bir çizgide bağlanmak zorunda olmadığını düşündürür.',
      conclusion: 'Çekirge burada bir olasılık bırakıyor.',
    };
    const career: DreamData = {
      ...seen,
      interpretation:
        'Çekirge, yerinde uzun kalmayan bir canlı olarak kısa bir karşılaşmanın yön değiştirebileceğini düşündürür. Bu görüntü kariyerinde açılmayı bekleyen bir fırsatı da anlatıyor olabilir.',
      conclusion: 'Çekirge burada yönün değişebileceği bir olasılık bırakıyor.',
    };
    expect(read(grasshopper, gloss).failure).toBe('dictionary_style');
    expect(read(grasshopper, career).failure).toBe('unsupported_personal_fact');
  });

  it('rejects a real reading whose close hands the meaning back', () => {
    const data: DreamData = {
      ...seen,
      interpretation:
        'Çekirge, yerinde uzun kalmayan bir canlı olarak, kısa bir karşılaşmanın da tek bir çizgide bağlanmak zorunda olmadığını düşündürür.',
      conclusion: 'Çekirgeyi düşündüğünde aklına gelen ilk çağrışım ne?',
    };
    expect(read(grasshopper, data).failure).toBe('handed_back');
  });
});
