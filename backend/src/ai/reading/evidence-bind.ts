/** Accept / bind observation evidence and narrative evidenceIds. */

import { ErrorCode, fail } from '../../errors.js';
import type { AppLanguage } from '../app-language.js';
import {
  evaluateCoffeeQuality,
  evaluatePalmQuality,
  type HumanQualityFailure,
} from '../human-quality.js';
import { coffeeEvidenceConcentration } from './coffee-diversity.js';
import {
  isCoffeeV2SourceSlot,
  type CoffeeNarrative,
  type CoffeeObservation,
  type CoffeeV2Observation,
  type NarrativeSection,
  type PalmNarrative,
  type PalmObservation,
  type ReadingEvidenceItem,
  type ReadingPersonalization,
} from './types.js';

export type BindFailure =
  | 'unusable'
  | 'insufficient_evidence'
  | 'duplicate_evidence'
  | 'unknown_evidence_id'
  | 'missing_evidence_ids'
  | 'narrative_visual_without_id'
  | 'hedge_dropped'
  | 'human_quality'
  | 'empty_required'
  | 'locale_leak'
  | 'embedded_disclaimer'
  | 'generic_closing'
  | 'inferred_handedness'
  | 'theme_domination'
  | 'section_redundancy'
  | 'insight_collapse'
  | 'stock_advice'
  | 'evidence_reuse'
  /** A real internal evidence id literally appeared inside prose text. */
  | 'evidence_id_in_prose';

const FORTUNE_LEAK =
  /gelecek|kehanet|kaderin|you will meet|destiny awaits|fal olarak|yorumu:/i;

export function acceptCoffeeObservation(obs: CoffeeObservation): BindFailure | null {
  if (!obs.usable) return 'unusable';
  const c = obs.checks;
  if (
    !c.cupInteriorVisible ||
    !c.residueVisible ||
    !c.usefulRegionsVisible ||
    c.milkFoamObstruction ||
    !c.adequateFocusLight
  ) {
    return 'unusable';
  }
  return acceptEvidenceList(obs.evidence, 3);
}

/**
 * Coffee V2 (three-photo reading) — additive, dedicated quality gate.
 * Never touches or replaces `acceptCoffeeObservation` above (legacy,
 * single-image). Photo QUALITY and visual CONTENT are different things:
 * this gate rejects unusable photography, never uninteresting residue.
 */
export type CoffeeV2GateFailure =
  | 'unusable'
  | 'cup_primary_not_visible'
  | 'cup_secondary_not_visible'
  | 'saucer_not_visible'
  | 'inadequate_focus_light'
  | 'no_residue_on_either_cup'
  | 'invalid_source_slot'
  | BindFailure;

export function acceptCoffeeV2Observation(
  obs: CoffeeV2Observation,
): CoffeeV2GateFailure | null {
  if (!obs.usable) return 'unusable';
  const { cupPrimary, cupSecondary, saucer } = obs.photoChecks;
  if (!cupPrimary.cupInteriorVisible) return 'cup_primary_not_visible';
  if (!cupSecondary.cupInteriorVisible) return 'cup_secondary_not_visible';
  if (!saucer.saucerVisible) return 'saucer_not_visible';
  if (!cupPrimary.adequateFocusLight || !cupSecondary.adequateFocusLight || !saucer.adequateFocusLight) {
    return 'inadequate_focus_light';
  }
  // Deliberately NOT required: saucer.residueOrFlowVisible, residue on
  // BOTH cup sides, or a minimum symbol count — a genuinely sparse surface
  // is valid evidence, not a quality failure.
  if (!cupPrimary.residueVisible && !cupSecondary.residueVisible) {
    return 'no_residue_on_either_cup';
  }
  for (const item of obs.evidence) {
    if (!isCoffeeV2SourceSlot(item.sourceSlot)) return 'invalid_source_slot';
  }
  return acceptEvidenceList(obs.evidence, 3);
}

/**
 * Adapts an already-accepted CoffeeV2Observation into the exact shape the
 * existing, unmodified Coffee writer (`runCoffeeWriter` /
 * `buildCoffeeWriterPacket` / `bindCoffeeNarrative`) already consumes.
 * Those functions read only `.evidence` at runtime (never `.checks`) --
 * `checks` below exists purely to satisfy `CoffeeObservation`'s type with a
 * faithful summary, not a re-run of the V2 gate (already passed). Each
 * evidence item's `sourceSlot` rides through structurally unchanged, so the
 * writer prompt sees it in the evidence JSON without any writer/prompt
 * change at all.
 */
export function adaptCoffeeV2ForWriter(obs: CoffeeV2Observation): CoffeeObservation {
  const { cupPrimary, cupSecondary, saucer } = obs.photoChecks;
  return {
    usable: obs.usable,
    reason: obs.reason,
    checks: {
      cupInteriorVisible: cupPrimary.cupInteriorVisible && cupSecondary.cupInteriorVisible,
      adequateFocusLight:
        cupPrimary.adequateFocusLight && cupSecondary.adequateFocusLight && saucer.adequateFocusLight,
      residueVisible: cupPrimary.residueVisible || cupSecondary.residueVisible,
      milkFoamObstruction: false,
      usefulRegionsVisible:
        cupPrimary.usefulRegionsVisible || cupSecondary.usefulRegionsVisible || saucer.usefulRegionsVisible,
    },
    evidence: obs.evidence,
  };
}

export function acceptPalmObservation(obs: PalmObservation): BindFailure | null {
  if (!obs.usable) return 'unusable';
  const c = obs.checks;
  if (
    !c.onePalmFacing ||
    !c.majorLinesVisible ||
    c.overlapOcclusion ||
    c.dorsal ||
    !c.adequateFocusLight
  ) {
    return 'unusable';
  }
  const lineKeys = new Set<string>();
  for (const e of obs.evidence) {
    const blob = (e.region + ' ' + e.description).toLocaleLowerCase('tr-TR');
    if (/heart\s*line|kalp(\s*çizgi|\s*cizgi)?|kalp\b/.test(blob)) lineKeys.add('heart');
    if (/head\s*line|zihin(\s*çizgi|\s*cizgi)?|kafa\s*çiz|head\b/.test(blob)) lineKeys.add('head');
    if (/life\s*line|ya[sş]am(\s*çizgi|\s*cizgi)?|life\b/.test(blob)) lineKeys.add('life');
    if (/fate\s*line|kader(\s*çizgi|\s*cizgi)?/.test(blob)) lineKeys.add('fate');
  }
  if (lineKeys.size < 2 && !c.majorLinesVisible) return 'insufficient_evidence';
  return acceptEvidenceList(obs.evidence, 3);
}

function acceptEvidenceList(
  evidence: ReadingEvidenceItem[],
  min: number,
): BindFailure | null {
  if (!Array.isArray(evidence) || evidence.length < min) {
    return 'insufficient_evidence';
  }
  const ids = new Set<string>();
  const regionKeys = new Set<string>();
  for (const item of evidence) {
    if (!item?.id || !item.region || !item.description) {
      return 'insufficient_evidence';
    }
    if (ids.has(item.id)) return 'duplicate_evidence';
    ids.add(item.id);
    if (FORTUNE_LEAK.test(item.description) || FORTUNE_LEAK.test(item.region)) {
      return 'insufficient_evidence';
    }
    regionKeys.add(normalizeRegion(item.region + '|' + item.description.slice(0, 40)));
  }
  if (regionKeys.size < min) return 'insufficient_evidence';
  return null;
}

function normalizeRegion(s: string): string {
  return s.toLocaleLowerCase('tr-TR').replace(/\s+/g, ' ').trim();
}

function mapQuality(q: HumanQualityFailure): BindFailure {
  if (q === 'locale_leak') return 'locale_leak';
  if (q === 'embedded_disclaimer') return 'embedded_disclaimer';
  if (q === 'generic_closing') return 'generic_closing';
  if (q === 'inferred_handedness') return 'inferred_handedness';
  if (
    q === 'theme_domination' ||
    q === 'section_redundancy' ||
    q === 'insight_collapse' ||
    q === 'stock_advice' ||
    q === 'evidence_reuse'
  ) {
    return q;
  }
  return 'human_quality';
}

export function bindCoffeeNarrative(
  narrative: CoffeeNarrative,
  obs: CoffeeObservation,
  language: AppLanguage = 'tr',
  personalization?: ReadingPersonalization,
): BindFailure | null {
  const known = new Set(obs.evidence.map((e) => e.id));
  const required: NarrativeSection[] = [
    narrative.visualObservation,
    narrative.overall,
    narrative.takeaway,
  ];
  for (const sec of required) {
    if (!sec?.text?.trim()) return 'empty_required';
  }
  const allSections = [
    narrative.visualObservation,
    narrative.overall,
    narrative.love,
    narrative.career,
    narrative.money,
    narrative.nearFuture,
    narrative.takeaway,
  ];
  const bind = bindSections(allSections, known, obs.evidence);
  if (bind) return bind;
  const quality = evaluateCoffeeQuality({
    visualObservation: narrative.visualObservation.text,
    overall: narrative.overall.text,
    love: narrative.love.text,
    career: narrative.career.text,
    money: narrative.money.text,
    nearFuture: narrative.nearFuture.text,
    takeaway: narrative.takeaway.text,
    language,
    hasMemoryContext: Boolean(personalization?.memorySummary),
    relevantThemes: personalization?.relevantThemes,
  });
  if (quality) return mapQuality(quality);
  if (
    coffeeEvidenceConcentration(
      {
        overall: narrative.overall,
        nearFuture: narrative.nearFuture,
        takeaway: narrative.takeaway,
      },
      obs.evidence,
    )
  ) {
    return 'insight_collapse';
  }
  return null;
}

export function bindPalmNarrative(
  narrative: PalmNarrative,
  obs: PalmObservation,
  language: AppLanguage = 'tr',
  trustedHandSide = false,
  personalization?: ReadingPersonalization,
): BindFailure | null {
  const known = new Set(obs.evidence.map((e) => e.id));
  if (!narrative.visualObservation?.text?.trim() || !narrative.overall?.text?.trim()) {
    return 'empty_required';
  }
  const allSections = [
    narrative.visualObservation,
    narrative.overall,
    narrative.lifeLine,
    narrative.headLine,
    narrative.heartLine,
    narrative.fateLine,
    narrative.takeaway,
  ];
  const bind = bindSections(allSections, known, obs.evidence);
  if (bind) return bind;
  const quality = evaluatePalmQuality({
    visualObservation: narrative.visualObservation.text,
    overall: narrative.overall.text,
    lifeLine: narrative.lifeLine.text,
    headLine: narrative.headLine.text,
    heartLine: narrative.heartLine.text,
    fateLine: narrative.fateLine.text,
    takeaway: narrative.takeaway.text,
    language,
    trustedHandSide,
    hasMemoryContext: Boolean(personalization?.memorySummary),
    relevantThemes: personalization?.relevantThemes,
  });
  if (quality) return mapQuality(quality);
  return null;
}

function bindSections(
  sections: NarrativeSection[],
  known: Set<string>,
  evidence: ReadingEvidenceItem[],
): BindFailure | null {
  const hedges = evidence
    .filter((e) => e.resemblance && e.resemblance.trim())
    .map((e) => e.resemblance!.toLocaleLowerCase('tr-TR'));
  for (const sec of sections) {
    const text = (sec.text ?? '').trim();
    const ids = Array.isArray(sec.evidenceIds) ? sec.evidenceIds : [];
    if (!text) {
      if (ids.length > 0) return 'unknown_evidence_id';
      continue;
    }
    if (ids.length === 0) return 'missing_evidence_ids';
    for (const id of ids) {
      if (!known.has(id)) return 'unknown_evidence_id';
    }
    // A raw internal id (e.g. "e1", "p3") literally written into the
    // prose itself — the id belongs in evidenceIds, never in the text a
    // user reads. Short ids only (>=2 chars) matched at a word boundary
    // so this never false-positives on ordinary language.
    for (const id of known) {
      if (id.length < 2) continue;
      const escaped = id.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      if (new RegExp(`\\b${escaped}\\b`).test(text)) {
        return 'evidence_id_in_prose';
      }
    }
    if (
      /(bir demlik var|there is a teapot|demlik mevcut)/i.test(text) &&
      hedges.some((h) => /demlik|teapot|çaydanlık|caydanlik/.test(h))
    ) {
      return 'hedge_dropped';
    }
  }
  return null;
}

export function observationFail(
  code: BindFailure | CoffeeV2GateFailure,
  details?: Record<string, unknown>,
): never {
  if (code === 'unusable') {
    fail(ErrorCode.invalidImage, 200, { bindFailure: code, ...details });
  }
  fail(ErrorCode.invalidResponse, 200, { bindFailure: code, ...details });
}

export function narrativeFail(
  code: BindFailure,
  details?: Record<string, unknown>,
): never {
  if (
    code === 'human_quality' ||
    code === 'locale_leak' ||
    code === 'embedded_disclaimer' ||
    code === 'generic_closing' ||
    code === 'inferred_handedness' ||
    code === 'theme_domination' ||
    code === 'section_redundancy' ||
    code === 'insight_collapse' ||
    code === 'stock_advice' ||
    code === 'evidence_reuse' ||
    code === 'evidence_id_in_prose'
  ) {
    fail(ErrorCode.qualityUnavailable, 200, { bindFailure: code, ...details });
  }
  fail(ErrorCode.invalidResponse, 200, { bindFailure: code, ...details });
}

export function toPublicCoffee(n: CoffeeNarrative) {
  return {
    visualObservation: n.visualObservation.text,
    overall: n.overall.text,
    love: n.love.text,
    career: n.career.text,
    money: n.money.text,
    nearFuture: n.nearFuture.text,
    takeaway: n.takeaway.text,
    symbols: [] as Array<{ name: string; meaning: string; interpretation: string }>,
  };
}

export function toPublicPalm(n: PalmNarrative) {
  return {
    visualObservation: n.visualObservation.text,
    overall: n.overall.text,
    lifeLine: n.lifeLine.text,
    headLine: n.headLine.text,
    heartLine: n.heartLine.text,
    fateLine: n.fateLine.text,
    takeaway: n.takeaway.text,
    symbols: [] as string[],
    themes: [] as string[],
  };
}
