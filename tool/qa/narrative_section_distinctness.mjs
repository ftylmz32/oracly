/**
 * Phase 6E.5 — QA-only section distinctness diagnostic.
 *
 * Surfaces lexical overlap between narrative sections.
 * NOT a production rejection gate. Does NOT invent an overall quality score.
 *
 * Usage:
 *   node tool/qa/narrative_section_distinctness.mjs [path-to-results.json]
 * Default path: test/fixtures/tarot_narrative_provider_shadow_results_6e42_v2.json
 */

import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const DEFAULT_RESULTS =
  'test/fixtures/tarot_narrative_provider_shadow_results_6e42_v2.json';

const PAIRS = [
  ['summary', 'synthesis'],
  ['summary', 'advice'],
  ['summary', 'closingMessage'],
  ['synthesis', 'advice'],
  ['synthesis', 'closingMessage'],
  ['advice', 'closingMessage'],
];

/** Lightweight language-aware token normalize (EN/TR/RU). */
export function tokenize(text) {
  if (!text || typeof text !== 'string') return new Set();
  const lower = text
    .toLocaleLowerCase('en-US')
    .normalize('NFKC')
    .replace(/[^\p{L}\p{N}\s]+/gu, ' ');
  const stop = new Set([
    'the', 'a', 'an', 'and', 'or', 'of', 'to', 'in', 'on', 'for', 'with', 'your',
    'you', 'is', 'are', 'be', 'this', 'that', 'it', 'as', 'from', 'by', 'at',
    've', 'bir', 'bu', 'da', 'de', 'ile', 'için', 'olan', 'olarak',
    'и', 'в', 'на', 'с', 'к', 'по', 'для', 'это', 'что', 'как', 'из', 'от',
  ]);
  const out = new Set();
  for (const t of lower.split(/\s+/)) {
    if (t.length < 3 || stop.has(t)) continue;
    out.add(t);
  }
  return out;
}

export function jaccard(a, b) {
  if (a.size === 0 && b.size === 0) return 0;
  let inter = 0;
  for (const x of a) if (b.has(x)) inter++;
  const union = a.size + b.size - inter;
  return union === 0 ? 0 : inter / union;
}

export function sectionOverlaps(structured) {
  const out = {};
  for (const [left, right] of PAIRS) {
    const key = `${left}_${right === 'closingMessage' ? 'closing' : right}`;
    out[key] = Number(
      jaccard(tokenize(structured?.[left]), tokenize(structured?.[right])).toFixed(4),
    );
  }
  return out;
}

export function diagnoseCall(call) {
  const sr = call.structuredResult;
  if (!sr) {
    return {
      callNumber: call.callNumber,
      manifestId: call.manifestId,
      skipped: true,
      reason: 'no structuredResult',
    };
  }
  const overlaps = sectionOverlaps(sr);
  const max = Math.max(...Object.values(overlaps));
  // Diagnostic labels only — NOT a production pass/fail gate.
  let band = 'low';
  if (max >= 0.45) band = 'high';
  else if (max >= 0.28) band = 'review';
  return {
    callNumber: call.callNumber,
    manifestId: call.manifestId,
    languageCode: call.languageCode,
    cardCount: call.cardCount,
    overlaps,
    maxOverlap: Number(max.toFixed(4)),
    band,
    priorObservation: call.repetitionObservation ?? null,
  };
}

export function diagnoseResults(root) {
  const calls = Array.isArray(root.calls) ? root.calls : [];
  return {
    qaOnly: true,
    productionGate: false,
    overallQualityScore: null,
    note: 'Lexical overlap diagnostic only — does not certify writing quality.',
    calls: calls.map(diagnoseCall),
  };
}

function main() {
  const pathArg = process.argv[2] || DEFAULT_RESULTS;
  const abs = resolve(process.cwd(), pathArg);
  const root = JSON.parse(readFileSync(abs, 'utf8'));
  const report = diagnoseResults(root);
  console.log(JSON.stringify(report, null, 2));
}

const invokedDirectly =
  typeof process.argv[1] === 'string' &&
  process.argv[1].replace(/\\/g, '/').endsWith(
    'tool/qa/narrative_section_distinctness.mjs',
  );

if (invokedDirectly) {
  main();
}
