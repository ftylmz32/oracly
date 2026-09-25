# Tarot Phase 7 — Implementation Slices

**Parent:** `TAROT_PHASE7A_VISUAL_FORENSIC_BASELINE.md` · Visual contract: `TAROT_PHASE7_VISUAL_CONTRACT.md`  
**Phase 6:** FROZEN — do not reopen Narrative/model/billing/routing.  
**Crossroads:** internal geometry OK · picker/live FALSE through Phase 7.

---

## 7B — Shared Tarot visual primitives / chrome consolidation

**GOAL:** One live chrome path; mark/quarantine dead home/reveal stacks without deleting art.  
**PRODUCTION SCOPE:** Tokens alignment · table background · deprecate unused imports to dead home/glass where safe · no Narrative files.  
**TEST SCOPE:** Visual harness · geometry firewall · existing ritual presentation.  
**ROLLBACK:** Revert chrome-only PR.

---

## 7C — Spread geometry system

**GOAL:** Visual geometry for Classical 1/3/5 (+ seven/celtic layouts as needed) and internal Crossroads `fiveDecision`.  
**PRODUCTION SCOPE:** Geometry painters / table slot layout · **not** picker lists · **not** live gate.  
**TEST SCOPE:** Geometry contract · structural captures for reveal layouts.  
**ROLLBACK:** Geometry-only revert; Crossroads stays hidden.

---

## 7D — Ritual / table / reveal visual system

**GOAL:** Coherent deck-ready → shuffle → draw → flight → settle language; 60 FPS budget.  
**PRODUCTION SCOPE:** `TarotTableScene` stack · ritual cards · flight actor · reduce blur/particle load on low-end.  
**TEST SCOPE:** Ritual presentation/interaction · reveal · deck-ready reliability.  
**ROLLBACK:** Ritual visual PR only.

---

## 7E — Narrative Result UI

**GOAL:** Make spread-level Narrative the obvious primary body; demote life-area dashboard residue; prepare slots for evidenced relationships/memory without fabricating.  
**PRODUCTION SCOPE:** `ReadingPremium*` / footer / story strip — **UI only**; no Result Contract / serializer / bridge semantic changes.  
**TEST SCOPE:** Result experience · long-text viewport · visual baselines K–P · Phase 6 firewall smoke.  
**ROLLBACK:** Result UI revert; Narrative data path untouched.

---

## 7F — History / detail consistency

**GOAL:** History list/detail match reading identity; clarify Crossroads filter/icon debt without exposing picker.  
**PRODUCTION SCOPE:** History screens/mappers · card detail if re-wired.  
**TEST SCOPE:** History UX · visual reopen smoke.  
**ROLLBACK:** History-only.

---

## 7G — Golden master completion

**GOAL:** Expand settled goldens for table/reveal/result states; document pixel vs structural policy.  
**PRODUCTION SCOPE:** Prefer **none**; test/docs + optional reference screens if needed (authorize separately).  
**TEST SCOPE:** Full `test/visual/tarot/` · capture pipeline.  
**ROLLBACK:** Delete new goldens / tests.

---

## 7H — Final Phase 7 visual audit

**GOAL:** Independent freeze of Tarot visual system before Phase 8 E2E.  
**PRODUCTION SCOPE:** Docs only unless FAIL → 7H.1 remediation.  
**TEST SCOPE:** Full Flutter + visual suites + Phase 6 firewall.  
**ROLLBACK:** N/A (audit).

---

## Dependency order

```
7A (done) → 7B → 7C → 7D
                ↘ 7E → 7F → 7G → 7H
```

7E may start after 7B (does not require 7D completion) if strip geometry stubs exist; prefer 7C before shipping Signature strip layouts.

---

## Hard freezes for every slice

- No Narrative Evidence / serializer / Result Contract / provider / Sol writer / retry / cache / billing / safety / live routing changes  
- Crossroads `offeredInLivePicker=false` · live gate excludes Crossroads  
- No merge · no `release/ios-1.0` · 0 real provider calls  
