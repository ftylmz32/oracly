/**
 * Story-first closure — Coffee repair guidance for the ONE repair call.
 *
 * A rejected Coffee narrative can carry more than one deterministic defect,
 * but the bind reports only the first (e.g. section_redundancy before a
 * possibility menu). Repairing only that one left the menu in place and the
 * single allowed repair then failed. The primary violation is unchanged;
 * secondary defects detected by the SAME gate helpers are appended as
 * internal guidance only. Coffee only; Palm never calls this.
 */

import type { AppLanguage } from '../app-language.js';
import { coffeeHomeDomainClaim, coffeeOtherAgency, coffeePresumedUserState, coffeeSecondaryDefects, coffeeUnsupportedExistingFact, coffeeUnsupportedSourceCausation, type CoffeeSecondaryDefect } from '../human-quality.js';
import {
  coffeeContextEventPromotion,
  coffeeNarrativelySparse,
  coffeePlainLineRelocation,
  coffeeRepairFocus,
} from './coffee-diversity.js';
import { coffeeHomeAffordance, coffeeQualityFailure, type BindFailure } from './evidence-bind.js';
import type { CoffeeNarrative, ReadingEvidenceItem, ReadingPersonalization } from './types.js';
import { CONTEXT_EVENT_FOCUS, coffeeEmptyRequiredFocus, coffeeVoiceRepairFocus } from './writer-prompts.js';

function interpretationTexts(n: CoffeeNarrative): string[] {
  return [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway].map(
    (section) => section?.text ?? '',
  );
}

function primaryGuidance(
  violation: BindFailure,
  rejected: CoffeeNarrative,
  evidence: ReadingEvidenceItem[],
  primaryDetail: string | null,
): string | undefined {
  if (violation === 'insight_collapse' || violation === 'section_redundancy') {
    return coffeeRepairFocus(
      { overall: rejected.overall, nearFuture: rejected.nearFuture, takeaway: rejected.takeaway },
      evidence,
    );
  }
  if (violation === 'human_quality') return coffeeVoiceRepairFocus(primaryDetail);
  if (violation === 'empty_required') return coffeeEmptyRequiredFocus(rejected);
  return undefined;
}

function secondaryLine(defect: CoffeeSecondaryDefect, found: string | null): string {
  if (defect === 'possibility_menu') {
    return `possibility_menu — the reading lists alternative interpretations${found ? ` (near: "${found}")` : ''}. Collapse each list into ONE broader grounded meaning in fresh wording specific to this cup — do not reuse wording from these instructions. No "ya da / veya" alternatives anywhere.`;
  }
  if (defect === 'repeated_sentence') {
    return `repeated_sentence — one sentence is told twice in nearly the same words${found ? ` (near: "${found}")` : ''}. Keep one telling; replace the other with something this cup actually adds, or drop it.`;
  }
  if (defect === 'dictionary_voice') {
    return 'dictionary_voice — symbol-dictionary sentences ("… -e yorulur", "… olarak yorumlanır"). Retell them directly as the fortune itself.';
  }
  if (defect === 'cup_meta_talk') {
    return `cup_meta_talk — the reading comments on how much the cup tells or what it lacks${found ? ` (near: "${found}")` : ''}. Remove it and say plainly what is there; a sparse cup may stay short.`;
  }
  if (defect === 'geometry_inference') {
    return `geometry_inference — a shape is given a cause, an agent or a relationship role${found ? ` (near: "${found}")` : ''}. Keep only what the shape shows (its course, its link, where it reaches); no why, no who steers whom, no who carries the bond.`;
  }
  if (defect === 'advice_voice') {
    return `advice_voice — the reading instructs the person${found ? ` (near: "${found}")` : ''}. A fortune tells what is coming; replace the instruction with what the cup shows, or drop it.`;
  }
  if (defect === 'context_sequence') {
    return `context_sequence — scattering, dots, faint marks or the base are given an order of events${found ? ` (near: "${found}")` : ''}. Let the real sign carry the event; context may only qualify it, without "one after another / then / afterwards".`;
  }
  if (defect === 'plain_line_relocation') {
    return `plain_line_relocation — the reading moves the person somewhere${found ? ` (near: "${found}")` : ''}, but the cup shows no road or path. A plain line, a handle-side line or a bridge is a link between two places, not being carried elsewhere.`;
  }
  if (defect === 'context_event') {
    return `context_event${found ? ` (near: "${found}")` : ''} — ${CONTEXT_EVENT_FOCUS}`;
  }
  if (defect === 'unsupported_home_domain') {
    return `unsupported_home_domain${found ? ` (near: "${found}")` : ''} — home / family / close-circle claims on a cup with no handle-side cue. Keep the sign's own meaning and remove those claims.`;
  }
  if (defect === 'unsupported_other_agency') {
    return `unsupported_other_agency${found ? ` (near: "${found}")` : ''} — a specific other person's attitude, decision or action is claimed. Keep the bond or commitment at the level the sign supports; mutual language is fine.`;
  }
  if (defect === 'presumed_user_state') {
    return `presumed_user_state — the reading presumes what the person is waiting for, expects, wants or already thought${found ? ` (near: "${found}")` : ''}. Keep the event the sign carries; drop only the presumption about the person's mind.`;
  }
  if (defect === 'unsupported_existing_fact') {
    return `unsupported_existing_fact${found ? ` (near: "${found}")` : ''} â€” the reading invents a past or already-existing external fact. Keep only the future or structural meaning supported by the sign.`;
  }
  if (defect === 'unsupported_source_causation') {
    return `unsupported_source_causation${found ? ` (near: "${found}")` : ''} â€” a location or domain is treated as the cause/source. Keep the domain and structural connection; remove the causal attribution.`;
  }
  return 'invented_plan — the reading presupposes a plan (existing, half-finished, resumed, or coming out of a place) the cup never showed. Tell only what this particular shape shows instead (a road: its course; a bridge: the link between its sides; a plain line: that link).';
}

/**
 * Secondary deterministic Coffee defects present in the rejected narrative,
 * excluding the one the primary violation already names.
 */
export function coffeeAdditionalRepairDefects(
  rejected: CoffeeNarrative,
  primaryDetail: string | null,
  evidence?: ReadingEvidenceItem[],
  personalization?: ReadingPersonalization,
): Array<{ defect: CoffeeSecondaryDefect; found: string | null }> {
  const found = coffeeSecondaryDefects(interpretationTexts(rejected));
  if (!personalization?.memorySummary && !personalization?.intention) {
    const presumed = coffeePresumedUserState(interpretationTexts(rejected));
    if (presumed) found.push({ defect: 'presumed_user_state', found: presumed });
    const agency = coffeeOtherAgency(interpretationTexts(rejected));
    if (agency) found.push({ defect: 'unsupported_other_agency', found: agency });
    const existing = coffeeUnsupportedExistingFact(interpretationTexts(rejected));
    if (existing) found.push({ defect: 'unsupported_existing_fact', found: existing });
    const source = coffeeUnsupportedSourceCausation(interpretationTexts(rejected));
    if (source) found.push({ defect: 'unsupported_source_causation', found: source });
  }
  if (evidence && !coffeeHomeAffordance(evidence, personalization)) {
    const home = coffeeHomeDomainClaim(interpretationTexts(rejected));
    if (home) found.push({ defect: 'unsupported_home_domain', found: home });
  }
  if (evidence) {
    const promoted = coffeeContextEventPromotion(
      [rejected.overall, rejected.love, rejected.career, rejected.money, rejected.nearFuture, rejected.takeaway],
      evidence,
    );
    if (promoted) found.push({ defect: 'context_event', found: promoted });
    const relocation = coffeePlainLineRelocation(interpretationTexts(rejected), evidence);
    if (relocation) found.push({ defect: 'plain_line_relocation', found: relocation });
  }
  return found.filter(({ defect }) => defect !== primaryDetail);
}

/** Full guidance for the single Coffee repair call. */
export function coffeeRepairGuidance(
  violation: BindFailure,
  rejected: CoffeeNarrative,
  evidence: ReadingEvidenceItem[],
  language: AppLanguage,
  personalization?: ReadingPersonalization,
): string | undefined {
  const primaryDetail =
    violation === 'human_quality'
      ? coffeeQualityFailure(rejected, language, personalization, evidence)
      : null;
  const sparse = coffeeNarrativelySparse(evidence);
  let primary =
    sparse && primaryDetail === 'too_short'
      ? SPARSE_TOO_SHORT_FOCUS
      : primaryGuidance(violation, rejected, evidence, primaryDetail);
  // A sparse cup never receives the full-fortune length target.
  if (sparse && primary) primary = primary.replace(FULL_FORTUNE_TARGET, 'Keep overall concise; rewrite only what repeats.');
  const extra = coffeeAdditionalRepairDefects(rejected, primaryDetail, evidence, personalization);
  const note = sparse ? SPARSE_CUP_NOTE : '';
  if (extra.length === 0) return [primary, note].filter(Boolean).join(' ') || undefined;
  return [
    primary,
    `Additional detected Coffee defects: ${extra.map((e) => e.defect).join(', ')}. Fix them in this same repair, together with the primary violation:`,
    ...extra.map((e) => secondaryLine(e.defect, e.found)),
    sparse
      ? 'Preserve the valid grounded substance and stay concise; do not introduce a plan, event, category or backstory, and do not use unused context evidence to fill space.'
      : 'Preserve the valid grounded substance; do not shorten the reading below a full main fortune, do not introduce a plan, event or backstory, and do not use unused context evidence to fill space.',
    note,
  ]
    .filter(Boolean)
    .join(' ');
}

/** The non-sparse redundancy focus's length target (coffee-diversity.ts). */
const FULL_FORTUNE_TARGET = 'Keep the grounded substance of overall; rewrite only what repeats.';

/**
 * Story-first closure: on a narratively sparse cup the "full main fortune
 * (70–120 words)" target produced padding and report prose in real repairs
 * (targeted11 HANDLE, DOTS) and a 1-word miss (targeted14 HANDLE). Sparse
 * repairs never see that target.
 */
const SPARSE_CUP_NOTE =
  'THIS CUP IS NARRATIVELY SPARSE (no sign and no drawn form — only dots, faint marks, density, a clean band or the handle side): a concise reading is correct. When fixing a defect, rewrite the offending sentence at evidence level instead of deleting it — never cut the reading below its sparse minimum (visualObservation + overall at least 35 words, overall at least 20, takeaway at least 8). Preserve the grounded substance and stay concise — a few direct sentences in overall, the takeaway one short distinct point. Add words only when they add a grounded facet; never pad toward a length, and never invent events, categories, report vocabulary (inner surface, traces, density) or comments on what the cup lacks to fill space.';

const SPARSE_TOO_SHORT_FOCUS =
  'The reading is slightly below the minimum length for a sparse cup (visualObservation + overall at least 35 words together, overall at least 20, takeaway at least 8). Keep everything that is grounded and add only what this cup actually holds — where the telve sits, what that place means for the person — in direct falcı language. Do not add events, categories, advice or report vocabulary.';
