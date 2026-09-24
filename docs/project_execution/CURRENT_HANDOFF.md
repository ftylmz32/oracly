# CURRENT HANDOFF

**Living state — factual only**
**Updated:** 2026-09-25 — Tarot Phase 6F Classical Narrative V2 live cutover · pending independent verification

---

## How to read SHAs in this document

Do **not** treat this file as a live pointer to the branch tip.

| Concept | Value | Meaning |
|---|---|---|
| Canonical branch | `fix/final-product-remediation-20260922` | Active remediation branch |
| Active worktree | `D:/oracly_final_r1` | Where remediation docs/code land |
| Last verified **application/code** baseline (pre-3A) | `173d75228248baf32ea0d4f04fe936665efff342` | R2.1 — prior Flutter-verified code tip (3627/0/15/0) |
| Phase 3A end | `200a3a874fcce763cfdeb2299cfd7177dcb03290` | Major Narrative foundation |
| Phase 3B1 end | `66e814ebac1e84ea6ee556030d8f7af93be7daed` | Wands complete (docs tip) |
| Phase 3B2 end | `c30c3005c11f1e4e52c8612cf9a65828d72a9388` | Cups complete |
| Phase 3B3 task start | `c30c3005c11f1e4e52c8612cf9a65828d72a9388` | Swords start |
| Phase 3B3 end | `427b76bbebdc9a7f161869b9ac66e7c151fa5c95` | Swords profiles commit |
| Phase 3B3.1 end | `2c5c6aa637ed5b5d9407f8e913d18fea543cd839` | Handoff project-memory restoration |
| Phase 3B4 task start | `2c5c6aa637ed5b5d9407f8e913d18fea543cd839` | Pentacles start |
| Phase 3B4 end (profiles) | `c2b5a6d8fa54fe17ba8c000b536d5e3f5a689f01` | 78/78 semantic catalog |
| Phase 3C task start | `c2b5a6d8fa54fe17ba8c000b536d5e3f5a689f01` | Cross-deck red-team |
| Phase 3C end (audit) | `05c485656fd890fdaf20eaaa4db7de221c390fab` | RT-M02/M01/M03 documented |
| Phase 3C.1 task start | `05c485656fd890fdaf20eaaa4db7de221c390fab` | RT-M02 remediation |
| Phase 3C.1 end | `b03fac88ed45948d779ea208fd1536d7b39c3223` | RT-M02 resolved |
| Phase 3C.2 task start | `b03fac88ed45948d779ea208fd1536d7b39c3223` | RT-M01 Cups 09/10 |
| Phase 3C.2 end | `776f040778ed61a94cead565b60016f5c8dc0e61` | RT-M01 resolved |
| Phase 3C.3A task start | `776f040778ed61a94cead565b60016f5c8dc0e61` | RT-M03 part 1 (core/desire/shadow) |
| Phase 3C.3A end | `8e6eedb6cbae693a236c1273725d75fcec63937f` | RT-M03 part 1 diversity gates |
| Phase 3C.3A.1 task start | `8e6eedb6cbae693a236c1273725d75fcec63937f` | RT-M03A naturalness repair |
| Phase 3C.3B task start | `71c2b528c11bd74af51d2aedade45cc99d32093b` | RT-M03 interaction semantics (part 2) |
| Phase 3C.3B end | `b7180fc6498456c3badc063dff207497aef47087` | RT-M03 remediated pending 3C.4 |
| Phase 3C.4 task start | `b7180fc6498456c3badc063dff207497aef47087` | Final 78-card independent re-audit |
| Phase 3C.4 end | `582a2fd88c386bb64746b549950a22fd6ab04557` | Final re-audit docs tip |
| Phase 3C.5A task start | `582a2fd88c386bb64746b549950a22fd6ab04557` | FR-B01 Magician desire EN |
| Phase 3C.5A end | `05aa15cca2d1b6fd00ce0d773f3656cb8ee5dbb4` | FR-B01 Magician desire RESOLVED |
| Phase 3C.5B task start | `05aa15cca2d1b6fd00ce0d773f3656cb8ee5dbb4` | FR-M03 shadow vs reversed |
| Phase 3C.5B end | `4b1c7aecc8b9a77a0452a4a318ccb509b00d4c75` | FR-M03 + RT-M02 RESOLVED |
| Phase 3C.5C task start | `4b1c7aecc8b9a77a0452a4a318ccb509b00d4c75` | FR-M01 / FR-M02 EN naturalness |
| Phase 3C.5C end | `bc9ff060801d941c16ed32b32d8708177fa20c21` | FR-M01/M02 RESOLVED; FR-M04 still OPEN |
| Phase 3C.5D task start | `bc9ff060801d941c16ed32b32d8708177fa20c21` | FR-M04 keyword ontology design |
| Phase 3C.5D end | `9b7086cc92709abe3d3aea11f1f6ee3b6ab34b8b` | Ontology design complete; FR-M04 OPEN |
| Phase 3C.5D.1 task start | `9b7086cc92709abe3d3aea11f1f6ee3b6ab34b8b` | FR-M04 semantic mapping repair |
| Phase 3C.5D.1 end | `a0dbee280b0931469780ad5fbf567343397a80b5` | Ontology plan semantic repair |
| Phase 3C.5E task start | `a0dbee280b0931469780ad5fbf567343397a80b5` | FR-M04 ontology implementation |
| Phase 3C.5E end | `dca0cc197b7ea02f1715431de5edbfc655bc48a6` | Keyword ontology implemented |
| Phase 3C.5F task start | `dca0cc197b7ea02f1715431de5edbfc655bc48a6` | Final ontology + readiness audit |
| Phase 3C.5F end | `e90a5109bbb75ce2c1247be686c9a149aa554846` | Deck ready YES; FR-M04 RESOLVED |
| Phase 3D.0 task start | `e90a5109bbb75ce2c1247be686c9a149aa554846` | Evidence Engine implementation spec |
| Phase 3D.0 end | `18cfeea804cc415a8d064e2a3f9d89c611c8cb4d` | Spec READY; open decisions 0 |
| Phase 3D.0.1 task start | `18cfeea804cc415a8d064e2a3f9d89c611c8cb4d` | Spec contract hardening |
| Phase 3D.0.1 end | `379b68c0761443e641f4a8aa81c382fda0352fa4` | Spread catalog + slice LOCKED |
| Phase 3D.1A task start | `379b68c0761443e641f4a8aa81c382fda0352fa4` | Evidence domain foundation |
| Phase 3D.1A end | `620dae768d104f7ed9b8368c6b2831cec55508c3` | Evidence domain foundation |
| Phase 3D.1B task start | `620dae768d104f7ed9b8368c6b2831cec55508c3` | Structured semantic signal layer |
| Phase 3D.1B end | `9a20151986581d7ffcdb086112c3b4b802fde770` | Semantic signals |
| Phase 3D.1B.1 task start | `9a20151986581d7ffcdb086112c3b4b802fde770` | Relationship scoring calibration |
| Phase 3D.1B.1 end | `fc61bccc65f1bd523dbc3d753c5b74136586dcae` | Scoring calibration |
| Phase 3D.1B.2 task start | `fc61bccc65f1bd523dbc3d753c5b74136586dcae` | Admission consistency repair |
| Phase 3D.1B.2 end | `9d7b388e2ae3ec16a9c2b0ba5e72f6802c98b890` | Admission consistency repair |
| Phase 3D.1C task start | `9d7b388e2ae3ec16a9c2b0ba5e72f6802c98b890` | Deterministic relationship scorer + selector |
| Phase 3D.1C end | `bd5c9dcb9eabfa199eef737a66365a64c9d7b9bf` | Relationship scorer + selector |
| Phase 3D.1C.1 task start | `bd5c9dcb9eabfa199eef737a66365a64c9d7b9bf` | Selector admission/bounds/court-guard hardening |
| Phase 3D.1C.1 end | `1e1abc0bdbf9525893b46bb213db0627cb39e1c5` | Admission + bounds + FR minor-only |
| Phase 3D.1D task start | `1e1abc0bdbf9525893b46bb213db0627cb39e1c5` | Full NarrativeEvidenceBuilder + frozen corpus |
| Phase 3D.1D end | `dfba28d1c724a7d0c60aef56575b98186698d5d4` | Builder + frozen real-deck corpus |
| Phase 3D.1D.1 task start | `ea6bd1230cb900f46b42d1793db3e21da7476833` | Builder error-contract + corpus metric hardening |
| Phase 3D.1D.1 end | `c6503a24ff745958ad51fa6f1ff04a8c78136781` | Validation order + corpus metric lock |
| Phase 3D.1E task start | `6b90f59b9c3827a9ddf38c9237b2c56bf2a931e2` | Final independent Evidence Engine audit |
| Phase 3D.1E end | `8434b26e4bdc021b83ea2ae486db53c4204afa75` | Final audit PASS · ready to freeze YES |
| Phase 4.0 task start | `bfa64996d4934c0fe28c709376280a320fd570e1` | Memory + historical recurrence forensic/spec |
| Phase 4.0 end | `98dd2f98d6105343876566d0c5bace9481a2be5b` | Spec PASS · production NOT IMPLEMENTED |
| Phase 4A task start | `98dd2f98d6105343876566d0c5bace9481a2be5b` | Normalized history + card recurrence pure |
| Phase 4A end | `5d5cbd6e781800547dec933a06caf8a2c6e3c20b` | Card recurrence pure PASS |
| Phase 4A.1 task start | `5d5cbd6e781800547dec933a06caf8a2c6e3c20b` | Identity + generic-topic + short-alias harden |
| Phase 4A.1 end | `9985527c1b28ae05caec2efddaa0b0fd01a84be5` | Hardening PASS |
| Phase 4B task start | `9985527c1b28ae05caec2efddaa0b0fd01a84be5` | Theme + memory pure engines |
| Phase 4B end | `7cad2866dd22c0f8f684c530d6d82d90ede5b007` | Theme + memory pure PASS |
| Phase 4C task start | `7cad2866dd22c0f8f684c530d6d82d90ede5b007` | Storage adapters + owner/delete integrity |
| Phase 4C end | `2d9ef3b374221d2d0317ee80c1165d726bdd28e4` | Adapters + delete PASS |
| Phase 4C.1 task start | `2d9ef3b374221d2d0317ee80c1165d726bdd28e4` | Owner-safe live ids + typed delete + grounding |
| Phase 4C.1 end | `dac943f11bf4c1a8ea3a53b3c67a10df043e3dc4` | H14–H16 PASS |
| Phase 4C.2 task start | `dac943f11bf4c1a8ea3a53b3c67a10df043e3dc4` | Strict live Tarot source aliases |
| Phase 4C.2 end | `4ff9441be9a8b508a38cc0dcaf1eed52c1a7a040` | H17 PASS |
| Phase 4D task start | `4ff9441be9a8b508a38cc0dcaf1eed52c1a7a040` | Request enricher + frozen historical corpus |
| Phase 4D end | `55e284a193d994d1f1ffb3a44477104e57e09f7c` | Enricher + corpus PASS |
| Phase 4D.1 task start | `55e284a193d994d1f1ffb3a44477104e57e09f7c` | Privacy contract hardening (H18) |
| Phase 4D.1 end | `40182d177ca3bb895438218f672db06e9fcf88fe` | H18 PASS |
| Phase 4E task start | `40182d177ca3bb895438218f672db06e9fcf88fe` | Independent Memory + Historical Recurrence audit |
| Phase 4E end | `1eb09c2cb343a1d58937aeccff05a35c0b3e2541` | FAIL (H7 MAJOR) |
| Phase 4E.1 task start | `1eb09c2cb343a1d58937aeccff05a35c0b3e2541` | H7 transitive physical-identity remediation |
| Phase 4E.1 end | `6acb2b18f4c3cd29de2ed99e2f78ae688a24f00f` | H7 PASS |
| Phase 4E.1a task start | `6acb2b18f4c3cd29de2ed99e2f78ae688a24f00f` | H19 exact-tie representative determinism |
| Phase 4E.1a end | `32eb74f848cef75ceb0a0f9060c96182145b7ab0` | H19 PASS |
| Phase 4E re-audit start | `32eb74f848cef75ceb0a0f9060c96182145b7ab0` | Final Memory + Historical Recurrence freeze gate |
| Phase 4E re-audit end | `61134c811f9073d466cbc423a17692abaab76612` | Phase 4 FROZEN |
| Phase 5.0 task start | `61134c811f9073d466cbc423a17692abaab76612` | Signature Spreads forensic + architecture lock |
| Phase 5.0 end | `a590da5e39a9c84466237e3decc120f9197735f6` | docs PASS |
| Phase 5.0.1 task start | `a590da5e39a9c84466237e3decc120f9197735f6` | Signature Spread contract hardening |
| Phase 5.0.1 end | `c013dd1de183f1b224a01805f709705e5c3c1137` | docs PASS |
| Phase 5A task start | `c013dd1de183f1b224a01805f709705e5c3c1137` | Pure SignatureSpread domain + launch catalog |
| Phase 5A end | `07d02c099a5ba653d5e07a78b48f2f746c00ebed` | Catalog PASS |
| Phase 5B task start | `07d02c099a5ba653d5e07a78b48f2f746c00ebed` | Signature → SpreadSemanticDefinition projection |
| Phase 5B end | `a590107f1ca184299dea29dc50429b94819febc3` | Projection PASS |
| Phase 5C task start | `a590107f1ca184299dea29dc50429b94819febc3` | Localization + geometry descriptor |
| Phase 5C end | `650ca746df0629a610033432641777caad91325e` | L10n PASS |
| Phase 5D task start | `650ca746df0629a610033432641777caad91325e` | Crossroads runtime + persistence dual-read |
| Phase 5D end | `a417fc7e1e99eaeaa2b0290fcb93c35ac04b629e` | machine-id write · dual-read · picker firewall |
| Phase 5D.1 task start | `a417fc7e1e99eaeaa2b0290fcb93c35ac04b629e` | machine-id UI leak + localized history search |
| Phase 5D.1 end | `185f59dc94264995dc55c7b6c282db6ae9da8683` | display/search remediation PASS |
| Phase 5E task start | `185f59dc94264995dc55c7b6c282db6ae9da8683` | Signature shadow + frozen corpus |
| Phase 5E end | `7e2e6e963caee375e59e1ff956c937d2d18383d8` | shadow + corpus PASS |
| Phase 5F task start | `7e2e6e963caee375e59e1ff956c937d2d18383d8` | Independent final Signature Spreads audit |
| Phase 5F end | `89dd4c526b0d96bb52666b64fa1485ecd3761d65` | audit PASS · Phase 5 FROZEN |
| Phase 5F.1 task start | `89dd4c526b0d96bb52666b64fa1485ecd3761d65` | Post-audit M1/I1/I2 hardening |
| Phase 5F.1 end | `4b56592bc9dc2fea9bb75416851844cc18731891` | hardening PASS |
| Phase 5 independent re-freeze | `4b56592bc9dc2fea9bb75416851844cc18731891` | ChatGPT verified 5F.1 · Phase 5 RE-FROZEN |
| Phase 6.0 task start | `4b56592bc9dc2fea9bb75416851844cc18731891` | Narrative V2 live migration forensic + architecture lock |
| Phase 6.0 end | `7affe63253fe4976d7c99f0071c53cd705755ecf` | architecture lock PASS (docs-only) |
| Phase 6.0.1 task start | `7affe63253fe4976d7c99f0071c53cd705755ecf` | Safety delivery non-billable / non-journal |
| Phase 6.0.1 end | `52e2f0f8056c3005977bdd9c87bd96b4a27d388b` | billing/journal PASS · independent follow-up needed |
| Phase 6.0.2 task start | `52e2f0f8056c3005977bdd9c87bd96b4a27d388b` | Safety purity + recovery auth + delivery copy |
| Phase 6.0.2 end | `b04296c77be79cc4dfee1eb96b809f78646f2234` | B1/M1/M2 PASS · independent follow-up B2/M3 |
| Phase 6.0.3 task start | `b04296c77be79cc4dfee1eb96b809f78646f2234` | Safety preflight before affordability + retry firewall |
| Phase 6.0.3 end | `b82e517edf035f3c80c17b84f53978408a73f078` | independently verified · gate for 6A |
| Phase 6A task start | `b82e517edf035f3c80c17b84f53978408a73f078` | Classical-preserving spread + edge provider seams |
| Phase 6A end | `0fbd5c2cb2fdee1fa474e10979d2e8d9b2177557` | Classical parity PASS · ChatGPT found provider identity defect |
| Phase 6A.1 task start | `0fbd5c2cb2fdee1fa474e10979d2e8d9b2177557` | Provider/spread identity fail-closed hardening |
| Phase 6A.1 end | `37683d9555bc3a08962c244f0fa6e5e07ce1d34c` | independently verified · gate for 6B |
| Phase 6B task start | `37683d9555bc3a08962c244f0fa6e5e07ce1d34c` | Signature history normalization / Crossroads FACT |
| Phase 6B end | `3247443bbe5ee67f80d4f3feee9fc3395d012cc0` | independently verified · follow-up broad catch → 6B.1 |
| Phase 6B.1 task start | `3247443bbe5ee67f80d4f3feee9fc3395d012cc0` | Signature history resolver unexpected-error hardening |
| Phase 6B.1 end | `fc26e0fe50400cb2f80818e5e60b6b4c55a1059b` | independently verified · gate for 6C |
| Phase 6C task start | `fc26e0fe50400cb2f80818e5e60b6b4c55a1059b` | Narrative prompt serializer + SHA-256 cache identity |
| Phase 6C end | `10e63da369b91d608e0c80ada55a9919cc8f89ed` | independently verified · follow-up M1–M5 → 6C.1 |
| Phase 6C.1 task start | `10e63da369b91d608e0c80ada55a9919cc8f89ed` | Prompt structural integrity + version/locale fail-closed |
| Phase 6C.1 end | `11e826fd0f32e9f314bce5be9fd99989ef64d540` | independently verified · follow-up M6–M8 → 6C.2 |
| Phase 6C.2 task start | `11e826fd0f32e9f314bce5be9fd99989ef64d540` | Canonical bounds + scalar integrity + locale fixture |
| Phase 6C.2 end | `b9293d3503e3bf8c74af1780098787b392c551e6` | independently verified · Phase 6C FROZEN |
| Phase 6D task start | `b9293d3503e3bf8c74af1780098787b392c551e6` | Narrative V2 wire + structured result contract |
| Phase 6D end | `c652c22e16b47f7fe0c4ba495e58922f368d939d` | independently verified · follow-up M1–M2 → 6D.1 |
| Phase 6D.1 task start | `c652c22e16b47f7fe0c4ba495e58922f368d939d` | Backend input firewall + full semantic fingerprint |
| `release/ios-1.0` | `1b7151dca954f0cc25f39f815c0dacf0613a1164` | Build 4 — untouched |

**The authoritative current branch tip must always be obtained from `git rev-parse HEAD` / origin branch tracking — not inferred from this document.**

Updating this handoff must **not** trigger recursive commits solely to refresh a “Current HEAD” field.

---

## Repository

| Field | Value |
|---|---|
| Remote | `https://github.com/ftylmz32/oracly.git` (`ftylmz32/oracly`) |
| Active remediation branch | `fix/final-product-remediation-20260922` |
| Active worktree | `D:/oracly_final_r1` |
| Build 4 state | Untouched — `1b7151dc` on `release/ios-1.0` |

Pre-existing local noise (do **not** stage/clean):
`design/runtime/astrology_runtime.png`, generated plugin registrants, possible line-ending dirt on tests, `tool/qa/` helper scripts.

---

## Remediation completed

### R1 — Privacy / Discovery History connected-memory purge

| | |
|---|---|
| Status | **PASS** |
| Commit | `764e7b04bb43c7ae792d51d813d38ceb5dd70b94` |

### R2 — Tarot production fail-closed

| | |
|---|---|
| Status | **PASS** |
| Commit | `6fe6a74f6e1250605198b4ff8c5018d2dcebce6b` |

### R2.1 — Tarot retry-path quality bypass closure

| | |
|---|---|
| Status | **PASS** |
| Commit | `173d75228248baf32ea0d4f04fe936665efff342` |

---

## Tarot product program

| Phase | Status |
|---|---|
| Phase 0 — Forensic baseline | **COMPLETE** (read-only docs) |
| Phase 1 — Narrative product + architecture spec | **COMPLETE** (docs) |
| Phase 1.1 — Architecture contract hardening | **COMPLETE** (docs) |
| Phase 2 — Quality corpus + harness | **COMPLETE** |
| Phase 2.1 — Harness false-positive hardening | **COMPLETE** |
| Phase 3A — Major Arcana Narrative semantic foundation | **COMPLETE** |
| Phase 3B1 — Wands Minor Narrative profiles | **COMPLETE** |
| Phase 3B2 — Cups Minor Narrative profiles | **COMPLETE** |
| Phase 3B3 — Swords Minor Narrative profiles | **COMPLETE** |
| Phase 3B3.1 — CURRENT_HANDOFF project-memory restoration | **COMPLETE** (docs) |
| Phase 3B4 — Pentacles Minor Narrative profiles | **COMPLETE** |
| Phase 3C — 78-card cross-deck semantic red-team | **COMPLETE** (audit) |
| Phase 3C.1 — RT-M02 reversed-orientation remediation | **COMPLETE** |
| Phase 3C.2 — RT-M01 Cups 09/10 relationship distinction | **COMPLETE** |
| Phase 3C.3A — RT-M03 core/desire/shadow template diversification | **COMPLETE** (RT-M03 still OPEN) |
| Phase 3C.3A.1 — RT-M03A naturalness repair | **COMPLETE** (3C.3A naturalness FROZEN; RT-M03 still OPEN) |
| Phase 3C.3B — RT-M03 relationship/decision/action interaction semantics | **COMPLETE** (RT-M03 was pending 3C.4) |
| Phase 3C.4 — Final 78-card cross-deck re-audit | **COMPLETE** (audit PASS; deck readiness **NO**) |
| Phase 3C.5A — FR-B01 Magician desire EN contamination | **COMPLETE** (FR-B01 RESOLVED; readiness still **NO**) |
| Phase 3C.5B — FR-M03 shadow vs reversed court separation | **COMPLETE** (FR-M03 + RT-M02 RESOLVED; readiness still **NO**) |
| Phase 3C.5C — FR-M01 / FR-M02 EN naturalness | **COMPLETE** (FR-M01/M02 + RT-M03 minors-only; readiness still **NO** — FR-M04) |
| Phase 3C.5D — FR-M04 keyword ontology design | **COMPLETE** (design only; FR-M04 **OPEN**; readiness **NO**) |
| Phase 3C.5D.1 — FR-M04 ontology semantic mapping repair | **COMPLETE** (plan repaired; FR-M04 was OPEN) |
| Phase 3C.5E — FR-M04 canonical keyword ontology implementation | **COMPLETE** (FR-M04 was REMEDIATED — PENDING 3C.5F) |
| Phase 3C.5F — final keyword ontology + deck readiness audit | **COMPLETE** (FR-M04 **RESOLVED**; deck readiness **YES**) |
| Phase 3D.0 — Narrative Evidence Engine implementation specification | **COMPLETE** (superseded active contract by 3D.0.1) |
| Phase 3D.0.1 — Evidence Engine spec contract hardening | **COMPLETE** (spread catalog + profile slice LOCKED; OPEN **0**) |
| Phase 3D.1A — Evidence Domain Foundation | **COMPLETE** (models + slice + grounding + classical catalog; scoring **NOT** implemented) |
| Phase 3D.1B — Structured Semantic Signal Layer | **COMPLETE** (channel + DF + contrasts + transforms; scoring **NOT** implemented) |
| Phase 3D.1B.1 — Relationship scoring calibration | **COMPLETE** (docs + diagnostic; production scoring **NOT** implemented; OPEN 3D.1C decisions **0**) |
| Phase 3D.1B.2 — Admission consistency repair | **COMPLETE** (FR-F01+canonical 0.90 → REJECT; thresholds unchanged) |
| Phase 3D.1C — Deterministic Relationship Scorer + Selector | **COMPLETE** (scoring/admission/kinds/ranking/`rel_##`; builder **NOT** implemented) |
| Phase 3D.1C.1 — Selector admission/bounds/court-guard hardening | **COMPLETE** (non-theme requires normalAdmitted; max 12/10; FR minor-only) |
| Phase 3D.1D — Full NarrativeEvidenceBuilder + frozen real-deck corpus | **COMPLETE** (builder + 46 corpus; memory/recurrence empty; user path unchanged) |
| Phase 3D.1D.1 — Builder error-contract + corpus metric hardening | **COMPLETE** (`unknownCanonicalCardId` reachable; reversed scenarios **38**; fixture unchanged) |
| Phase 3D.1E — Final independent Narrative Evidence Engine audit | **COMPLETE** (READY TO FREEZE **YES**; Phase 3 **COMPLETE**; BLOCKER 0 · MAJOR 0) |
| Phase 4.0 — Memory + Historical Recurrence forensic/specification | **COMPLETE** (docs-only; OPEN decisions **0**; production **NOT** implemented) |
| Phase 4A — Normalized historical models + pure card recurrence | **COMPLETE** (pure engines; storage/theme/memory/enricher **NOT**; user path unchanged) |
| Phase 4A.1 — Historical recurrence identity + generic-topic + short-alias hardening | **COMPLETE** |
| Phase 4B — Cross-feature themes + pure memory evidence | **COMPLETE** |
| Phase 4C — Storage adapters + owner/delete integrity | **COMPLETE** |
| Phase 4C.1 — Owner-safe live source identity + typed deletion | **COMPLETE** |
| Phase 4C.2 — Strict live Tarot source aliases | **COMPLETE** |
| Phase 4D — Request enricher + frozen historical corpus | **COMPLETE** |
| Phase 4D.1 — Enrichment privacy contract hardening | **COMPLETE** |
| Phase 4E — Independent Memory + Historical Recurrence audit | **COMPLETE / FAIL** (H7 MAJOR recorded · historical) |
| Phase 4E.1 — H7 transitive physical-identity remediation | **COMPLETE / PASS** |
| Phase 4E.1a — H19 exact-tie representative determinism | **COMPLETE / PASS** |
| Phase 4E re-audit — Final freeze gate | **COMPLETE / PASS** · Phase 4 **FROZEN** |
| Phase 5.0 — Signature Spreads forensic + architecture lock | **COMPLETE / PASS** (docs-only) |
| Phase 5.0.1 — Signature Spread contract hardening | **COMPLETE / PASS** (docs-only · ready for 5A) |
| Phase 5A — Pure SignatureSpread domain + launch catalog | **COMPLETE / PASS** (shadow · Crossroads unreachable · TarotSpreadType unchanged) |
| Phase 5B — Signature semantic projection + Crossroads edges | **COMPLETE / PASS** (shadow · classical parity · Phase 3 scorer does not consume Phase 5 edges) |
| Phase 5C — Signature localization + geometry descriptor | **COMPLETE / PASS** (TR/EN/RU · Crossroads unreachable · live titles unchanged) |
| Phase 5D — Crossroads runtime + persistence dual-read | **COMPLETE / PASS** (enum index 5 · machine-id write · legacy dual-read · picker firewall) |
| Phase 5D.1 — Machine-id UI leak + localized history search | **COMPLETE / PASS** (display/search only · persistence unchanged · Phase 3/4 firewall tests) |
| Phase 5E — Signature shadow integration + frozen corpus | **COMPLETE / PASS** (classical parity · Crossroads structural-only · Phase3/4 blocked · user-path importers 0) |
| Phase 5F — Independent final Signature Spreads audit | **COMPLETE / PASS** · **Phase 5 FROZEN** (pre-5F.1) |
| Phase 5F.1 — Post-audit contract + localization hardening | **COMPLETE / PASS** · independently verified |
| Phase 5 — Signature Spreads | **RE-FROZEN AFTER 5F.1 INDEPENDENT VERIFICATION** at `4b56592bc9dc2fea9bb75416851844cc18731891` |
| Phase 6.0 — Narrative V2 live migration forensic + architecture lock | **COMPLETE / PASS** (docs-only) |
| Phase 6.0.1 — Safety delivery non-billable / non-journal | **COMPLETE / PASS** (billing/journal) · independent review found B1/M1/M2 follow-ups |
| Phase 6.0.2 — Safety purity + recovery authorization | **COMPLETE / PASS** (B1/M1/M2) · independent review found B2/M3 |
| Phase 6.0.3 — Safety preflight + quality retry firewall | **COMPLETE / PASS** (pending independent ChatGPT verification) |
| Runtime Narrative Tarot Engine | **NOT IMPLEMENTED** / **NOT USER-REACHABLE** |
| Tarot Visual System (locked goldens) | **NOT IMPLEMENTED** |

### Phase 3A

| Field | Value |
|---|---|
| Status | **PASS** |
| Major profiles | **22 / 22** |

### Phase 3B1

| Field | Value |
|---|---|
| Status | **PASS** |
| Wands | **14 / 14** |

### Phase 3B2

| Field | Value |
|---|---|
| Status | **PASS** |
| Cups | **14 / 14** |

### Phase 3B3

| Field | Value |
|---|---|
| Status | **PASS** |
| Swords | **14 / 14** |
| V2 profile coverage (then) | **64 / 78** |

### Phase 3B4

| Field | Value |
|---|---|
| Status | **PASS** |
| V2 profile coverage | **78 / 78** |
| Major | **22 / 22** |
| Wands | **14 / 14** |
| Cups | **14 / 14** |
| Swords | **14 / 14** |
| Pentacles | **14 / 14** |
| Full 78-profile catalog | **COMPLETE** (exact set equality with `OraclyTarotDeck.expectedIds`) |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| Canonical deck | Unchanged (78 / 22 / 56) |
| Current Tarot user path | Unmodified |

### Phase 3C

| Field | Value |
|---|---|
| Status | **PASS** (audit complete) |
| Profiles reviewed | **78 / 78** |
| Report | `docs/product/tarot/TAROT_78_PROFILE_RED_TEAM.md` |
| BLOCKER | **0** |
| MAJOR | **3** (RT-M01 cups_09/10 rel · RT-M02 shadow≈reversed · RT-M03 template monotony) |
| MINOR | **6** |
| INFO | **5** |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** (unchanged) |

### Phase 3C.1

| Field | Value |
|---|---|
| Status | **PASS** |
| RT-M02 | **RESOLVED** |
| RT-M01 | **OPEN** |
| RT-M03 | **OPEN** |
| Initial exact shadow↔reversed clones | **19** |
| Initial high-similarity (≥0.75) | **9** |
| Profiles changed | **36** (`reversed.expression` only) |
| Transform assignments changed | **NONE** |
| Final exact clones | **0** |
| Unresolved semantic near-clones | **0** |
| DECK READY FOR EVIDENCE ENGINE | **NO** (RT-M01 + RT-M03 still open) |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

### Phase 3C.2

| Field | Value |
|---|---|
| Status | **PASS** |
| RT-M01 | **RESOLVED** |
| RT-M02 | **RESOLVED** |
| RT-M03 | **OPEN** |
| Fields changed | `cups_09.relationshipDynamic` · `cups_10.relationshipDynamic` |
| Before similarity | **≈ 0.77** |
| After similarity | **0.107** |
| Blind-swap | **NO / NO** |
| DECK READY FOR EVIDENCE ENGINE | **NO** (RT-M03 still open) |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

### Phase 3C.3A

| Field | Value |
|---|---|
| Status | **PASS** (part 1 only; metrics green; naturalness later repaired in 3C.3A.1) |
| Fields in scope | `coreMeaning` · `desire` · `shadow` |
| Profiles touched | **78** |
| coreMeaning changed | **62** (EN) |
| desire changed | **78** (EN) |
| shadow changed | **47** (EN) |
| Top opener share (all target × locales) | **≤ 25%** |
| Replacement monoculture | **NO** (mechanical gate); residual scaffold rotation repaired in **3C.3A.1** |
| Historical EN stems (`It speaks of` / wish / slide) | **62→0** / **78→0** / **47→0** |
| RT-M01 | **RESOLVED** |
| RT-M02 | **RESOLVED** (shadow↔reversed exact clones=0) |
| RT-M03 | **PARTIALLY REMEDIATED / OPEN** (interaction fields not yet remediated) |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

### Phase 3C.3A.1

| Field | Value |
|---|---|
| Status | **PASS** |
| 3C.3A naturalness quality | **FROZEN** |
| Fields changed | EN `coreMeaning` / `desire` / `shadow` only |
| Profiles changed | **77** |
| coreMeaning.en | **44** |
| desire.en | **73** |
| shadow.en | **33** |
| TR/RU fields changed | **NONE** |
| Replacement scaffolds cleared | At the center / meaning turns on / Part of this archetype / At the edge… → **0** |
| Known stilted / fragmentary / template-swap remaining | **0** |
| RT-M01 | **RESOLVED** |
| RT-M02 | **RESOLVED** |
| RT-M03 | **PARTIALLY REMEDIATED / OPEN** |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

### Phase 3C.3B

| Field | Value |
|---|---|
| Status | **PASS** |
| Fields in scope | `relationshipDynamic` · `decisionDynamic` · `actionDirection` |
| Profiles touched | **75 / 78** |
| relationshipDynamic changed | **53** |
| decisionDynamic changed | **74** |
| actionDirection changed | **52** |
| TR/EN/RU field changes | **179 / 179 / 179** |
| Historical EN stems | `the choice` 60→0 · `asks to separate` 39→0 · `in a bond` 52→2 · `do not` 62→5 |
| Self-caught replacement monoculture | "worth telling/keeping apart" / "не то же самое" family peaked ~31% of touched relationship fields mid-pass; corrected to 14.8% via a second rewrite pass on 9 cards |
| High-similarity candidates (Jaccard ≥0.5) | 9→0 |
| `cups_03`/`cups_10` decisionDynamic (RT-m01) | 0.643→0.161, **RESOLVED** |
| `pentacles_13` same-card role redundancy | 0.50→0, **RESOLVED** |
| RT-m05 action clustering | `name` 15.4% share both before/after — **lexical-only, non-semantic** |
| RT-M01 | **RESOLVED** (untouched, regression-tested) |
| RT-M02 | **RESOLVED** (untouched, regression-tested) |
| RT-M03 | **REMEDIATED — PENDING FINAL RE-AUDIT** |
| DECK READY FOR EVIDENCE ENGINE | **NO** — Phase 3C.4 independent re-audit required |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |
| Canonical deck | Unchanged |
| Current Tarot user path | Unmodified |

### Phase 3C.4

| Field | Value |
|---|---|
| Status | **PASS** (audit complete) |
| Report | `docs/product/tarot/TAROT_78_PROFILE_FINAL_REAUDIT.md` |
| Profiles reviewed | **78 / 78** |
| BLOCKER | **1** |
| MAJOR | **4** |
| MINOR | **4** |
| INFO | **4** |
| RT-M01 | **RESOLVED** |
| RT-M02 | **OPEN** |
| RT-M03 | **OPEN** |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |
| Production profiles modified | **NO** |

### Phase 3C.5A

| Field | Value |
|---|---|
| Status | **PASS** |
| FR-B01 | **RESOLVED** |
| Field changed | `major_01.desire.en` only |
| TR / RU changed | **NO** / **NO** |
| CLEAR-DRIFT from FR-B01 | **0** after remediation |
| Canonical fidelity (`major_01`) | **FAITHFUL** |
| FR-M01 | **OPEN** |
| FR-M02 | **OPEN** |
| FR-M03 | **OPEN** |
| FR-M04 | **OPEN** |
| RT-M02 | **OPEN** |
| RT-M03 | **OPEN** |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

### Phase 3C.5B

| Field | Value |
|---|---|
| Status | **PASS** |
| FR-B01 | **RESOLVED** |
| FR-M03 | **RESOLVED** |
| RT-M02 | **RESOLVED** |
| Profiles changed | **5** — `cups_11`, `swords_11`, `swords_13`, `swords_14`, `wands_11` |
| Field changed | `reversed.expression` TR/EN/RU only |
| Transform assignments | **NONE** changed |
| cups_10 / pentacles_10 edited | **NO** |
| Human near-clones in audited FR-M03 scope | **0** |
| Exact shadow↔reversed clones | **0** |
| FR-M01 | **OPEN** |
| FR-M02 | **OPEN** |
| FR-M04 | **OPEN** |
| RT-M03 | **OPEN** |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

### Phase 3C.5C

| Field | Value |
|---|---|
| Status | **PASS** |
| FR-B01 | **RESOLVED** |
| FR-M01 | **RESOLVED** |
| FR-M02 | **RESOLVED** |
| FR-M03 | **RESOLVED** |
| RT-M01 | **RESOLVED** |
| RT-M02 | **RESOLVED** |
| RT-M03 | **RESOLVED — NON-BLOCKING MINORS REMAIN** |
| Profiles changed | `swords_09`, `cups_10` |
| EN fields changed | swords_09: light/desire/upright.expression/reversed.expression · cups_10: coreMeaning/desire/relationshipDynamic |
| TR / RU | **Unchanged** |
| keywordIds | **Unchanged** |
| FR-M04 | **OPEN** |
| DECK READY FOR EVIDENCE ENGINE | **NO** — FR-M04 blocks |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

### Phase 3C.5D

| Field | Value |
|---|---|
| Status | **PASS** (design only) |
| FR-M04 | **OPEN** — implementation pending |
| Ontology plan | `docs/product/tarot/TAROT_KEYWORD_ONTOLOGY_PLAN.md` |
| Current unique / singleton | **397** / **352** (**88.66%**) |
| Proposed lexicon | **124** defined · projected used **118** |
| Projected singleton % | **24.58%** |
| Full 78×orientation mapping | **COMPLETE** |
| Migration table | **COMPLETE** |
| Ambiguous mappings | `envy` (+ review notes) |
| Production keywordIds changed | **NO** |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

### Phase 4E

| Field | Value |
|---|---|
| Status | **COMPLETE** / **FAIL** |
| Audit doc | `docs/product/tarot/NARRATIVE_MEMORY_RECURRENCE_FINAL_AUDIT.md` |
| BLOCKER | **0** |
| MAJOR | **1** — H7 non-transitive physical-identity dedupe double-count |
| MINOR | **2** |
| INFO | **3** |
| Phase 4 frozen | **NO** |
| Proof test | `tarot_4e_h7_chained_alias_red_team_test.dart` (was intentionally failing) |
| Production fixed in 4E | **NO** (audit-only) |

### Phase 4E.1

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** (remediation) |
| H7 fix | **IMPLEMENTED** — transitive alias component collapse (union-find) |
| `samePhysicalIdentity` | **UNCHANGED** (pairwise) |
| Phase 4 frozen | **YES** (via 4E re-audit) |
| Phase 4E status | historical **FAIL** · re-audit **PASS** |

### Phase 4E.1a

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| H19 | **IMPLEMENTED** — sessionId ASC + canonical payload tie-break |
| Primary order | **UNCHANGED** (`occurredAt` DESC, `readingId` ASC) |
| Field merge | **NO** |
| Phase 4 frozen | superseded by re-audit |

### Phase 4E re-audit

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Audit doc | `docs/product/tarot/NARRATIVE_MEMORY_RECURRENCE_FINAL_REAUDIT.md` |
| Original FAIL doc | `NARRATIVE_MEMORY_RECURRENCE_FINAL_AUDIT.md` (historical) |
| BLOCKER / MAJOR | **0** / **0** |
| H1–H19 | **19 / 19 PASS** |
| Original H7 MAJOR | **CLOSED** |
| Phase 4 frozen | **YES** |
| Live Narrative V2 | **NOT WIRED** |
| Runtime engine | **NOT USER-REACHABLE** |

### Phase 5.0

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Type | docs-only forensic + architecture lock |
| Source audit | `docs/product/tarot/SIGNATURE_SPREADS_SOURCE_AUDIT.md` |
| Spec | `docs/product/tarot/SIGNATURE_SPREADS_SPEC.md` |
| Launch set | **4** (Quick Insight · Timeline · Deep Field · Crossroads) |
| Production implemented | **NO** |
| Phase 3/4 modified | **NO** |
| OPEN BLOCKER / MAJOR | **0** / **0** |
| Live Narrative V2 | **NOT WIRED** |

### Phase 5.0.1

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Type | docs-only contract hardening |
| Crossroads roles | option_a/b/direction=`direction` · tension=`challenge` · counsel=`support` |
| Crossroads edges | **4** exact (opp · pressure×2 · supportive) |
| QuestionKinds | decision/open/guidance · relationship **unsupported** |
| Geometry | `SignatureGeometryHook` separate · Phase 3 unmodified |
| Enum append | **deferred to 5D** · 5A must not touch `TarotSpreadType` |
| Sequence | 5A domain → 5B projection → 5C l10n → 5D runtime → 5E shadow → 5F audit |
| OPEN BLOCKER / MAJOR | **0** / **0** |

### Phase 5A

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Package | `lib/features/tarot/signature_spreads/` |
| Catalog count | **4** (Quick Insight · Timeline · Deep Field · Crossroads) |
| Crossroads picker | **false** · `runtimeEnumName` inert |
| `TarotSpreadType` | **UNCHANGED** |
| Phase 3/4 production | **UNCHANGED** |
| Edges / Phase 3 projection | **NOT** in 5A (deferred 5B) |
| Live Narrative V2 | **NOT WIRED** |

### Phase 5B

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Projector | `SignatureSpreadProjector` · classical via `ClassicalSpreadSemantics.bySpreadId` |
| Crossroads edges | **4** Phase-5-owned · **7** projected relation rows |
| Classical parity | single / threeCard / fiveCard · **ZERO** semantic drift |
| Phase 3 global edge table | **UNMODIFIED** |
| Phase 3 scorer consumes Phase 5 edges | **NO** (intentional · audited seam later) |
| Crossroads EvidenceBuilder call | **NO** |
| Live Narrative V2 | **NOT WIRED** |
| Crossroads picker | **false** |
| Next | **Phase 5C** |

### Phase 5C

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Locales | TR · EN · RU complete for all 4 launch definitions |
| Canonical aliases | `threeCard.blurb` / `fiveCard.blurb` · legacy parity PASS |
| Crossroads copy | title · banner · blurb · purpose · 4 labels · 5 guides |
| Geometry | `SignatureGeometryDescriptor` ×4 · Crossroads `decisionBranching=true` |
| Live titles / legacy blurbs | **UNCHANGED** |
| `TarotSpreadType` | **UNCHANGED** |
| Crossroads picker | **false** |
| Next | **Phase 5D** |

### Phase 5D

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Enum | `crossroads` appended at index **5** · existing 0–4 unchanged |
| History write | `session.spread.name` (machine id) |
| Legacy dual-read | TR/EN/RU titles + machine ids |
| Snapshot `positionKey` | persisted on new saves · reconstructed from index |
| Session soft-parse | unknown → null · never fabricates `single` |
| Picker firewall | entry/ritual/table · Crossroads **unreachable** |
| Phase 3/4 | **UNCHANGED** |
| Live Narrative V2 | **NOT WIRED** |
| Next | **Phase 5D.1** (display/search remediation) |

### Phase 5D.1

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Persistence | machine-id write **unchanged** (no rollback) |
| Search | raw `spreadType` **OR** localized `typeLabel` |
| Saved reading | tagline/theme never raw machine id |
| Phase 3/4 production | **UNCHANGED** · firewall tests added |
| Spec | Phase-5-owned edges · history recurrence **NOT LIVE** |
| Crossroads picker | **false** |
| Next | **Phase 5E** |

### Phase 5E

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Shadow evaluator | **IMPLEMENTED** (pure · zero side effects) |
| Shadow corpus | **16** scenarios · `tarot_signature_shadow_v1.json` |
| Classical Phase 3/4 parity | **PASS** |
| Crossroads structural shadow | **PASS** (4 edges · 7 relation rows) |
| Crossroads Phase 3 evidence | **BLOCKED** |
| Crossroads Phase 4 history | **BLOCKED** |
| User-path shadow importers | **0** |
| Picker / live V2 | **false** / **NOT WIRED** |
| Phase 6 seam audit | `SIGNATURE_SPREADS_PHASE6_SEAM_AUDIT.md` |
| Next | **Phase 5F** independent final audit |

### Phase 5F

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Kind | **AUDIT-ONLY** (no production/test/fixture edits) |
| BLOCKER / MAJOR | **0** / **0** |
| Phase 5 | **FROZEN** (pre-5F.1; hardening pending re-freeze) |
| Crossroads | shadow-only · picker **false** · live V2 **NOT WIRED** |
| Final audit | `docs/product/tarot/SIGNATURE_SPREADS_FINAL_AUDIT.md` |
| Next | **Phase 5F.1** post-audit hardening |

### Phase 5F.1

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** · **INDEPENDENTLY VERIFIED** |
| Kind | **NARROW REMEDIATION** (M1 / I1 / I2 only) |
| M1 / I1 / I2 | **RESOLVED** (ChatGPT independent verification) |
| Phase 3 / 4 production | **UNCHANGED** |
| Crossroads | shadow-only · picker **false** |
| Phase 5 status | **RE-FROZEN AFTER 5F.1 INDEPENDENT VERIFICATION** |
| Next | Phase 6.0 architecture lock (done) → **6A** |

### Phase 6.0

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Kind | **AUDIT / SPEC ONLY** (no production/test/fixture edits) |
| Phase 5 | **RE-FROZEN** after independent 5F.1 verification at `4b56592…` |
| Source audit | `docs/product/tarot/NARRATIVE_V2_LIVE_MIGRATION_SOURCE_AUDIT.md` |
| Migration spec | `docs/product/tarot/NARRATIVE_V2_LIVE_MIGRATION_SPEC.md` |
| Live Narrative V2 | **NOT WIRED** |
| Crossroads picker | **false** |
| Prompt architecture | **C** — NarrativeTarotPromptInput + legacy adapter |
| Next | **Phase 6A** (completed) → **6A.1** → **6B** → **6B.1** → **6C** |

### Phase 6D.1

| Field | Value |
|---|---|
| Status | **COMPLETE** / **IMPLEMENTED** (pending independent ChatGPT verification) |
| Kind | **BACKEND INPUT FIREWALL + FULL SEMANTIC REQUEST FINGERPRINT** |
| Remediated | M1 shallow inbound validation · M2 weak Narrative fingerprint |
| Max Narrative JSON | 32000 (frozen 6C max 5385) |
| Fingerprint | `tarot-narrative:<sha256>` canonical full wire |
| Flutter production | **unchanged** |
| Next | Independent 6D.1 verification → **Phase 6E** |

### Phase 6D

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** (independently verified; follow-up → 6D.1) |
| Kind | **NARRATIVE V2 BACKEND WIRE + STRICT STRUCTURED RESULT + CLIENT QUALITY** |
| Request fields | `mode` · `contractVersion` · `language` · `narrative` |
| Result contract | **1** · schema `oracly_tarot_narrative_v1` |
| Exact JSON field names | **RESOLVED** |
| Open minor remaining | life-area UI migration timing |
| Live call sites | **0** |
| Next | **6D.1** (completed) → independent verify → **6E** |

### Phase 6C.2

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** (independently verified · Phase 6C **FROZEN**) |
| Kind | **CANONICAL BOUNDS + MODEL-FACING SCALAR INTEGRITY + LOCALE-CONSISTENT SIGNATURE FIXTURE** |
| Remediated | M6 mixed-locale Signature fixture · M7 numeric scalars · M8 bounds bypass |
| Serializer / policy version | still **1** / `narrative_policy_v1` |
| Cache goldens changed | 1/8 (`signature_manual_spread_generic`) |
| Live call sites | **0** |
| Next | **6D** → **6D.1** → **6E** |

### Phase 6C.1

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** (independently verified; follow-up → 6C.2) |
| Kind | **PROMPT STRUCTURAL INTEGRITY + VERSION/LOCALE FAIL-CLOSED** |
| Remediated | M1 interpretationOrder · M2 relationship correspondence · M3 cache namespace · M4 locale · M5 note |
| Serializer / policy version | still **1** / `narrative_policy_v1` |
| Cache goldens changed | 2/8 (`privacy_sentinel_internal_ids`, `signature_manual_spread_generic`) |
| Live call sites | **0** |
| Next | **6C.2** (completed) → independent verify → **6D** |

### Phase 6C

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** (independently verified; follow-up → 6C.1 → 6C.2) |
| Kind | **NARRATIVE PROMPT SERIALIZER + DETERMINISTIC V2 CACHE IDENTITY** |
| Package | `lib/features/tarot/narrative/prompt/` |
| Serializer version | **1** |
| Policy version | `narrative_policy_v1` |
| Cache key | `narrative_tarot_v2_s1_<sha256hex>` |
| Live call sites | **0** |
| Backend / AI executor / live cache | **UNCHANGED** |
| Exact backend JSON names | still **OPEN** for 6D |
| Live Narrative V2 | **NOT WIRED** |
| Next | **6C.1** (completed) → independent verify → **6D** |

### Phase 6B.1

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** (independently verified) |
| Kind | **SIGNATURE HISTORY RESOLVER UNEXPECTED-ERROR HARDENING** |
| Root cause | Broad `catch (_)` swallowed Crossroads resolver invariants as skippedMalformed |
| Production | `signature_history_spread_normalizer.dart` only |
| Phase 4 production | **UNCHANGED** |
| Live Narrative V2 | **NOT WIRED** |
| Next | **Phase 6C** → **6C.1** → **6D** |

### Phase 6B

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** (independently verified; follow-up → 6B.1) |
| Kind | **SIGNATURE HISTORY NORMALIZATION / CROSSROADS HISTORICAL FACT** |
| Phase 4 reopen | card/session/legacy normalize supported resolvers only |
| Adapter | `SignatureHistorySpreadNormalizer` (new) |
| Crossroads historical spreadId | `signature.crossroads` |
| `classicalFromSpread(crossroads)` | still **null** |
| fiveCard fabrication | **NO** |
| H7 / H17 / H19 / recurrence engines | **UNCHANGED** |
| Current Crossroads builder | still **UNSUPPORTED** |
| Live Narrative V2 | **NOT WIRED** |
| Crossroads picker | **false** |
| Prior gate | 6A/6A.1 independently verified |
| Next | **6B.1** (completed) → independent verify → **6C** |

### Phase 6A.1

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** (independently verified before 6B) |
| Kind | **PROVIDER IDENTITY FAIL-CLOSED HARDENING** |
| Root cause | Classical provider returned `[]` for Signature Crossroads (silent) |
| Classical provider | Validates catalog identity before edge filter |
| Signature provider | Validates projected Crossroads identity + position keys |
| Default scorer/selector + Crossroads | **FAIL CLOSED** |
| classical.single zero edges | still valid |
| Live Narrative V2 | **NOT WIRED** |
| Next | **6B** → **6B.1** → **6C** |

### Phase 6A

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** (Classical parity independently verified; follow-up → 6A.1) |
| Kind | **CLASSICAL-PRESERVING SPREAD + EDGE PROVIDER SEAMS** |
| Phase 3 reopen | validation resolveSpread · pairing/scorer/selector edge provider |
| Signature adapters | new files only · **0** live callers |
| Default builder Crossroads | **UNSUPPORTED** |
| Classical corpus parity | **PASS** |
| Global edge table | **UNCHANGED** (29) |
| Live Narrative V2 | **NOT WIRED** |
| Crossroads picker | **false** |
| Phase 4 / Phase 5 SOT | **UNCHANGED** (pre-6B) |
| Prior gate | 6.0.3 independently verified |
| Next | **6A.1** → **6B** → **6B.1** → **6C** |

### Phase 6.0.3

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** (independently verified before 6A) |
| Kind | **SAFETY PREFLIGHT + QUALITY/RETRY FIREWALL** |
| B2 | Safety before `canAfford` · zero-balance safety OK · load not invoked |
| M3 | Quality actions hidden · reinterpret never writes safety interpretation |
| Live Narrative V2 | **NOT WIRED** |
| Crossroads picker | **false** |
| Phase 3 / 4 / 5 production | **UNCHANGED** (pre-6A) |
| Next | **6A** → **6A.1** → **6B** → **6B.1** → **6C** |

### Phase 6.0.2

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** (B1/M1/M2) · independent review found B2/M3 → 6.0.3 |
| Kind | **SAFETY PURITY + RECOVERY AUTHORIZATION + DELIVERY COPY** |
| B1 | Pure `safetyResponse` — no card-derived prose / Tarot story UI |
| M1 | Recovery requires `alreadyCharged` — else fail closed |
| M2 | `tarotContentWithSummary` preserves `deliveryKind` |
| Live Narrative V2 | **NOT WIRED** |
| Crossroads picker | **false** |
| Phase 3 / 4 production | **UNCHANGED** |
| Next | Follow-up **6.0.3** (completed) → independent verify → **6A** |

### Phase 6.0.1

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** (billing/journal) · independent review found B1/M1/M2 → 6.0.2 |
| Kind | **SAFETY BILLING / JOURNAL REMEDIATION** |
| Root cause | Usable safety `emergencyFallback` → `markProviderOk`/`commit` + journal |
| Delivery kinds | `interpretation` · `safety` · `recovery` |
| Safety | non-billable · non-journal · no OR/share/favorite/save |
| Recovery | no second charge · journal-eligible |
| Live Narrative V2 | **NOT WIRED** |
| Crossroads picker | **false** |
| Phase 3 / 4 production | **UNCHANGED** |
| Next | Follow-up **6.0.2** (completed) → independent verify → **6A** |

### Phase 4D.1

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| H18 | **IMPLEMENTED** (`privacyBlocked` + `currentOwnerId` required · no defaults · no inference) |
| Privacy short-circuit | **UNCHANGED** (`omitReason=privacy`) |
| Frozen corpus expectations | **UNCHANGED** |
| Live Narrative V2 | **NOT WIRED** |

### Phase 4D

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Request enricher | **IMPLEMENTED** (pure sync · card → theme → memory) |
| Historical corpus | **55** scenarios · **44/44** classes |
| Privacy short-circuit | **IMPLEMENTED** (`omitReason=privacy`) |
| Phase 3 fields | **PRESERVED** (identity pass-through) |
| Storage adapters | **4C frozen** |
| Live Narrative V2 | **NOT WIRED** |
| AI | **0** |

### Phase 4C.2

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| H17 strict live aliases | **IMPLEMENTED** (session.id + linked ReadingModel.id only) |
| linked.sessionId authority | **NO** |
| Request enricher | **IMPLEMENTED** (4D — still shadow) |
| Narrative V2 user path | **UNCHANGED** / **NOT WIRED** |

### Phase 4C.1

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| H14 owner-safe live Tarot ids | **IMPLEMENTED** (accepted adapter rows only) |
| H15 typed memory deletion | **IMPLEMENTED** (`removeBySourceAndType`) |
| H16 question grounding fallback | **IMPLEMENTED** (shared effective ask/topic) |
| Request enricher | **NOT IMPLEMENTED** |
| Narrative V2 user path | **UNCHANGED** / **NOT WIRED** |

### Phase 4C

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Snapshot loader | **IMPLEMENTED** |
| Owner isolation | **IMPLEMENTED** (`privacyBlocked` + empty on mismatch) |
| Source existence firewall | **IMPLEMENTED** |
| Tarot single delete coupling | **IMPLEMENTED** (`TarotHistoryDeletionService`) |
| Discovery clear ghost protection | **IMPLEMENTED** (`removeByType` · not soulmate) |
| Request enricher | **NOT IMPLEMENTED** |
| Narrative V2 user path | **UNCHANGED** |
| New persistence keys | **0** |
| Network / AI | **0** / **0** |

### Phase 4B

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Theme recurrence | **IMPLEMENTED** (cross-feature ≥2 types) |
| Memory evidence | **IMPLEMENTED** (pure · bounded · epistemic) |
| Connected memory adapters | **4C IMPLEMENTED** |
| Owner/store isolation | **4C IMPLEMENTED** |
| Delete coupling | **4C IMPLEMENTED** |
| Request enricher | **NOT IMPLEMENTED** |
| User path | **UNCHANGED** |
| Storage / AI / Network | **NONE** / **0** / **0** (pure engines) |

### Phase 4A.1

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Generic topic false positive | **FIXED** (H6 sentinels) |
| Physical-reading dedupe | **IMPLEMENTED** (H7 · before scan bound) |
| Dedupe before scan bound | **YES** |
| Short `aşk` | **SUPPORTED** → `ilişki` |
| ASCII `ask` | **NOT** a relationship alias |
| Storage | **NONE** |
| Theme / memory / enricher | **NOT IMPLEMENTED** (pre-4B) |
| User path | **UNCHANGED** |

### Phase 4A

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Phase 3 | **FROZEN** / **COMPLETE** |
| Phase 3 MINOR-01 | **CARRIED** (not fixed) |
| Production | historical models + eligibility + context + `TarotCardRecurrenceEngine` |
| Existing model change | `RecurringOccurrence.orientationKnown` only |
| Storage adapters | **NOT IMPLEMENTED** |
| Theme recurrence | **NOT IMPLEMENTED** |
| Memory evidence | **NOT IMPLEMENTED** (`MemoryEvidenceEntry` amendment → **4B**) |
| Request enricher | **NOT IMPLEMENTED** |
| Lookback | **90 days** inclusive · future rows **REJECT** |
| Scan / samples | ≤20 / ≤5 |
| occurrenceCount | distinct prior readings (H4) · physical identity dedupe (H7) |
| Evidence ids | `rec_card_##` |
| User path | **UNCHANGED** |
| AI / Network / Persistence | **0** / **0** / **0** |

### Phase 4.0

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** (docs-only) |
| Phase 3 | **FROZEN** / **COMPLETE** |
| Phase 3 MINOR-01 | **CARRIED** (not fixed) |
| Production Phase 4 | **NOT IMPLEMENTED** (4.0) · **4A pure engines IMPLEMENTED** |
| Docs | `NARRATIVE_MEMORY_RECURRENCE_SOURCE_AUDIT.md` · `NARRATIVE_MEMORY_RECURRENCE_SPEC.md` |
| Canonical Tarot history | **ReadingSession** (A) · ReadingModel enrichment |
| Connected memory authority | **OraclyMemoryStore** |
| Lookback | **90 days** (≤) · scan ≤20 |
| Owner isolation | same owner; owner-bound excludes ownerless legacy |
| Delete-source guarantee | design requires 4C journal↔session↔memory coupling |
| Open Phase 4 decisions | **0** |
| User path | **UNCHANGED** |

### Phase 3D.1E

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Audit doc | `docs/product/tarot/NARRATIVE_EVIDENCE_ENGINE_FINAL_AUDIT.md` |
| BLOCKER / MAJOR / MINOR / INFO | **0 / 0 / 1 / 3** |
| Evidence Engine ready to freeze | **YES** |
| Phase 3 | **COMPLETE** |
| Builder / scorer / selector | **IMPLEMENTED** |
| Corpus | **46** · reversed **38** · kinds **10/10** |
| Memory / history | **NOT IMPLEMENTED** / **NONE** |
| User path | **UNCHANGED** · V2 **NOT USER-REACHABLE** |
| Production source modified | **NO** (audit docs + test-only) |

### Phase 3D.1D.1

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Defect 1 | `unknownCanonicalCardId` unreachable (ritual check ran before deck lookup) |
| Repair | Per-card order: duplicate → deck → profile → ritual parity → position |
| `unknownCanonicalCardId` | **DIRECTLY REACHABLE** |
| `ritualCardMismatch` | valid-canonical parity error only |
| Defect 2 | 3D.1D report miscounted reversed scenarios as **26** |
| Corpus truth | scenarios **46** · reversed (≥1) **38** · fixture **UNCHANGED** |
| Relationship kinds | **10 / 10** |
| Scoring / selector / profiles | **UNCHANGED** |
| User path | **UNCHANGED** |

### Phase 3D.1D

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Builder | **IMPLEMENTED** — `NarrativeEvidenceBuilder.build` → closed `TarotNarrativeRequest` |
| Input | `NarrativeEvidenceInput` / `NarrativeEvidenceCardInput` (no memory/history/AI fields) |
| Language | `AppLocale.normalize` only → `tr` \| `en` \| `ru` |
| Spreads | classical 5/5 via `ClassicalSpreadSemantics.byLegacyTypeName` |
| Validation | card count · duplicate card · ritual↔canonical · deck/profile · positions · coverage · closed universe |
| New error codes | `duplicateCardId` · `ritualCardMismatch` (11 codes total) |
| Relationships | existing selector · max **12** · `rel_##` |
| Memory | `TarotNarrativeMemoryEvidence.empty` only |
| Recurrence | `recurringCards=[]` · `recurringThemes=[]` (themeRepetition ≠ historical) |
| Bounds | RequestBounds.defaults **20 / 5 / 12 / 800 / 4** |
| Corpus | `test/fixtures/tarot_narrative_evidence_v1.json` · **46** real-deck · frozen expectations |
| Corpus reversed scenarios | **38** (3D.1D task report **26** was a **reporting miscount**) |
| Relationship kinds | **10 / 10** covered in corpus |
| User path | **UNCHANGED** — no live importers outside evidence |
| AI / Network / Persistence / History | **0** / **0** / **0** / **NONE** |

### Phase 3D.1C.1

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Defect | Higher-priority kind bypassed `normalAdmitted` in selector `_finalize` |
| Repair | Non-theme emit requires `normalAdmitted`; theme sole special admission |
| Max relationships | Hard clamp requested max to **[0, 12]** |
| Max cards | Absolute ceiling **10** → else `cardCountMismatch` |
| FR court guards | Minor suits only — `OraclyTarotSuit.none` never true |
| Scoring constants / kind precedence | **UNCHANGED** |
| NarrativeEvidenceBuilder | **NOT IMPLEMENTED** |
| User path | **UNCHANGED** |

### Phase 3D.1C

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Scorer | **IMPLEMENTED** — `NarrativeRelationshipScorer` over prepared contexts |
| Selector | **IMPLEMENTED** — C(n,2) · kind finalization · theme · top-12 · `rel_##` |
| Overlap | `Σ(weight/6)` |
| Contradiction | **kind/veto only** — **NO** numeric −0.60 |
| FR-F01/F02 | overlap cap 0.35 · strength cap 0.45 — **NO** separate FR penalty |
| Support fallback | `normalAdmitted` + SEMANTIC; reinforcement = ≥2 ids df<8 AND mean raw weight ≥4.0 |
| Theme echo | current-spread selector only · max **1** · HF-only **REJECT** |
| Top-N / evidence ids | **12** · `rel_01`…`rel_12` deterministic |
| NarrativeEvidenceBuilder | **NOT IMPLEMENTED** |
| User path | **UNCHANGED** |
| AI / Memory / Network / Persistence | **0** / **NONE** / **0** / **0** |

### Phase 3D.1B.2

| Field | Value |
|---|---|
| Status | **PASS** |
| Defect | FR-F01 + canonical S=0.90 incorrectly labeled admitted |
| Correct result | **REJECT** (canonical threshold ≥1.0 unchanged) |
| FR-F02 + supportive 0.65 | **REJECT** |
| Synthetic guarded admit | 0.35+0.55+0.40=**1.30** · strength≈**0.371** ≤0.45 |
| Weak-band example | 1 HF + canonical (~1.11–1.19) |
| Scoring constants changed | **NO** |
| Production source | **UNCHANGED** |
| Open 3D.1C scoring decisions | **0** |
| Spec ready for 3D.1C | **YES** |

### Phase 3D.1B.1

| Field | Value |
|---|---|
| Status | **PASS** — calibration complete · OPEN 3D.1C scoring decisions **0** |
| Kind | Docs + optional test-only diagnostic — **no production scorer** |
| Calibration doc | `docs/product/tarot/NARRATIVE_RELATIONSHIP_SCORING_CALIBRATION.md` |
| Raw IDF saturation | **CONFIRMED** (single-id min ≈3.35; 93% overlapping pairs raw ≥3.5) |
| Chosen overlap | `Σ (weight(id)/6.0)` over Chan∩ |
| Normalized id range | ≈ **0.558 → 0.894** (used) |
| Theme echo threshold | **Keep 2.0** (normalized) |
| Tag-only / orientation / question | 0 numeric · 0 alone · {0,+0.15} |
| FR-F01/F02 identity | **`keywordIds` set equality** |
| Production scoring | **NOT IMPLEMENTED** |
| Evidence builder | **NOT IMPLEMENTED** |
| User path | **UNCHANGED** |
| Spec ready for 3D.1C | **YES** (after 3D.1B.2 admission example repair) |

### Phase 3D.1B

| Field | Value |
|---|---|
| Status | **COMPLETE** |
| Implemented | `NarrativeSemanticChannel` · FR-F04 dedupe · frozen ontology-rev1 DF map · keyword discrimination weights · explicit contrast table · transform signal/suppression helper |
| Ontology revision / N / DF ids | **1** · **156** · **128** |
| scatter / haste df | **14** / **13** (catalog truth; stale prompt 14 for haste WITHDRAWN) |
| keyword∩symbolTag orientations | **64 / 156** |
| Contrast pairs | **11** HARD + **4** CONTEXTUAL = **15** |
| Scoring | **NOT IMPLEMENTED** |
| FR-F01 / FR-F02 pair guards | **NOT IMPLEMENTED** — Phase 3D.1C |
| Evidence builder | **NOT IMPLEMENTED** |
| User path | **UNCHANGED** |
| AI / Persistence | **0** / **0** |
| Narrative evidence tests | **64** passed |
| Full Flutter | **3832** passed · **0** failed · **15** skipped · **0** timed out |

### Phase 3D.1A

| Field | Value |
|---|---|
| Status | **COMPLETE** |
| Implemented | Evidence domain models · `TarotNarrativeProfileSlice` · question grounding · classical spread semantic catalog · typed errors · empty memory/recurrence shells · `RequestBounds` / `TarotNarrativeRequest` |
| Spreads / positions | **5 / 5** · **26** |
| Authoritative edges / projected | **29** · **45** (13 directed + 16×2) |
| Position weights | **all 1.0** |
| Scoring | **NOT IMPLEMENTED** |
| Evidence builder | **NOT IMPLEMENTED** |
| Relationship candidate generation | **NOT IMPLEMENTED** |
| User path | **UNCHANGED** |
| AI calls | **0** |
| Persistence | **0** |
| Memory / recurrence providers | **NOT IMPLEMENTED** |
| Production surface | `lib/features/tarot/narrative/evidence/` |
| Tests | `test/features/tarot/narrative_evidence/` (**38** passed at 3D.1A) |
| Full Flutter | **3806** passed · **0** failed · **15** skipped · **0** timed out |

### Phase 3D.0.1

| Field | Value |
|---|---|
| Status | **PASS** — contract hardening |
| Resolved | Spread semantics completeness · `TarotNarrativeProfileSlice` architecture |
| Spreads / positions / edges | **5 / 5** · **26** rows · **29** edges |
| Position weights | **all 1.0** |
| Open implementation decisions | **0** |
| Spec ready for 3D.1A | **YES** |
| Evidence Engine | **NOT IMPLEMENTED** |
| Deck ready | **YES** |
| Production modified | **NO** |

### Phase 3D.0

| Field | Value |
|---|---|
| Status | **COMPLETE** — base spec; active contract = **3D.0.1** |
| Spec | `docs/product/tarot/NARRATIVE_EVIDENCE_ENGINE_IMPLEMENTATION_SPEC.md` |
| Deck readiness | **YES** (from 3C.5F) |
| Evidence Engine | **NOT IMPLEMENTED** |
| Open implementation decisions | **0** (after 3D.0.1) |
| Current user path | **UNCHANGED** |
| AI calls | **0** |
| Memory / recurrence | **DEFERRED Phase 4** |
| Signature spreads | **DEFERRED Phase 5** |
| AI narrative | **DEFERRED Phase 6** |
| Visual | **DEFERRED Phase 7** |
| Production modified | **NO** |

### Phase 3C.5F

| Field | Value |
|---|---|
| Status | **PASS** (independent audit) |
| Profiles / orientations | **78 / 78** · **156 / 156** |
| FR-M04 | **RESOLVED** |
| BLOCKER / MAJOR / MINOR / INFO | **0 / 0 / 3 / 2** |
| Semantic inversion / loss | **0 / 0** |
| Engine-blocking false overlaps | **0** |
| Unsupported keyword concepts | **0** |
| Engine usage contract | **READY** |
| DECK READY FOR EVIDENCE ENGINE | **YES** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Visual System | **NOT IMPLEMENTED** |
| Audit doc | `docs/product/tarot/TAROT_KEYWORD_ONTOLOGY_FINAL_AUDIT.md` |
| Production modified | **NO** |

### Phase 3C.5E

| Field | Value |
|---|---|
| Status | **PASS** (implementation) |
| FR-M04 | was **REMEDIATED — PENDING 3C.5F** (now RESOLVED via 3C.5F) |
| Keyword ontology | **IMPLEMENTED** |
| Ontology revision | **1** |
| Defined / used ids | **128 / 122** |
| Assignments / singletons | **439 / 30 (24.59%)** |
| Orientations mapped | **156 / 156** |
| Appendix B fixture match | **156 / 156** |
| Prose / transforms / symbolTags / profileRevision | **UNCHANGED** |
| DECK READY FOR EVIDENCE ENGINE | was **NO** pending 3C.5F |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Visual System | **NOT IMPLEMENTED** |

### Phase 3C.5D.1

| Field | Value |
|---|---|
| Status | **PASS** (design repair) |
| FR-M04 | was **OPEN** — implementation pending |
| Ontology plan | `docs/product/tarot/TAROT_KEYWORD_ONTOLOGY_PLAN.md` (**ACTIVE = 3C.5D.1**, implemented in 3C.5E) |
| Ambiguous mappings | **0** |
| Semantic inversions after | **0** |
| Plan approved for implementation | **YES** |
| Production keywordIds changed | **NO** (design phase) |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

Production surface:

- `lib/features/tarot/narrative/domain/` — models + validator + symbol tags
- `lib/features/tarot/narrative/data/` — catalog + Major + Wands + Cups + Swords + Pentacles profiles
- Tests: `test/features/tarot/narrative_domain/` (+ `red_team/`)

### Spec artifacts

- `docs/product/tarot/NARRATIVE_TAROT_SPEC.md`
- `docs/product/tarot/NARRATIVE_TAROT_DATA_CONTRACT.md`
- `docs/product/tarot/NARRATIVE_TAROT_MIGRATION_PLAN.md`
- `docs/product/tarot/NARRATIVE_TAROT_QUALITY_STANDARD.md`
- `docs/product/tarot/TAROT_PHASE0_FORENSIC_BASELINE.md`
- `docs/product/tarot/TAROT_78_PROFILE_RED_TEAM.md`
- `docs/product/tarot/TAROT_KEYWORD_ONTOLOGY_PLAN.md`

### Phase 2 artifacts

- Canonical corpus: `test/fixtures/narrative_tarot_v2_corpus.json`
- CONTRACT HARNESS (test-only): `test/support/narrative_tarot_v2/`
- Tests: `test/features/tarot/narrative_v2/`
- Legacy corpus retained: `test/fixtures/interpretation_engine_v2_corpus.json` (historical / insufficient for Narrative Tarot V2; not deleted)

---

## Latest verified baselines

| Suite | Result |
|---|---|
| Flutter (at code baseline `173d7522`) | 3627 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3A — PL-T3A) | 3662 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3B1 — PL-T3B1) | 3669 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3B2 — PL-T3B2) | 3676 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3B3 — PL-T3B3) | 3685 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3B4 — PL-T3B4) | 3699 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.1 — PL-T3C.1) | 3715 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.2 — PL-T3C.2) | 3719 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.3A — PL-T3C.3A) | 3725 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.3A.1 — PL-T3C.3A.1) | 3728 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.3B — PL-T3C.3B) | 3737 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.4 — PL-T3C.4) | docs/test-only; production source unmodified |
| Flutter (Phase 3C.5A — PL-T3C.5A) | 3740 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.5B — PL-T3C.5B) | 3749 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.5C — PL-T3C.5C) | 3756 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.5D — PL-T3C.5D) | docs + diagnostic only; production source unmodified |
| Flutter (Phase 3C.5D.1 — PL-T3C.5D.1) | docs only; production source unmodified |
| Flutter (Phase 3C.5E — PL-T3C.5E) | 3768 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3D.1A — PL-T3D.1A) | 3806 passed · 0 failed · 15 skipped · 0 timed out (+38 evidence domain) |
| Flutter (Phase 3D.1B — PL-T3D.1B) | 3832 passed · 0 failed · 15 skipped · 0 timed out (+26 semantic signals) |
| Flutter (Phase 3D.1D — PL-T3D.1D) | 3922 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3D.1D.1 — PL-T3D.1D.1) | 3923 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3D.1E — PL-T3D.1E) | 3944 passed · 0 failed · 15 skipped · 0 timed out |
| Backend (known) | 658 passed · 0 failed · 1 skipped |

---

## Open canonical backlog (NOT completed)

### P1

- Yildizname / Birth Chart: exact time/place collected; chart core is Sun-sign-only
- Astrology: LOCAL catalogue/sun-sign behavior vs LIVE registry mismatch
- Universe Map Memory chamber: reachable legacy CRUD/admin-feeling UI
- Home / Daily Ritual: inverse text-size accessibility behavior
- Premium: cancel/pending/restore-none uses success-style snackbar

### Release proof

Coffee production E2E · Palm production E2E · SoulMate production E2E · real/sandbox iOS StoreKit monthly/yearly purchase · restore · server entitlement verification

These remain **NOT COMPLETE** unless later evidence proves otherwise.

---

## Next action

**Independent ChatGPT verification of Phase 6F** — Classical Narrative V2 live cutover.

6F: **IMPLEMENTED** · flag `tarot_narrative_v2` default true · single/three/five live · seven/celtic legacy · Crossroads picker false · frozen Sol writer locked-env fail-closed · **0** real provider calls · Cloud deploy **NO**.

6E.8 independent: provider quality **FROZEN** (`gpt-5.6-sol` / `none`).

Do **not** begin **6G** until independent 6F PASS. Picker remains false in 6G.

Phase 6.0–6E.1: **PASS** · 6E.2 writing quality: **NOT PASS** · 6E.3/6E.3.1: **VERIFIED** · 6E.4: **0/6 transport** · 6E.4.1: **PASS** · 6E.4.2: **6/6 structured** · 6E.5: **prompt refine** · 6E.6: **6/6 structured** · 6E.7: **model isolation** · 6E.8: **quality FROZEN** · 6F: **wired** (pending verify) · live Classical V2: **YES (flag)** · Crossroads: **NOT LIVE**.

Do **not** merge.
Do **not** modify `release/ios-1.0` / Build 4.
Do **not** begin Phase 6F until independent writing-quality PASS.
Do **not** claim provider quality PASS from agent automated gates alone.
Do **not** wire live Tarot Narrative V2 path until an approved 6F cutover slice.
Do **not** expose Crossroads in user pickers until Phase 6 final + Phase 7 + Phase 8 gates.
