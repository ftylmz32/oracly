/** Deterministic Soulmate text gate. One named reason, never a live call. */
export type SoulmateSections = {
  personality: string;
  dynamic: string;
  attraction: string;
  challenge: string;
  meeting: string;
  feeling: string;
};

export type SoulmateGateReason =
  | 'too_short'
  | 'generic_cliche'
  | 'repetitive'
  | 'deterministic'
  | 'fake_memory'
  | 'contradiction'
  | 'raw_schema'
  | 'restating_inputs'
  | 'adjective_list';

export type SoulmateGateContext = {
  name?: string;
  presence?: string;
  mood?: string;
};

const CLICHE = [
  'ruh esin kesinlikle',
  'ruh esin seni bekliyor',
  'yildizlar seni',
  'evrenin plani',
  'sonsuz ask',
  'ikiz alev',
  'kalbinin ritmi',
  'meant to be',
  'twin flame',
  'the universe has planned',
];

const CERTAIN = [
  'kesinlikle',
  'su tarihte',
  'karsilasacaksin',
  'bu kisi kesin',
  'you will definitely meet',
  'you will meet on',
];

const MEMORY = [
  'hatirliyorum',
  'gecen yil',
  'eski sevgilin',
  'daha once seninle',
  'eski iliskin',
  'i remember when you',
  'your previous relationship',
];

function fold(value: string): string {
  return value
    .toLowerCase()
    .replace(/\u015f/g, 's')
    .replace(/\u015e/g, 's')
    .replace(/\u0131/g, 'i')
    .replace(/\u0130/g, 'i')
    .replace(/\u011f/g, 'g')
    .replace(/\u011e/g, 'g')
    .replace(/\u00fc/g, 'u')
    .replace(/\u00dc/g, 'u')
    .replace(/\u00f6/g, 'o')
    .replace(/\u00d6/g, 'o')
    .replace(/\u00e7/g, 'c')
    .replace(/\u00c7/g, 'c');
}

export function assessSoulmateInterpretation(
  sections: SoulmateSections,
  context: SoulmateGateContext = {},
): SoulmateGateReason | null {
  const values = Object.values(sections);
  const joined = fold(values.join('\n'));
  if (values.some((v) => v.trim().length < 48) || joined.length < 320) {
    return 'too_short';
  }
  if (CLICHE.some((p) => joined.includes(p))) return 'generic_cliche';
  if (CERTAIN.some((p) => joined.includes(p))) return 'deterministic';
  if (/\b\d{1,2}[.\/]\d{1,2}([.\/]\d{2,4})?\b/.test(joined)) {
    return 'deterministic';
  }
  if (MEMORY.some((p) => joined.includes(p))) return 'fake_memory';
  if (/[{}[\]]|soulmate_|imagebase64|provider_error/.test(joined)) {
    return 'raw_schema';
  }
  if (startsRepeat(values) || buKisiStarts(values)) return 'repetitive';
  if (values.filter(isAdjectiveList).length >= 2) return 'adjective_list';
  if (restates(values, context.name)) return 'restating_inputs';
  if (contradicts(joined, context.presence)) return 'contradiction';
  return null;
}

function startsRepeat(values: string[]): boolean {
  const starts = values.map((v) =>
    fold(v).trim().split(/\s+/).slice(0, 3).join(' '),
  );
  return starts.some(
    (s) => s.length > 0 && starts.filter((x) => x === s).length >= 3,
  );
}

function buKisiStarts(values: string[]): boolean {
  const n = values.filter((v) =>
    /^(bu kisi|this person)\b/.test(fold(v).trim()),
  ).length;
  return n >= 3;
}

function isAdjectiveList(value: string): boolean {
  const commas = (value.match(/,/g) ?? []).length;
  return (
    commas >= 3 && !/\b(olabilir|hissed|durabilir|might|feel)\b/.test(fold(value))
  );
}

function restates(values: string[], name?: string): boolean {
  const who = fold(name ?? '').trim();
  if (who.length < 2) return false;
  const hits = values.filter((v) => {
    const t = fold(v);
    const count = t.split(who).length - 1;
    return count >= 2 && v.trim().length < 90;
  }).length;
  return hits >= 3;
}

function contradicts(joined: string, presence?: string): boolean {
  if (!presence) return false;
  if (
    presence.startsWith('masculine') &&
    /\b(kadinsi|she is a woman|feminine-presenting)\b/.test(joined)
  ) {
    return true;
  }
  if (
    presence.startsWith('feminine') &&
    /\b(erkeksi|he is a man|masculine-presenting)\b/.test(joined)
  ) {
    return true;
  }
  return false;
}
