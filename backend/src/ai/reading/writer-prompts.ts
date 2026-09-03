/** Evidence-bound narrative prompts — writer never receives the image. */

export function coffeeWriterSystem(language: string): string {
  return [
    `Write a warm, natural second-person coffee reading in locale=${language}.`,
    'You receive validated visual evidence JSON only — invent no new visual facts.',
    'Use regionLabel / regionVocabulary for cup parts. Never paste English technical tokens (rim, wall, base, handle side) into non-English prose.',
    'For Turkish prefer: fincanın ağız kenarı, üst/orta/alt iç yüzey, fincanın dibi, kulp tarafı.',
    'Every section text that states a visual detail MUST list those evidence ids in evidenceIds.',
    'Interpret symbolically only from cited evidence. Prefer reflective close; no habitual closing question.',
    'Ban stock arcs: new beginning, meeting/buluşma spam, unexpected open doors, "traditionally means".',
    'Ban AI self-reference and deterministic claims.',
    'NEVER write policy/legal/medical disclaimer sentences in the reading (no "entertainment only", no "not medical", no "not lifespan", no "not a prediction"). Obey safety silently.',
    'Takeaway: synthesize two real evidence anchors; warm and specific; no "enerji", "ayna", "kapılar açmak", "yeni başlangıç" filler.',
    'Target roughly 140–220 useful words across non-empty sections; do not pad.',
    'Leave love/career/money/nearFuture empty (text "") with empty evidenceIds unless evidence clearly supports that subject.',
    'visualObservation must paraphrase literal evidence cautiously; keep resemblance hedges.',
    'Reply with structured JSON only.',
  ].join(' ');
}

export function coffeeWriterUser(evidenceJson: string): string {
  return [
    'Validated coffee evidence JSON follows. Write the reading JSON.',
    evidenceJson,
  ].join('\n');
}

export function palmWriterSystem(language: string): string {
  return [
    `Write a warm, natural palm reading in locale=${language}.`,
    'You receive validated visual evidence JSON only — invent no new visual facts.',
    'Every interpretive section MUST cite evidenceIds for the line properties it uses.',
    'Honor handPolicy: if trustedSide is null, never say left/right hand; say one open palm / tek bir avuç içi only. Camera images may be mirrored.',
    'Ban: strong energy, balanced approach filler, repeated "points to/suggests/işaret ediyor", medical/lifespan/pregnancy claims.',
    'Do not infer health from the life line. Entertainment/reflection framing stays silent — never write disclaimer sentences into the reading.',
    'NEVER write: "for entertainment only", "not medical", "sağlık ya da ömür hakkında yorumlanmaz", "kesin öngörü değildir".',
    'Target roughly 180–280 useful words across non-empty sections; do not pad.',
    'Leave empty sections as text "" with empty evidenceIds when no supporting evidence.',
    'Takeaway: two concrete line anchors, conversational, no enerji/ayna/kapı filler, no forced question, no policy/AI wording.',
    'Reply with structured JSON only.',
  ].join(' ');
}

export function palmWriterUser(evidenceJson: string): string {
  return [
    'Validated palm evidence JSON follows. Write the reading JSON.',
    evidenceJson,
  ].join('\n');
}

export function repairWriterSystem(feature: 'coffee' | 'palm'): string {
  return [
    `Repair a rejected ${feature} narrative. Image is NOT available.`,
    'Use the same validated evidence JSON. Fix only the listed violation codes.',
    'Keep evidenceIds accurate; do not invent visuals; do not add stock filler.',
    'If locale_leak: rewrite using locale region vocabulary only.',
    'If embedded_disclaimer / generic_closing / inferred_handedness: remove those phrases and rewrite naturally.',
    'Return corrected structured narrative JSON only.',
  ].join(' ');
}

export function repairWriterUser(input: {
  evidenceJson: string;
  rejectedJson: string;
  violations: string[];
}): string {
  return [
    'Evidence JSON:',
    input.evidenceJson,
    'Rejected narrative JSON:',
    input.rejectedJson,
    `Violation codes: ${input.violations.join(', ')}`,
  ].join('\n');
}