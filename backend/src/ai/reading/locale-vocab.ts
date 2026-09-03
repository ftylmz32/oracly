/** Locale-safe region vocabulary for the production writer handoff. */

import type { AppLanguage } from '../app-language.js';
import type { CoffeeObservation, PalmObservation, ReadingEvidenceItem } from './types.js';

const COFFEE_REGION_TR: Record<string, string> = {
  rim: 'fincanın ağız kenarı',
  upper_wall: 'üst iç yüzey',
  'upper wall': 'üst iç yüzey',
  middle_wall: 'orta iç yüzey',
  mid_wall: 'orta iç yüzey',
  'mid wall': 'orta iç yüzey',
  'middle wall': 'orta iç yüzey',
  lower_wall: 'alt iç yüzey',
  'lower wall': 'alt iç yüzey',
  base: 'fincanın dibi',
  'base edge': 'dibin kenarı',
  handle_side: 'kulp tarafı',
  'handle side': 'kulp tarafı',
  cup_interior: 'fincanın içi',
};

const COFFEE_REGION_EN: Record<string, string> = {
  rim: 'cup rim',
  upper_wall: 'upper inner wall',
  middle_wall: 'middle inner wall',
  mid_wall: 'middle inner wall',
  lower_wall: 'lower inner wall',
  base: 'cup base',
  'base edge': 'base edge',
  handle_side: 'handle side',
  cup_interior: 'cup interior',
};

const COFFEE_REGION_RU: Record<string, string> = {
  rim: 'край чашки',
  upper_wall: 'верхняя внутренняя стенка',
  middle_wall: 'средняя внутренняя стенка',
  mid_wall: 'средняя внутренняя стенка',
  lower_wall: 'нижняя внутренняя стенка',
  base: 'дно чашки',
  'base edge': 'край дна',
  handle_side: 'сторона ручки',
  cup_interior: 'внутренность чашки',
};

export function coffeeRegionLabel(region: string, language: AppLanguage): string {
  const key = region.trim().toLowerCase();
  const table =
    language === 'ru'
      ? COFFEE_REGION_RU
      : language === 'en'
        ? COFFEE_REGION_EN
        : COFFEE_REGION_TR;
  if (table[key]) return table[key];
  // Fuzzy partials for free-form observer regions.
  if (language === 'tr') {
    if (/\brim\b/.test(key)) return 'fincanın ağız kenarı';
    if (/upper/.test(key) && /wall|iç|ic/.test(key)) return 'üst iç yüzey';
    if (/(mid|middle)/.test(key) && /wall|iç|ic/.test(key)) return 'orta iç yüzey';
    if (/lower/.test(key) && /wall|iç|ic/.test(key)) return 'alt iç yüzey';
    if (/\bbase\b/.test(key)) return 'fincanın dibi';
    if (/handle/.test(key)) return 'kulp tarafı';
  }
  return region;
}

export type WriterEvidencePacket = {
  locale: AppLanguage;
  handPolicy: {
    trustedSide: 'left' | 'right' | null;
    rule: string;
  };
  regionVocabulary: Record<string, string>;
  evidence: Array<
    ReadingEvidenceItem & { regionLabel: string }
  >;
  usable: boolean;
  checks: Record<string, boolean>;
};

export function buildCoffeeWriterPacket(
  obs: CoffeeObservation,
  language: AppLanguage,
): WriterEvidencePacket {
  const vocab: Record<string, string> = {};
  const evidence = obs.evidence.map((e) => {
    const regionLabel = coffeeRegionLabel(e.region, language);
    vocab[e.region] = regionLabel;
    return { ...e, regionLabel };
  });
  return {
    locale: language,
    handPolicy: {
      trustedSide: null,
      rule: 'not_applicable_for_coffee',
    },
    regionVocabulary: vocab,
    evidence,
    usable: obs.usable,
    checks: obs.checks as unknown as Record<string, boolean>,
  };
}

export function buildPalmWriterPacket(
  obs: PalmObservation,
  language: AppLanguage,
  trustedSide: 'left' | 'right' | null,
): WriterEvidencePacket {
  const evidence = obs.evidence.map((e) => ({
    ...sanitizeHandednessInItem(e, trustedSide),
    regionLabel: e.region,
  }));
  return {
    locale: language,
    handPolicy: {
      trustedSide,
      rule: trustedSide
        ? 'trusted_user_metadata_may_name_side'
        : 'never_infer_left_or_right_from_pixels_or_mirroring; say one open palm only',
    },
    regionVocabulary: {},
    evidence,
    usable: obs.usable,
    checks: obs.checks as unknown as Record<string, boolean>,
  };
}

export function sanitizeHandednessInItem(
  item: ReadingEvidenceItem,
  trustedSide: 'left' | 'right' | null,
): ReadingEvidenceItem {
  if (trustedSide) return item;
  const scrub = (s: string) =>
    s
      .replace(/\bright\s+hand\b/gi, 'palm-facing hand')
      .replace(/\bleft\s+hand\b/gi, 'palm-facing hand')
      .replace(/\b(sağ|sag|sol)\s+(el|avuç|avuc)\b/gi, 'avuç içi')
      .replace(/\b(right|left)\s+palm\b/gi, 'open palm');
  return {
    ...item,
    description: scrub(item.description),
    region: scrub(item.region),
    resemblance: item.resemblance ? scrub(item.resemblance) : item.resemblance,
  };
}

export function normalizeTrustedHand(raw: unknown): 'left' | 'right' | null {
  if (typeof raw !== 'string') return null;
  const v = raw.trim().toLowerCase();
  if (v === 'left' || v === 'sol') return 'left';
  if (v === 'right' || v === 'sag' || v === 'sağ') return 'right';
  return null;
}
