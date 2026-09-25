# YILDIZNAME Phase 7 — Result Architecture

**Status:** FROZEN (contract only — no production model in 7A)  
**Canonical owner:** `StarMapReferenceResultScreen`  
**Adapter today:** `YildiznameArtifactPresentation` → same owner

---

## One owner rule

Do **not** create parallel:

- Narrative result screen  
- Artifact result screen  
- FullNatal result screen  

with competing chrome.

Typed presentation state drives one result architecture.

---

## Future presentation model (conceptual — implement 7B)

```
YildiznameResultPresentation
  source          // legacyLive | legacyArtifact | narrativeLive | narrativeArtifact
  scope           // legacy | reduced | full  (UI enum — never wire fidelity strings)
  fidelity        // internal only; mapped to disclosure copy
  isHistoricalArtifact
  createdAtUtc?
  title
  scopeDisclosure // localized human sentence
  factSnapshot    // compact verified facts from request/evidence — never prose
  narrativeSummary
  sections[]      // localized chrome titles + stored prose bodies
  reflection?
  closing?
  recurrenceEvidence?  // absent → omit section
  actions         // or / share / favorite / continue availability
```

### Fact snapshot contract

| Mode | Source |
|------|--------|
| Narrative artifact reopen | Stored safe **request** snapshot on the artifact |
| Narrative live (Phase 8) | The **same request** that produced the accepted result |
| Legacy | Symbolic sun-sign / catalogue material only — never fake natal facts |

Never derive visual fact text from narrative prose.  
Never recalculate astronomy for reopen goldens or reopen UI.

### Immutability

Chrome may localize. Stored prose + stored fact values + stored result locale MUST NOT change.

Cross-locale: TR body under EN chrome is valid; layout must not fail.

---

## Section visual treatment (target)

| Block | Treatment |
|-------|-----------|
| Summary | Dominant hero narrative — strongest type hierarchy |
| Chapters | Reading lanes / archive separators — not 10 bordered glass cards |
| Memory | One restrained archive echo when present |
| Reflection | Quiet question (`ChamberRitualInvite` / `ChamberStoryPanel` if suitable) |
| Closing | Epilogue — lighter than summary |
| Facts | Compact plate / secondary group — never dashboard |

---

## Scope × depth matrix

| | Legacy | Reduced | Full |
|--|--------|---------|------|
| Disclosure | symbolic by birth date | valid limited scope | calculated natal |
| Asc / houses / MC | absent | absent (no fake slots) | available |
| Degrees | none | none | structured only |
| Visual weight | lightest | complete-within-scope | richest facts, narrative still dominant |

---

## Live generation readiness

Phase 8 will wire live Narrative V1.  
Phase 7 architecture must accept **live accepted result** before artifact reopen  
using the same `YildiznameResultPresentation` shape.

---

## Loading / error

`StarMapLoadingCinema` / `StarMapErrorState` exist but are currently **unused**.  
Future: cinematic quiet states — never fake successful narrative chrome on failure.

---

## Hub status (future adapter)

`StarMapReferenceStatus` today is binary `hasBirthInfo`.  
Future should express: missing date · missing time knowledge · missing place · reduced-ready · full-ready  
without a second visual language. Implement after 7A.

---

## Subphase plan

| Phase | Focus |
|-------|--------|
| **7A** | Forensic baseline · contract · golden harness (this doc set) |
| **7B** | Presentation model · scope disclosure chrome · localized section titles |
| **7C** | Natal fact visual layer (priority matrix) |
| **7D** | Narrative hierarchy · chapters · memory |
| **7E** | Live/artifact parity · footer/actions |
| **7F** | Responsive / a11y polish |
| **7G** | Golden masters refresh + hash freeze |
| **7H** | Final visual audit / freeze |

---

## Known production blockers (do not fix in 7A)

1. Raw titles: `summary` · enum `.name` · `reflection` · `closing`  
2. No scope/fidelity disclosure on result despite artifact fields  
3. Flat section list — no hierarchy beyond first-as-hero  
4. Footer order: share → OR → favorite (target: OR → share → favorite)  
5. Loading/error cinema unused  
6. Hub status cannot express evidence tiers  
