/** Accept / bind observation evidence and narrative evidenceIds. */

import { ErrorCode, fail } from '../../errors.js';
import type { AppLanguage } from '../app-language.js';
import {
  coffeeHomeDomainClaim,
  coffeeOtherAgency,
  coffeePresumedUserState,
  coffeeUnsupportedExistingFact,
  coffeeUnsupportedSourceCausation,
  coffeePublicEvidenceLeak,
  evaluateCoffeeQuality,
  evaluatePalmQuality,
  type HumanQualityFailure,
} from '../human-quality.js';
import { mapCoffeeMeanings } from './coffee-meaning-map.js';
import {
  coffeeCommunicationAffordance,
  coffeeContextEventPromotion,
  coffeeContextOnlyTakeaway,
  coffeeEvidenceConcentration,
  coffeeNarrativelySparse,
  coffeeSparseContextAnchored,
  coffeePlainLineRelocation,
  coffeeSingleSemanticAnchorRoots,
} from './coffee-diversity.js';
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
  | 'evidence_leak'
  | PalmNamedFailure
  /** A real internal evidence id literally appeared inside prose text. */
  | 'evidence_id_in_prose';

/** Palm gate codes forwarded by name so repair can target the defect. */
const PALM_NAMED_FAILURES = [
  'dictionary_voice',
  'unsupported_other_person',
  'presumed_user_state',
  'coaching_voice',
  'person_switch',
  'prohibited_claim',
  'unsupported_certainty',
] as const;
type PalmNamedFailure = (typeof PALM_NAMED_FAILURES)[number];

function isPalmNamedFailure(code: string): code is PalmNamedFailure {
  return (PALM_NAMED_FAILURES as readonly string[]).includes(code);
}

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
 * Keeps an already-accepted CoffeeV2Observation in the internal grounding
 * shape used by binding and quality checks. Raw evidence (including each
 * sourceSlot) remains intact here, but `buildCoffeeWriterPacket` maps it to
 * private meaning facets and never forwards this observation to the writer.
 * `checks` is only the faithful V2 quality summary required by the internal
 * CoffeeObservation contract; it does not re-run the V2 gate.
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
  if (q === 'evidence_leak') return 'evidence_leak';
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
  const quality = coffeeQualityFailure(narrative, language, personalization, obs.evidence);
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
  if (coffeeContextOnlyTakeaway(narrative.takeaway, obs.evidence)) return 'insight_collapse';
  return null;
}

/**
 * Story-first closure: does anything legitimately place this reading at
 * home? A handle-side evidence item (region or description), or supplied
 * personalization (intention / themes / memory) that is itself about home
 * or family.
 */
export function coffeeHomeAffordance(
  evidence: ReadingEvidenceItem[],
  personalization?: ReadingPersonalization,
): boolean {
  if (evidence.some((item) => /\bhandle\b/i.test(`${item.region.replace(/_/g, ' ')} ${item.description}`))) return true;
  const supplied = [personalization?.intention, personalization?.memorySummary, ...(personalization?.relevantThemes ?? [])]
    .filter(Boolean)
    .join(' ')
    .toLocaleLowerCase('tr');
  return /\b(ev|evim|evimiz|aile|ailem|annem|babam|kardeş|home|family)\w*/.test(supplied);
}

/**
 * The un-mapped Coffee quality code behind a `human_quality` bind failure.
 * Internal only (repair guidance); the transport still reports the mapped
 * BindFailure, so the public error contract is unchanged.
 */
export function coffeeQualityFailure(
  narrative: CoffeeNarrative,
  language: AppLanguage = 'tr',
  personalization?: ReadingPersonalization,
  evidence?: ReadingEvidenceItem[],
): HumanQualityFailure | null {
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
    hasIntention: Boolean(personalization?.intention),
    relevantThemes: personalization?.relevantThemes,
    groundedSigns: evidence
      ? mapCoffeeMeanings(
          {
            usable: true,
            checks: {
              cupInteriorVisible: true,
              adequateFocusLight: true,
              residueVisible: true,
              milkFoamObstruction: false,
              usefulRegionsVisible: true,
            },
            evidence,
          },
          language,
        ).length
      : undefined,
    communicationAffordance: evidence ? coffeeCommunicationAffordance(evidence) : undefined,
    singleSemanticAnchorRoots: evidence ? coffeeSingleSemanticAnchorRoots(evidence) : undefined,
    narrativelySparse: evidence ? coffeeNarrativelySparse(evidence) : undefined,
    sparseContextAnchored: evidence
      ? coffeeSparseContextAnchored(
          [narrative.overall, narrative.love, narrative.career, narrative.money, narrative.nearFuture, narrative.takeaway],
          evidence,
        )
      : undefined,
  });
  if (quality) return quality;
  if (
    coffeePublicEvidenceLeak(
      [
        narrative.visualObservation.text,
        narrative.overall.text,
        narrative.love.text,
        narrative.career.text,
        narrative.money.text,
        narrative.nearFuture.text,
        narrative.takeaway.text,
      ],
      evidence
        ?.map((item) => item.resemblance?.trim())
        .filter((value): value is string => Boolean(value)),
    )
  ) {
    return 'evidence_leak';
  }
  const meaningTexts = [narrative.overall, narrative.love, narrative.career, narrative.money, narrative.nearFuture, narrative.takeaway].map((s) => s.text);
  // Personalization-aware (evidence path only; the legacy single-call parser
  // is unaffected): the person's expectation / wish / prior thought presumed.
  if (
    (language === 'tr' || language === undefined) &&
    !personalization?.memorySummary &&
    !personalization?.intention &&
    coffeePresumedUserState(meaningTexts)
  ) {
    return 'presumed_user_state';
  }
  const turkish = language === 'tr' || language === undefined;
  if (turkish && !personalization?.memorySummary && !personalization?.intention && coffeeUnsupportedExistingFact(meaningTexts)) {
    return 'unsupported_existing_fact';
  }
  if (turkish && !personalization?.memorySummary && !personalization?.intention && coffeeUnsupportedSourceCausation(meaningTexts)) {
    return 'unsupported_source_causation';
  }
  // A specific other person's attitude / decision / intention / action.
  if (turkish && !personalization?.memorySummary && !personalization?.intention && coffeeOtherAgency(meaningTexts)) {
    return 'unsupported_other_agency';
  }
  // Home / close circle needs a home affordance: a handle-side cue in the
  // evidence, or personalization that is itself about home / family.
  if (turkish && evidence && !coffeeHomeAffordance(evidence, personalization) && coffeeHomeDomainClaim(meaningTexts)) {
    return 'unsupported_home_domain';
  }
  if (evidence && turkish && coffeePlainLineRelocation(meaningTexts, evidence)) {
    return 'plain_line_relocation';
  }
  // Evidence-aware (needs per-section evidenceIds): context promoted to events.
  if (
    evidence &&
    (language === 'tr' || language === undefined) &&
    coffeeContextEventPromotion(
      [narrative.overall, narrative.love, narrative.career, narrative.money, narrative.nearFuture, narrative.takeaway],
      evidence,
    )
  ) {
    return 'context_event';
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
    hasStatedContext: Boolean(
      personalization?.intention?.trim() || personalization?.memorySummary?.trim(),
    ),
    relevantThemes: personalization?.relevantThemes,
  });
  if (quality) return isPalmNamedFailure(quality) ? quality : mapQuality(quality);
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
    code === 'evidence_leak' ||
    code === 'evidence_id_in_prose' ||
    isPalmNamedFailure(code)
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
