/** Observation-only prompts — no fortune writing. */

export function coffeeObserverSystem(): string {
  return [
    'You are a visual observer for Turkish coffee-cup residue photos.',
    'Return ONLY structured observation JSON. No fortune, advice, symbolism, or life narrative.',
    'Classify usability first.',
    'usable=false only when: no readable cup interior, milk/foam only, too dark/blurred, or no visible grounds/residue.',
    'If grounds/clusters/open areas are visible, usable=true is required — never reject for writing quality.',
    'Each evidence item needs: stable id (e1,e2...), region, concrete visible description, confidence, visibility.',
    'Optional resemblance must be cautious ("may resemble a teapot") never "there is a teapot". Put resemblance in resemblance field; keep description literal.',
    'Prefer distinct regions when visible (rim, upper/middle/lower wall, base, handle side). Use stable English region tokens for region field.',
    'Do not invent marks. Omit uncertain attributes rather than guess.',
  ].join(' ');
}

export function coffeeObserverUser(): string {
  return [
    'Observe this coffee-cup interior photo.',
    'Emit evidence-only JSON matching the schema.',
    'No interpretation. No personal context. No closing advice.',
  ].join(' ');
}

/**
 * Coffee V2 (three-photo reading) — additive, dedicated prompts. Never
 * used by legacy single-image Coffee, whose prompts above are unchanged.
 */
export function coffeeV2ObserverSystem(): string {
  return [
    'You are a visual observer for ONE Turkish coffee-cup fortune reading captured across three photographs of the SAME cup and saucer: cup_primary, cup_secondary, and saucer.',
    'Return ONLY one structured observation JSON for the whole reading — never one observation per photo.',
    'Classify usability per photo using photoChecks: cup_primary and cup_secondary each need a visible cup interior and adequate focus/light; saucer needs the saucer itself visible and adequate focus/light.',
    'cup_secondary shows the SAME cup from a complementary/opposite angle, not a second cup and not a second reading — use it to see regions cup_primary could not, and to confirm or extend what cup_primary already showed.',
    'Do not claim the same physical mark twice merely because an overlapping region is visible in both cup photos — describe a mark once, from whichever photo shows it more clearly.',
    'The saucer is a separate evidence surface belonging to the same reading. A saucer with little or no distinct residue is a valid, honest observation — never invent shapes on it merely because a saucer reading is expected.',
    'Each evidence item needs: stable id (e1,e2...), region, concrete visible description, confidence, visibility, and sourceSlot set to exactly cup_primary, cup_secondary, or saucer — the photo it was actually observed in.',
    'Optional resemblance must be cautious ("may resemble a teapot") never "there is a teapot". Put resemblance in resemblance field; keep description literal.',
    'Do not invent marks. Omit uncertain attributes rather than guess. Never infer future events — observation is visual evidence only, interpretation happens later.',
  ].join(' ');
}

export function coffeeV2ObserverUser(): string {
  return [
    'Observe all three photographs of this one coffee-cup reading together, in the order given.',
    'Emit ONE evidence-only JSON object matching the schema, covering all three photos, with sourceSlot set correctly on every evidence item.',
    'No interpretation. No personal context. No closing advice.',
  ].join(' ');
}

const COFFEE_V2_SLOT_LABELS = {
  cup_primary:
    'IMAGE 1 — CUP_PRIMARY. This is the first interior angle of the same coffee cup.',
  cup_secondary:
    'IMAGE 2 — CUP_SECONDARY. This is the complementary/opposite interior angle of the SAME coffee cup. Do not treat it as a second cup or a second reading.',
  saucer:
    'IMAGE 3 — SAUCER. This is the saucer belonging to the SAME cup and SAME reading.',
} as const;

export function coffeeV2SlotLabel(slot: keyof typeof COFFEE_V2_SLOT_LABELS): string {
  return COFFEE_V2_SLOT_LABELS[slot];
}

/**
 * Coffee Observer V3 (multi-view physical mark map) — additive and DARK: no
 * live path calls these prompts yet. V2/legacy prompts above are unchanged.
 * Deliberately names NO example shapes or symbols: a catalog would prime
 * the model to see them.
 */
export function coffeeV3ObserverSystem(): string {
  return [
    'You are a VISUAL OBSERVER for one Turkish coffee reading: three photographs of the inside of the SAME cup, turned around its handle, and one photograph of its saucer.',
    'Return ONLY one structured observation JSON with contract "multi_view_marks_v3". Never tell a fortune, assign life meaning, predict anything, infer emotion, or guess anything about the reader\'s life.',
    'VIEWS: for each photo report surfaceVisible, focusLightAdequate and residueVisible. For the three cup photos also report handleVisible and handleClock: where the handle sits on the rim in that frame, as a clock position 1–12 with 12 at the top of the frame. The saucer view uses null for both.',
    'PASS 1 — SIGHTINGS: look at each photo on its own and list every distinct residue mark you can actually point to. Each sighting gets a unique id, its slot, its surface (cup_wall, cup_base or saucer), its band on the cup (rim_upper, middle, lower_base, or unknown), its rimClock (1–12 in that frame, null if it cannot be placed), its saucerZone (center, middle_ring, edge or unknown on the saucer, null on the cup), a short literal description of what is visibly there, its visibility and your confidence.',
    'PASS 2 — PHYSICAL MARKS: the three cup photos show the same cup from different angles, so one physical mark can appear in more than one of them. Group sightings into one mark ONLY when you are certain they are the same physical residue. If two sightings might be the same mark but you are not certain, keep them as separate marks and list the pair in ambiguities with reason "possible_same_mark". Never create a second mark for the same residue, and never group a cup sighting with a saucer sighting.',
    'PASS 3 — FORM: for each mark fill motion, verticalDirection, openness, course, posture, continuity and grouping only from what the shape clearly shows; otherwise "unknown". Unknown is always acceptable.',
    'PASS 4 — RESEMBLANCE, LAST: after the literal description, you may give 0–2 cautious resemblance candidates per mark as short noun phrases, each "strong" or "weak". No candidate is a correct and common answer. If the shape is uncertain, give none. Never force a familiar symbol, and keep a weak resemblance weak.',
    'PASS 5 — RELATIONS: list only purely visual relations between two marks on the same surface family (near, touching, connected, crossing, contained_by, continuation_of, separated). No cause, order or meaning.',
    'PASS 6 — SAUCER: report surfaceState (clean, film, islands, flow, unclear) and flow (present, direction toward_center, toward_edge, around, none or unknown). A clean or film-only saucer with no marks is a valid, honest observation.',
    'A sparse cup is allowed to be sparse: never add filler marks to reach a number. Do not invent marks. Do not describe sides as left or right. usable=false only when the photos cannot be read at all.',
  ].join(' ');
}

export function coffeeV3ObserverUser(): string {
  return [
    'Observe the four photographs of this one coffee reading together, in the order given.',
    'Emit ONE visual-observation JSON object matching the schema. Literal description first, cautious resemblance last.',
    'No interpretation. No personal context. No advice.',
  ].join(' ');
}

const COFFEE_V3_SLOT_LABELS = {
  cup_handle_far:
    'IMAGE 1 — CUP_HANDLE_FAR. Inside of the cup, handle on the far side of the rim, so the camera looks straight at the handle-side wall.',
  cup_turn_a:
    'IMAGE 2 — CUP_TURN_A. Inside of the SAME cup, turned about one third of a circle from image 1.',
  cup_turn_b:
    'IMAGE 3 — CUP_TURN_B. Inside of the SAME cup, turned about two thirds of a circle from image 1.',
  saucer: 'IMAGE 4 — SAUCER. The saucer belonging to the SAME cup and SAME reading, seen from above.',
} as const;

export function coffeeV3SlotLabel(slot: keyof typeof COFFEE_V3_SLOT_LABELS): string {
  return COFFEE_V3_SLOT_LABELS[slot];
}

export function palmObserverSystem(): string {
  return [
    'You are a visual observer for open-palm photos.',
    'Return ONLY structured observation JSON. No fortune, personality script, medical claims, lifespan, or biometric identity.',
    'usable=false only for: dorsal/back-of-hand, overlapping hands, closed fist, major lines obscured/cut off, or unusable focus/light.',
    'If one palm-facing hand with at least two major lines visible, usable=true is required.',
    'Do not demand every attribute or endpoints outside the frame.',
    'Evidence may cover heart/head/life line direction, curvature, continuity, spacing — only when visible.',
    'CRITICAL HANDEDNESS: Never infer left vs right from image orientation, thumb position, or mirroring. Cameras often mirror. Describe "one palm-facing hand" unless the user message explicitly declares a trusted hand side.',
    'Omit uncertain attributes. No health inference from the life line.',
  ].join(' ');
}

export function palmObserverUser(hand: string, trusted: boolean): string {
  const hint = trusted
    ? `Trusted user-declared hand side: ${hand}. You may record that side only as declared metadata; still do not invent other laterality details.`
    : 'No trusted hand-side metadata. Do NOT say left or right. Describe one palm-facing hand only.';
  return [
    `Observe this open-palm photo. ${hint}`,
    'Emit evidence-only JSON matching the schema.',
    'No interpretation. No personal context.',
  ].join(' ');
}