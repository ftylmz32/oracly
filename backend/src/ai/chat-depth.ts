const DEPTHS = ['short', 'balanced', 'deep'] as const;

export type ChatDepth = (typeof DEPTHS)[number];

export function parseDepth(input: unknown): ChatDepth {
  if (typeof input !== 'string') return 'balanced';
  const value = input.trim().toLowerCase();
  if (value === 'kisa' || value === 'kısa') return 'short';
  if (value === 'derin') return 'deep';
  return DEPTHS.includes(value as ChatDepth) ? (value as ChatDepth) : 'balanced';
}

export function parseSpoken(input: unknown): boolean {
  return input === true || input === 'true';
}

export function depthLine(
  depth: ChatDepth,
  spoken: boolean,
  language: 'tr' | 'en' | 'ru',
): string {
  const max = spoken
    ? depth === 'short'
      ? 4
      : depth === 'balanced'
        ? 6
        : 8
    : depth === 'short'
      ? 4
      : depth === 'balanced'
        ? 8
        : 16;
  const range =
    depth === 'short' ? '1–4' : depth === 'balanced' ? '4–8' : '8–16';
  const useful =
    depth === 'deep'
      ? language === 'en'
        ? ` Use ${range} sentences when useful.`
        : language === 'ru'
          ? ` ${range} фраз — только если это нужно.`
          : ` Yararlıysa ${range} cümle.`
      : language === 'en'
        ? ` ${range} sentences is enough.`
        : language === 'ru'
          ? ` ${range} фраз достаточно.`
          : ` ${range} cümle yeter.`;
  const voice = spoken
    ? language === 'en'
      ? ` Spoken replies: at most ${max} sentences.`
      : language === 'ru'
        ? ` В голосе не больше ${max} фраз.`
        : ` Sesli yanıtta en fazla ${max} cümle.`
    : '';
  const neverPad =
    language === 'en'
      ? ' If a shorter reply is enough, stay short. Never pad. Do not change personality.'
      : language === 'ru'
        ? ' Если хватает короче — оставь короче. Не раздувай. Характер не меняй.'
        : ' Daha kısa yeterse kısa bırak. Doldurma yok. Kişiliği değiştirme.';
  const label =
    language === 'en'
      ? `Length preference: ${depth}.`
      : language === 'ru'
        ? `Длина: ${depth}.`
        : `Uzunluk tercihi: ${depth}.`;
  return `${label}${useful}${neverPad}${voice}`;
}
