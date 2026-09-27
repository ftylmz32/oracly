/// Yıldızname Narrative V1 version + bound constants.
///
/// Phase 8C.2c parity audit: every ceiling below is classified against the
/// frozen backend contract (`backend/src/ai/narrative-yildizname-limits.ts`,
/// candidate `169c514a`) in
/// `docs/product/yildizname/YILDIZNAME_PHASE8C2C_CONTRACT_PARITY.md`. Ceilings
/// the client actually enforces on the wire (outgoing request or incoming
/// result) are set to agree with the backend exactly, never looser in a way
/// that could send something the backend rejects, and never stricter in a
/// way that could reject a genuine backend response.
library;

const int kYildiznameNarrativeVersion = 1;
const int kYildiznameSerializerVersion = 1;
const int kYildiznameContractVersion = 1;
const int kYildiznameResultContractVersion = 1;

const String kYildiznamePolicyVersion = 'yildizname_policy_v1';
const String kYildiznameNarrativeMode = 'natal_narrative_v1';

/// WIRE — matches backend `maxThemes` exactly; enforced while building the
/// outgoing request (`YildiznameRequestExtras.themes`).
const int kYildiznameMaxThemes = 3;

/// UNUSED — never enforced. The natural ceiling (10 `NatalBody` values) is
/// already backend's `maxPlacements` (10); this constant is stale (12) but
/// harmless since nothing reads it. See the parity doc.
const int kYildiznameMaxPlacements = 12;

/// UNUSED — never enforced. The whole-sign house system always yields
/// exactly 12 houses, matching backend's `maxHouses` (12) structurally.
const int kYildiznameMaxHouses = 12;

/// UNUSED — never enforced. The engine can produce at most C(10,2) = 45
/// aspects, always within backend's `maxAspects` (48). This constant is
/// stale (40, i.e. below the natural maximum) but harmless since nothing
/// reads it. See the parity doc.
const int kYildiznameMaxAspects = 40;

/// UNUSED — never enforced. Only Ascendant + Midheaven exist, matching
/// backend's `maxAngles` (2) structurally.
const int kYildiznameMaxAngles = 2;

/// RESULT PARSER ceiling on incoming `sections`. In practice this raw count
/// check is dead slack: the parser separately rejects a DUPLICATE section
/// kind, and only 10 kinds exist, so no response can ever have more than 10
/// distinct sections regardless of this number. Kept looser than backend's
/// `maxSections` (10) so it can never be the reason a valid response is
/// rejected; tightening it to 10 would add no safety.
const int kYildiznameMaxSections = 12;

/// Per-block ref-count ceilings. Backend enforces `factRefs` and `themeRefs`
/// SEPARATELY (`maxFactRefsPerBlock` / `maxThemeRefsPerBlock`); the client
/// used to collapse both into one shared ceiling (16), which happened to be
/// safe only because it was looser than both — replaced with the exact
/// per-list backend values so the two can never silently disagree.
const int kYildiznameMaxFactRefsPerBlock = 12;
const int kYildiznameMaxThemeRefsPerBlock = 3;

/// RESULT PARSER ceilings — match backend `summary` / `section` / `closing`
/// exactly (1200 / 1600 / 600). Raised from stricter client-only values
/// (900 / 1400 / 500) found in the Phase 8C.2c parity audit: those could
/// have rejected a genuine, backend-accepted response purely for being
/// longer than the client's accidental ceiling.
const int kYildiznameMaxSummaryChars = 1200;
const int kYildiznameMaxSectionChars = 1600;
const int kYildiznameMaxClosingChars = 600;

/// RESULT PARSER ceiling on `reflectionPrompt` — already matches backend's
/// `reflectionPrompt` (400) exactly.
const int kYildiznameMaxReflectionChars = 400;

/// QUALITY POLICY, not a backend mirror: the frozen backend only requires
/// non-empty prose (`nonEmpty`/`nullable` trim-and-check, effectively a
/// minimum of 1 character). These floors reject suspiciously short prose as
/// a deliberate client quality gate and must not be loosened to match
/// backend's bare technical minimum.
const int kYildiznameMinSummaryChars = 40;
const int kYildiznameMinSectionChars = 40;

/// QUALITY POLICY, not a backend mirror: the client trims outgoing discovery
/// labels to 64 chars before they ever reach the request, well under
/// backend's `maxLabelChars` (120). Being stricter here is a deliberate,
/// safe-direction choice (labels come from local device history) — it can
/// never cause the backend to reject a request.
const int kYildiznameMaxThemeLabelChars = 64;

/// Ref STRING length ceilings. Backend distinguishes `maxFactRefChars` (80)
/// from `maxThemeRefChars` (64); the client used to check both kinds of ref
/// against one shared, accidentally-stricter value (72), which could have
/// rejected a genuine backend factRef between 73 and 80 characters (no real
/// factRef ever approaches that length — see the parity doc — but the
/// ceiling itself must still agree).
const int kYildiznameMaxFactRefChars = 80;
const int kYildiznameMaxThemeRefChars = 64;

const int kYildiznameMaxLanguageCodeChars = 8;

const Set<String> kYildiznameLocales = {'tr', 'en', 'ru'};
