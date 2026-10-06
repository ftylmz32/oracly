import type { AppLanguage } from '../app-language.js';
import type {
  CoffeeObservation,
  ReadingEvidenceItem,
  ReadingPersonalization,
} from './types.js';

export type CoffeeMeaningFamily =
  | 'communication'
  | 'movement'
  | 'opportunity'
  | 'emotional_relevance'
  | 'bond'
  | 'solution'
  | 'growth'
  | 'social_relevance'
  | 'home_close_circle'
  | 'choice';

export type CoffeeMeaningFacet = {
  family: CoffeeMeaningFamily;
  implication: string;
  evidenceIds: string[];
  context?: 'home_close_circle';
  timing?: 'nearer_term';
};

export type CoffeeWriterPacket = {
  locale: AppLanguage;
  facets: CoffeeMeaningFacet[];
  personalization?: ReadingPersonalization;
};

const IMPLICATIONS: Record<AppLanguage, Record<CoffeeMeaningFamily, string>> = {
  tr: {
    communication: 'haber, mesaj veya iletişim gelişmesi',
    movement: 'ilerleyen bir süreç, yön değişimi veya yeni bir açılım',
    opportunity: 'fırsat, kazanç veya kısmet',
    emotional_relevance: 'duygusal hayatı veya yakın bir bağı ilgilendiren gelişme',
    bond: 'bağ, anlaşma veya bağlılık',
    solution: 'çözüm, erişim veya açılan bir imkân',
    growth: 'büyüme, köklenme veya aileyle ilgili gelişim',
    social_relevance: 'başka bir kişi veya sosyal çevreyle bağlantı',
    home_close_circle: 'ev veya yakın çevre bağlamı',
    choice: 'iki alternatif arasında seçim',
  },
  en: {
    communication: 'news, a message, or a communication development',
    movement: 'progress, a change of course, or a new opening',
    opportunity: 'an opportunity, gain, or good fortune',
    emotional_relevance: 'a development involving emotions or a close bond',
    bond: 'a bond, agreement, or commitment',
    solution: 'a solution, access, or an opening',
    growth: 'growth, roots, or family-related development',
    social_relevance: 'a connection involving another person or the social circle',
    home_close_circle: 'home or close-circle context',
    choice: 'a choice between alternatives',
  },
  ru: {
    communication: 'новость, сообщение или развитие общения',
    movement: 'продвижение, смена курса или новое направление',
    opportunity: 'возможность, выгода или удача',
    emotional_relevance: 'развитие в чувствах или близкой связи',
    bond: 'связь, соглашение или обязательство',
    solution: 'решение, доступ или новая возможность',
    growth: 'рост, укрепление корней или семейное развитие',
    social_relevance: 'связь с другим человеком или окружением',
    home_close_circle: 'контекст дома или близкого круга',
    choice: 'выбор между альтернативами',
  },
};

function fold(value: string): string {
  return value
    .normalize('NFC')
    .toLocaleLowerCase('tr-TR')
    .replace(/ı/g, 'i')
    .replace(/ğ/g, 'g')
    .replace(/ü/g, 'u')
    .replace(/ş/g, 's')
    .replace(/ö/g, 'o')
    .replace(/ç/g, 'c');
}

function meaningFamily(item: ReadingEvidenceItem): CoffeeMeaningFamily | null {
  const resemblance = fold(item.resemblance?.trim() ?? '');
  const description = fold(item.description);
  if (/diverg|fork|crossroad|ikiye ayr|yol ayr/.test(`${resemblance} ${description}`)) return 'choice';
  if (/bird|kus|letter|mektup|message|mesaj|zarf/.test(resemblance)) return 'communication';
  if (/fish|balik/.test(resemblance)) return 'opportunity';
  if (/ring|yuzuk/.test(resemblance)) return 'bond';
  if (/heart|kalp/.test(resemblance)) return 'emotional_relevance';
  if (/key|anahtar/.test(resemblance)) return 'solution';
  if (/road|path|route|yol|patika/.test(resemblance)) return 'movement';
  if (/tree|agac/.test(resemblance)) return 'growth';
  if (/person|figure|face|insan|kisi|sil[üu]et|yuz/.test(resemblance)) return 'social_relevance';
  return null;
}

function regionContext(item: ReadingEvidenceItem): {
  context?: CoffeeMeaningFacet['context'];
  timing?: CoffeeMeaningFacet['timing'];
} {
  const region = fold(item.region.replace(/_/g, ' '));
  return {
    ...(/handle|kulp/.test(region) ? { context: 'home_close_circle' as const } : {}),
    ...(/rim|upper|agiz|ust/.test(region) ? { timing: 'nearer_term' as const } : {}),
  };
}

export function mapCoffeeMeanings(
  obs: CoffeeObservation,
  language: AppLanguage,
): CoffeeMeaningFacet[] {
  const facets: CoffeeMeaningFacet[] = [];
  for (const item of obs.evidence) {
    if (item.confidence === 'low' || item.visibility === 'uncertain') continue;
    const family = meaningFamily(item);
    const region = regionContext(item);
    if (family) {
      facets.push({
        family,
        implication: IMPLICATIONS[language][family],
        evidenceIds: [item.id],
        ...region,
      });
    } else if (region.context) {
      facets.push({
        family: 'home_close_circle',
        implication: IMPLICATIONS[language].home_close_circle,
        evidenceIds: [item.id],
        context: region.context,
      });
    }
  }
  return facets;
}

export function buildCoffeeWriterPacket(
  obs: CoffeeObservation,
  language: AppLanguage,
  personalization?: ReadingPersonalization,
): CoffeeWriterPacket {
  return {
    locale: language,
    facets: mapCoffeeMeanings(obs, language),
    ...(personalization ? { personalization } : {}),
  };
}
