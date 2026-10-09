# Coffee C3.1 — Fixed Public Corpus Qualification (QA only)

- Date: 2026-10-09
- Branch: `fix/coffee-c21-private-meaning-handoff-20261006`
- Head: `919dd061b1eaaa3dee0df0846680c9229cf4bb51`
- Production code changed: **no**. Provider calls: **0**.
- Machine-readable manifest: `coffee-c31-fixed-public-corpus-20261009.json`
- **No third-party image bytes are stored in this repository.** Images were inspected outside the repo for research only. This file records source identity, locators and factual annotations.

## Verdict: **OUTCOME B**

Real cups hold several distinct physical structures. The current symbol-only M1 maps none of them.

| | Result |
|---|---|
| Sets attempted / qualified | 5 / 5 (Grade A: 2, Grade B: 3, rejected: 0) |
| Median physical structures in the cup | **3 strict / 6 liberal** |
| Cross-view identities | 8 confirmed, 8 ambiguous |
| Current-M1 strong sign groups | **0** (5 ambiguous, pareidolia-dependent candidates) |
| Unmapped structures | 22 (18 cup + 4 saucer) |
| Sets with 3+ current-M1 developments | **0/5** |
| Observer physical density | **CONFIRMED** |
| Current M1 | **TOO SYMBOL-NARROW** |

## Method

1. Physical structures come first. A structure counts on its own only when it has a defensible visual boundary.
   - **Strict:** bounded structures only.
   - **Liberal:** also counts sub-structures, faint smears and speckle fields.
2. Cross-view identity is graded per structure as CERTAIN, POSSIBLE or NOT_VISIBLE. Clock angles are not invented where the handle is missing.
3. Current-M1 mapping comes last. A structure maps only on a **strong** resemblance to one of the ten current sign classes. Pareidolia-dependent readings are recorded as ambiguous.
4. Band, form and relation words follow the current V3 contract.

## Corpus

| Set | Source | Views (useful) | Saucer | Same cup | Grade | Handle anchor | Strict / liberal | Cross-view certain / possible |
|---|---|---|---|---|---|---|---|---|
| C3F-RITAG | Fiverr gig by Ritag777 (6-panel labeled collage) | 6 (6) | yes | high | **A** | strong | 4 / 6 | 2 / 2 |
| C3F-GAZETA | Gazeta.Ru, 5 Nov 2023 (in-article photo) | 3 (3) | no | high | **A** | strong | 3 / 6 | 2 / 1 |
| C3F-HALIL | X, HalilMrT4Real, status 1926964738249925079 | 4 (4) | no | high | **B** | partial | 5 / 8 | 2 / 3 |
| C3F-BASAK | Wikimedia Commons, "Kahve falı 1/2" (CC0) | 2 (1) | yes | high | **B** | partial | 3 / 5 | 0 / 1 |
| C3F-UNAL | LinkedIn, "Kahve falımdan ne çıktı ?" (31 Jul 2025) | 3 (2) | yes | high | **B** | strong | 3 / 5 | 2 / 1 |

**Why each is the same cup:**

- **RITAG:** identical square Greek-key saucer and identical residue in all six labeled panels; handle visible in every panel.
- **GAZETA:** same floral exterior and same ring-stained napkin in panels 1 and 3, and the same residue mass in all three panels.
- **HALIL:** one distinctive slanted dry patch appears in all four panels.
- **BASAK:** same uploader and camera, two minutes apart; the porcelain pattern matches the saucer.
- **UNAL:** the article describes this capture protocol (one photo from each handle side plus the saucer, all for one reading).

**Excluded material:**

- the Gazeta lead image, which is an illustration
- the author's own interpretation in the UNAL article, which is not used as evidence

## Physical structure maps (cup)

**RITAG**

- P1: base pool (CERTAIN)
- P2: streaky band climbing from the pool to the rim; continuation of P1 (POSSIBLE)
- P3: feathered branching field on the opposite wall (POSSIBLE)
- P4: clear crescent area contained by P1 (CERTAIN)

**HALIL**

- P1: slanted oval dry patch (CERTAIN, 4/4 panels)
- P2, P3: rim clump groups (POSSIBLE)
- P4: wet trail from rim to base, connected to P5 (POSSIBLE)
- P5: curved base pool / crescent band (CERTAIN)

**GAZETA**

- P1: large upper network with enclosed clear islands (CERTAIN)
- P2: dark base pool, connected to P1 (CERTAIN)
- P3: lower band separated from P1 by a clear gap (POSSIBLE)

**BASAK**

- P1: upper streak web (POSSIBLE)
- P2: mid-wall blob
- P3: flooded base pool
- Saucer S1: crescent band with a tail

**UNAL**

- P1: speckled base pool (CERTAIN)
- P2: continuous rim stain band (CERTAIN)
- P3: far-wall drip connected to P2 (POSSIBLE)
- Saucer S1–S3: a loop band enclosing a clear area, a dark inner bar, drip tails to the edge

## V3 observations from real material

- **The handle-relative angle check correctly refuses unsound merges.** In GAZETA and in RITAG panels 2/3, the photographed geometry (perspective, a handle that switches sides, possible mirroring) can't be reconciled. V3 keeps those merges as `possible_same_mark`, which is the intended fail-safe.
- **Segmentation uncertainty is real.** Liberal counts are about twice the strict counts. An observer prompt must keep connected networks as one structure unless a boundary is visible.

## Structural motif frequency (5 accepted sets)

| Motif (neutral) | Sets |
|---|---|
| continuous / drip trail | 5/5 |
| connected continuation between structures | 5/5 |
| base pool | 5/5 |
| enclosed / open clear area | 4/5 |
| arc / partial ring band | 4/5 |
| clustered speckles | 4/5 |
| straight / bending line | 4/5 |
| branching network | 3/5 |
| isolated patch / blob | 3/5 |

Current M1 attaches form, placement and relations only to a recognized object sign. With no strong object resemblance, **all of this material is dropped**.

## Current-M1 mapping

- **Strong sign groups:** 0.
- **Ambiguous candidates (not accepted):**
  - RITAG P2 and HALIL P4: band or trail as direction/path
  - HALIL P1: as fish
  - GAZETA P1: as a face (pareidolia)
  - UNAL S1: a residue loop read as a ring object (lexical hazard)
- **Developments per set:** 0 in all five.

## Decision

**OUTCOME B.** The evidence does **not** call for adding many more object symbols. It calls for a curated **structure-first semantic lane** in M1, covering the recurring real motifs: trails and continuations, clear and enclosed areas, arcs and bands, branching networks, speckle clusters, and the base pool. That lane would be deterministic and placement-aware, with fortune meanings designed to the same no-fabrication standard as the current sign grammar.

## Caveats

- Five sets is a small corpus. The outcome is a direction, not a statistic.
- Collage panels limit handle-anchored angle validation.
- Strict and liberal counts bracket the segmentation uncertainty.
