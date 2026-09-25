/** Phase 5 — Yıldızname result parse + evidence binding (fail-closed). */
import { ErrorCode, fail } from '../errors.js';
import { asRecord } from './sanitize.js';
import type { YildiznameWireNarrative } from './narrative-yildizname-contract.js';
import {
  asEnumSet,
  YILDIZNAME_LIMITS,
  YILDIZNAME_RESULT_CONTRACT_VERSION,
  YILDIZNAME_SECTION_KINDS,
} from './narrative-yildizname-limits.js';
import { findDeterministicFuture } from './narrative-tarot-prose-quality.js';

export type YildiznameNarrativeResult = {
  contractVersion: 1;
  languageCode: 'tr' | 'en' | 'ru';
  scope: string;
  summary: { text: string; factRefs: string[]; themeRefs: string[] };
  sections: {
    kind: string;
    text: string;
    factRefs: string[];
    themeRefs: string[];
  }[];
  reflectionPrompt: string | null;
  closingMessage: string;
};

const TOP = new Set([
  'contractVersion',
  'languageCode',
  'scope',
  'summary',
  'sections',
  'reflectionPrompt',
  'closingMessage',
]);

const SECTION_KINDS = asEnumSet(YILDIZNAME_SECTION_KINDS);

function bad(): never {
  fail(ErrorCode.invalidResponse);
}

function exactKeys(obj: Record<string, unknown>, allowed: Set<string>): void {
  for (const k of Object.keys(obj)) {
    if (!allowed.has(k)) bad();
  }
  for (const k of allowed) {
    if (!(k in obj)) bad();
  }
}

function nonEmpty(v: unknown, max: number): string {
  if (typeof v !== 'string') bad();
  const t = v.trim();
  if (!t || v.length > max) bad();
  return v;
}

function nullable(v: unknown, max: number): string | null {
  if (v === null) return null;
  if (typeof v !== 'string') bad();
  const t = v.trim();
  if (!t || v.length > max) bad();
  return v;
}

function parseRefList(
  raw: unknown,
  allowed: Set<string>,
  maxItems: number,
  maxChars: number,
): string[] {
  if (!Array.isArray(raw)) bad();
  if (raw.length > maxItems) bad();
  const seen = new Set<string>();
  const out: string[] = [];
  for (const item of raw) {
    if (typeof item !== 'string') bad();
    if (item.length < 1 || item.length > maxChars) bad();
    if (!allowed.has(item) || seen.has(item)) bad();
    seen.add(item);
    out.push(item);
  }
  return out;
}

export function parseYildiznameNarrativeResult(
  rawText: string,
  requestNarrative: YildiznameWireNarrative,
): YildiznameNarrativeResult {
  let parsed: unknown;
  try {
    parsed = JSON.parse(rawText);
  } catch {
    bad();
  }
  const root = asRecord(parsed);
  if (!root) bad();
  exactKeys(root, TOP);
  if (root.contractVersion !== YILDIZNAME_RESULT_CONTRACT_VERSION) bad();
  if (root.languageCode !== requestNarrative.languageCode) bad();
  if (root.scope !== requestNarrative.scope) bad();

  const allowedFacts = collectFactRefs(requestNarrative);
  const allowedThemes = new Set(
    requestNarrative.discoveryThemes.map((t) => String(t.themeRef)),
  );

  const summary = parseProseBlock(
    root.summary,
    allowedFacts,
    allowedThemes,
    YILDIZNAME_LIMITS.summary,
  );
  const sections = parseSections(
    root.sections,
    allowedFacts,
    allowedThemes,
  );
  const reflectionPrompt = nullable(
    root.reflectionPrompt,
    YILDIZNAME_LIMITS.reflectionPrompt,
  );
  const closingMessage = nonEmpty(
    root.closingMessage,
    YILDIZNAME_LIMITS.closingMessage,
  );

  const result: YildiznameNarrativeResult = {
    contractVersion: 1,
    languageCode: requestNarrative.languageCode,
    scope: requestNarrative.scope,
    summary,
    sections,
    reflectionPrompt,
    closingMessage,
  };
  assertTotalChars(result);
  assertLightProseSafety(result);
  return result;
}

function collectFactRefs(n: YildiznameWireNarrative): Set<string> {
  const out = new Set<string>();
  for (const list of [
    n.placements,
    n.angles,
    n.houses,
    n.aspects,
    n.balances,
  ]) {
    for (const item of list) out.add(String(item.factRef));
  }
  return out;
}

function parseProseBlock(
  raw: unknown,
  facts: Set<string>,
  themes: Set<string>,
  maxText: number,
): YildiznameNarrativeResult['summary'] {
  const r = asRecord(raw);
  if (!r) bad();
  exactKeys(r, new Set(['text', 'factRefs', 'themeRefs']));
  return {
    text: nonEmpty(r.text, maxText),
    factRefs: parseRefList(
      r.factRefs,
      facts,
      YILDIZNAME_LIMITS.maxFactRefsPerBlock,
      YILDIZNAME_LIMITS.maxFactRefChars,
    ),
    themeRefs: parseRefList(
      r.themeRefs,
      themes,
      YILDIZNAME_LIMITS.maxThemeRefsPerBlock,
      YILDIZNAME_LIMITS.maxThemeRefChars,
    ),
  };
}

function parseSections(
  raw: unknown,
  facts: Set<string>,
  themes: Set<string>,
): YildiznameNarrativeResult['sections'] {
  if (!Array.isArray(raw)) bad();
  if (raw.length < 1 || raw.length > YILDIZNAME_LIMITS.maxSections) bad();
  const seenKinds = new Set<string>();
  const out: YildiznameNarrativeResult['sections'] = [];
  for (const item of raw) {
    const r = asRecord(item);
    if (!r) bad();
    exactKeys(r, new Set(['kind', 'text', 'factRefs', 'themeRefs']));
    const kind = nonEmpty(r.kind, 64);
    if (!SECTION_KINDS.has(kind) || seenKinds.has(kind)) bad();
    seenKinds.add(kind);
    out.push({
      kind,
      text: nonEmpty(r.text, YILDIZNAME_LIMITS.section),
      factRefs: parseRefList(
        r.factRefs,
        facts,
        YILDIZNAME_LIMITS.maxFactRefsPerBlock,
        YILDIZNAME_LIMITS.maxFactRefChars,
      ),
      themeRefs: parseRefList(
        r.themeRefs,
        themes,
        YILDIZNAME_LIMITS.maxThemeRefsPerBlock,
        YILDIZNAME_LIMITS.maxThemeRefChars,
      ),
    });
  }
  return out;
}

function assertTotalChars(result: YildiznameNarrativeResult): void {
  let total = result.summary.text.length + result.closingMessage.length;
  if (result.reflectionPrompt) total += result.reflectionPrompt.length;
  for (const s of result.sections) total += s.text.length;
  if (total > YILDIZNAME_LIMITS.totalVisible) bad();
}

/** Light server-side prose safety — not the full Flutter quality corpus. */
function assertLightProseSafety(result: YildiznameNarrativeResult): void {
  const parts = [
    result.summary.text,
    result.closingMessage,
    ...(result.reflectionPrompt ? [result.reflectionPrompt] : []),
    ...result.sections.map((s) => s.text),
  ];
  const prose = parts.join('\n');
  if (/placement\.|angle\.|house\.|aspect\.|balance\.|theme\./i.test(prose)) {
    bad();
  }
  if (/\{[\s\S]*"factRefs"/.test(prose) || /```/.test(prose)) bad();
  const prophecy = findDeterministicFuture(prose, result.languageCode);
  if (prophecy !== null) bad();
}
