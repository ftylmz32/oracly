/** Daily astrology writer prompts — calculated findings in, plain Turkish out. */
import type { OpenAiMessage } from '../types.js';
import type { AstrologyWireSky } from './astrology-daily-contract.js';
import {
  ASTROLOGY_DAILY_RESULT_VERSION,
  ASTROLOGY_DAILY_WORDS,
} from './astrology-daily-limits.js';

export function astrologyDailyMessages(sky: AstrologyWireSky): OpenAiMessage[] {
  return [
    { role: 'system', content: astrologyDailySystemRules().join('\n') },
    { role: 'user', content: userPrompt(sky) },
  ];
}

export function astrologyDailySystemRules(): string[] {
  const w = ASTROLOGY_DAILY_WORDS;
  return [
    'You are the ORACLY daily sky writer. You write today\'s personal astrology for one person, in contemporary Turkish they would read aloud, with correct diacritics.',
    'EVIDENCE. The app has already calculated this person\'s natal positions, today\'s planet signs, and one finding per lane (a real aspect between a moving planet and a natal point). Those are the only facts. Never calculate astronomy, never add an aspect, placement, sign or house that is not supplied, and never speak about a natal point that is not in the natal list.',
    'EACH LANE HAS ITS OWN GROUND. A lane with a finding is written from that finding. A lane without a finding is written briefly and modestly from its anchor signs, as an observation about the person, never borrowing another lane\'s finding. Never describe the reading\'s own structure: no "bu alan", "bu cephe", "uyarı alanı", "fırsat tarafı sessiz", "bulgu yok".',
    'LANES MUST DIFFER. overall, love, career and money each say something the others do not. Do not restate the overall point inside a lane, and do not reuse a sentence frame across lanes.',
    'HIDDEN TECHNIQUE. The calculation is the reason, not the subject. Lead with how the day feels or works for this person. Prefer no planet or sign names at all; at most one planet name in a lane, and none in portrait. Never build "Koç\'taki Güneş", "Aslan\'daki Mars", "doğuştan gelen …" or "natal …" phrases. Never write degrees, orbs, "kare açı", "üçgen açı", "karşıtlık", "kavuşum", "transit", house numbers, or element counts. Do not sound like a report.',
    'NO INVENTED LIFE. You do not know their job, partner, family, money situation or plans. Never state a private fact, an event that happened, or a conversation as real. A concrete picture is allowed only as a clear hypothetical that grows out of this lane\'s finding; do not reach for stock openers ("bir mesaj bekliyorsan" and the like) that would read the same for everyone.',
    'NO FIXED FUTURE. Never promise or predict an outcome ("bugün para gelecek", "biriyle tanışacaksın", "kesinlikle"). Describe tendencies in the present tense, as observations. Use at most three "-abilir/-ebilir" forms ("olabilir", "hissedebilirsin") in the whole reading; vary the grammar instead.',
    'NOT A COACH. No instructions, no homework, no motivational slogans, no chains of imperatives ("dene", "unutma", "kendine izin ver", "dikkat et", "harekete geç"). The whole reading may contain at most one soft suggestion. reflection is one quiet question, not advice.',
    'ADDRESSING. If addressName is supplied, use it exactly once in the whole reading, where a person sitting across the table would naturally say it (the start of overall works well). Never as a greeting formula ("Sevgili …"). Without addressName, speak as "sen" and never invent a name.',
    'THEMES. If themes are supplied, you may connect one lane lightly to one theme as something that has come up in their recent readings. Never claim more memory than that.',
    `LENGTH. portrait: one or two sentences about the temperament their natal positions describe, in lived language, without naming planets or signs. overall: ${w.overallMin}–${w.overallMax} words. love, career, money: ${w.laneMin}–${w.laneMax} words each. mood, drive, opportunity, caution: one to three sentences each. reflection: a single question ending with "?".`,
    'Keep safety discipline silent: never write that this is "not fate", "only symbolic", or "based on calculations". Return ONLY the JSON object required by the schema.',
  ];
}

const POINT_MEANING: Record<string, string> = {
  sun: 'kimlik, kendini ortaya koyma, canlılık',
  moon: 'duygusal ihtiyaçlar, iç ritim, güven duygusu',
  mercury: 'düşünme, konuşma, yazışma, karar verme biçimi',
  venus: 'sevgi dili, yakınlık, keyif, değer verdiği şeyler, para ile ilişkisi',
  mars: 'istek, harekete geçme, öfke, fiziksel enerji',
  jupiter: 'güven, büyüme, iyimserlik, fırsatlar',
  saturn: 'sorumluluk, sınırlar, yorgunluk, kalıcılık',
  ascendant: 'dışarıya verdiği ilk izlenim, beden dili',
  midheaven: 'iş hayatındaki yönü, görünürlük, statü',
};

const TONE_MEANING: Record<string, string> = {
  fusion: 'two energies merge; intense, focused, hard to ignore',
  flow: 'easy, supportive, things move without force',
  friction: 'tension, impatience, a pull between two needs',
};

const SPAN_MEANING: Record<string, string> = {
  hours: 'passes within the day',
  days: 'lasts a few days',
  week: 'lasts about a week',
  weeks: 'part of a longer, multi-week period',
};

const HOUSE_AREA: Record<number, string> = {
  1: 'self and appearance',
  2: 'money and resources',
  3: 'close circle, messages, short trips',
  4: 'home and family',
  5: 'pleasure, creativity, romance',
  6: 'daily work routine and health habits',
  7: 'partnerships and close relationships',
  8: 'shared money, debts, deep bonds',
  9: 'learning, travel, beliefs',
  10: 'career and public standing',
  11: 'friends, groups, future plans',
  12: 'rest, retreat, inner life',
};

/** Signs a lane without a finding may speak from (moving planet, natal point). */
const QUIET_ANCHORS: Record<string, [string, string]> = {
  overall: ['moon', 'sun'],
  love: ['venus', 'venus'],
  career: ['mercury', 'mercury'],
  money: ['jupiter', 'venus'],
  mood: ['moon', 'moon'],
  drive: ['mars', 'mars'],
  opportunity: ['jupiter', 'sun'],
  caution: ['saturn', 'sun'],
};

const LANES = [
  'overall',
  'love',
  'career',
  'money',
  'mood',
  'drive',
  'opportunity',
  'caution',
] as const;

function userPrompt(sky: AstrologyWireSky): string {
  const sign = (point: string, list: { point: string; sign: string }[]) =>
    list.find((p) => p.point === point)?.sign;
  const laneLines = LANES.map((lane) => {
    const f = sky.findings.find((x) => x.lane === lane);
    if (f) {
      const returning = f.transit === f.natal && f.aspect === 'conjunction'
        ? f.natal === 'sun'
          ? ' This is the solar return: the Sun is back at its birth position, so it is their birthday season — say so plainly.'
          : ' This planet is back at its own birth position (a return).'
        : '';
      return `- ${lane}: moving ${f.transit} (now in ${sign(f.transit, sky.transits)}) meets natal ${f.natal} (${POINT_MEANING[f.natal]}); tone ${f.tone} = ${TONE_MEANING[f.tone]}; ${f.strength}; ${SPAN_MEANING[f.span]}.${returning}`;
    }
    const [moving, natalPoint] = QUIET_ANCHORS[lane];
    const natalSign = sign(natalPoint, sky.natal) ?? sign('sun', sky.natal);
    return `- ${lane}: no finding today. Anchor: ${moving} is now in ${sign(moving, sky.transits)}; natal ${natalPoint} is in ${natalSign}.`;
  });
  const houses =
    sky.depth === 'full'
      ? sky.transits
          .filter((t) => t.natalHouse)
          .map((t) => `${t.point} → ${HOUSE_AREA[t.natalHouse!]}`)
          .join('; ')
      : '';
  return [
    'Calculated sky (authoritative):',
    JSON.stringify(sky),
    '',
    `Chart depth: ${sky.depth === 'full' ? 'full chart (birth time and city known).' : 'birth day only: no birth time, so no rising sign, MC or houses exist. Never mention them.'}`,
    houses ? `Life areas the moving planets cross today: ${houses}.` : '',
    'Lane grounds:',
    ...laneLines,
    sky.addressName
      ? `addressName: "${sky.addressName}". Follow the ADDRESSING rule.`
      : 'No addressName: do not use or invent a name.',
    sky.themes.length ? `Recent themes: ${sky.themes.join(', ')}.` : 'No themes.',
    '',
    `Return JSON matching contractVersion ${ASTROLOGY_DAILY_RESULT_VERSION}.`,
  ]
    .filter((l) => l !== '')
    .join('\n');
}
