import { ErrorCode, fail } from '../errors.js';
import { evaluateCoffeeQuality } from './human-quality.js';

export function extractChatText(raw: string): string {
  const text = raw.trim();
  if (!text) fail(ErrorCode.invalidResponse);
  return text;
}

export type DreamData = {
  summary: string;
  symbols: string[];
  emotionalTheme: string;
  interpretation: string;
  dailyLifeReflection: string;
  conclusion: string;
};

export function parseDreamData(raw: string): DreamData {
  const json = extractJson(raw);
  if (!json) fail(ErrorCode.invalidResponse);
  const summary = pickText(json, ['ozet', 'özet', 'summary']);
  const emotionalTheme = pickText(json, ['duygusalTema', 'emotionalTheme', 'duygu']);
  const interpretation = pickText(json, ['yorum', 'interpretation']);
  const dailyLifeReflection = pickText(json, [
    'gunlukYansi',
    'günlükYansıma',
    'dailyLifeReflection',
    'yansi',
  ]);
  const conclusion = pickText(json, ['sonuc', 'sonuç', 'conclusion']);
  if (
    !summary ||
    !emotionalTheme ||
    !interpretation ||
    !dailyLifeReflection ||
    !conclusion
  ) {
    fail(ErrorCode.invalidResponse);
  }
  return {
    summary,
    symbols: stringList(json.semboller ?? json.symbols),
    emotionalTheme,
    interpretation,
    dailyLifeReflection,
    conclusion,
  };
}

export type TarotData = {
  summary: string;
  love: string;
  career: string;
  money: string;
  health: string;
  spiritualGuidance: string;
  advice: string;
  warnings: string;
  luckyEnergy: string;
  dailyFocus: string;
  closingMessage: string;
  rawText: string;
};

export function parseTarotData(raw: string): TarotData {
  const json = extractJson(raw);
  if (!json) fail(ErrorCode.invalidResponse);
  const summary = pickText(json, ['summary', 'ozet', 'özet'], 8);
  const advice = pickText(json, ['advice', 'tavsiye', 'guidance'], 8);
  const closingMessage = pickText(
    json,
    ['closingMessage', 'closing', 'kapanis', 'kapanış'],
    8,
  );
  if (!summary || !advice || !closingMessage) fail(ErrorCode.invalidResponse);
  const result: TarotData = {
    summary,
    love: pickText(json, ['love', 'ask', 'aşk'], 1),
    career: pickText(json, ['career', 'kariyer', 'is', 'iş'], 1),
    money: pickText(json, ['money', 'para', 'finans'], 1),
    health: pickText(json, ['health', 'denge', 'wellbeing'], 1),
    spiritualGuidance: pickText(
      json,
      ['spiritualGuidance', 'reflection', 'yansima', 'yansıma'],
      1,
    ),
    advice,
    warnings: pickText(json, ['warnings', 'questions', 'sorular'], 1),
    luckyEnergy: pickText(json, ['luckyEnergy', 'story', 'hikaye', 'hikâye'], 1),
    dailyFocus: pickText(json, ['dailyFocus', 'focus', 'odak'], 1),
    closingMessage,
    rawText: '',
  };
  result.rawText = [
    result.summary,
    result.love,
    result.career,
    result.money,
    result.health,
    result.spiritualGuidance,
    result.advice,
    result.warnings,
    result.luckyEnergy,
    result.dailyFocus,
    result.closingMessage,
  ].filter(Boolean).join('\n\n');
  return result;
}

export type CoffeeSymbol = {
  name: string;
  meaning: string;
  interpretation: string;
  /** Optional normalized focus from the provider — never invented. */
  focus?: { x: number; y: number; w: number; h: number };
};

export type CoffeeData = {
  visualObservation: string;
  overall: string;
  love: string;
  career: string;
  money: string;
  nearFuture: string;
  takeaway: string;
  symbols: CoffeeSymbol[];
};

export function parseCoffeeData(raw: string): CoffeeData {
  const json = extractJson(raw);
  if (!json) fail(ErrorCode.invalidResponse);
  if (json.usable === false || json.okunabilir === false) {
    fail(ErrorCode.invalidImage);
  }
  const visualObservation = pickText(json, [
    'gorselTespit',
    'görselTespit',
    'visualObservation',
    'visual',
    'detectedVisual',
    'observation',
  ], 12);
  const overall = pickText(json, [
    'genelYorum',
    'overall',
    'genel',
    'genel_yorum',
    'general',
  ], 12);
  const takeaway = pickText(json, [
    'sonuc',
    'takeaway',
    'sonuç',
    'kapanis',
    'closing',
  ], 1);
  if (!visualObservation || !overall) fail(ErrorCode.invalidResponse);
  const data: CoffeeData = {
    visualObservation,
    overall,
    love: pickText(json, ['ask', 'aşk', 'love', 'iliski', 'ilişki'], 1),
    career: pickText(json, ['kariyer', 'career', 'is', 'iş', 'work'], 1),
    money: pickText(json, [
      'maddiDurum',
      'maddi',
      'money',
      'para',
      'finans',
    ], 1),
    nearFuture: pickText(json, [
      'yakinDonem',
      'yakınDönem',
      'yakinGelecek',
      'yakınGelecek',
      'nearFuture',
      'gelecek',
    ], 1),
    takeaway,
    symbols: parseSymbols(json.semboller ?? json.symbols),
  };
  const quality = evaluateCoffeeQuality(data);
  if (quality) fail(ErrorCode.invalidResponse);
  return data;
}

function extractJson(raw: string): Record<string, unknown> | null {
  const trimmed = raw.trim();
  try {
    const decoded = JSON.parse(trimmed) as unknown;
    if (decoded && typeof decoded === 'object' && !Array.isArray(decoded)) {
      return decoded as Record<string, unknown>;
    }
  } catch {
    /* try slice */
  }
  const start = trimmed.indexOf('{');
  const end = trimmed.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    const decoded = JSON.parse(trimmed.slice(start, end + 1)) as unknown;
    if (decoded && typeof decoded === 'object' && !Array.isArray(decoded)) {
      return decoded as Record<string, unknown>;
    }
  } catch {
    return null;
  }
  return null;
}

function pickText(
  json: Record<string, unknown>,
  keys: string[],
  min = 8,
): string {
  for (const key of keys) {
    const value = json[key];
    if (typeof value === 'string' && value.trim().length >= min) {
      return value.trim();
    }
  }
  return '';
}

function stringList(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((item): item is string => typeof item === 'string' && item.trim().length > 0)
    .map((item) => item.trim());
}

function parseSymbols(raw: unknown): CoffeeSymbol[] {
  if (!Array.isArray(raw)) return [];
  const out: CoffeeSymbol[] = [];
  for (const item of raw) {
    if (!item || typeof item !== 'object' || Array.isArray(item)) continue;
    const rec = item as Record<string, unknown>;
    const name = String(rec.name ?? rec.ad ?? '').trim();
    if (!name) continue;
    const focus = parseFocus(rec);
    out.push({
      name,
      meaning: String(rec.meaning ?? rec.anlam ?? '').trim(),
      interpretation: String(rec.interpretation ?? rec.yorum ?? '').trim(),
      ...(focus ? { focus } : {}),
    });
  }
  return out;
}

/** Pass through reliable spatial boxes only. Never invent coordinates. */
function parseFocus(
  rec: Record<string, unknown>,
): { x: number; y: number; w: number; h: number } | undefined {
  const raw = rec.focus ?? rec.bbox ?? rec.box ?? rec.region ?? rec.konum ?? rec.spatial;
  const box = coerceBox(raw);
  if (!box) return undefined;
  const { x, y, w, h } = box;
  if (w < 0.04 || h < 0.04 || w > 0.82 || h > 0.82) return undefined;
  if (x < -0.01 || y < -0.01 || x + w > 1.02 || y + h > 1.02) return undefined;
  return box;
}

function coerceBox(
  raw: unknown,
): { x: number; y: number; w: number; h: number } | undefined {
  if (Array.isArray(raw) && raw.length >= 4) {
    const nums = raw.slice(0, 4).map(asNum);
    if (nums.some((n) => n === undefined)) return undefined;
    return { x: nums[0]!, y: nums[1]!, w: nums[2]!, h: nums[3]! };
  }
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return undefined;
  const m = raw as Record<string, unknown>;
  if (m.left !== undefined || m.l !== undefined) {
    const l = asNum(m.left ?? m.l);
    const t = asNum(m.top ?? m.t);
    const r = asNum(m.right ?? m.r);
    const b = asNum(m.bottom ?? m.b);
    if ([l, t, r, b].some((n) => n === undefined)) return undefined;
    return { x: l!, y: t!, w: r! - l!, h: b! - t! };
  }
  const x = asNum(m.x ?? m.left);
  const y = asNum(m.y ?? m.top);
  const w = asNum(m.w ?? m.width);
  const h = asNum(m.h ?? m.height);
  if ([x, y, w, h].some((n) => n === undefined)) return undefined;
  return { x: x!, y: y!, w: w!, h: h! };
}

function asNum(raw: unknown): number | undefined {
  if (typeof raw === 'number' && Number.isFinite(raw)) return raw;
  if (typeof raw === 'string') {
    const n = Number(raw.trim());
    return Number.isFinite(n) ? n : undefined;
  }
  return undefined;
}
