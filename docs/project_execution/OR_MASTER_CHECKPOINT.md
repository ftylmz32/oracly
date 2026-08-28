# OR Master Checkpoint

**Status:** OR MASTER STATUS = NOT COMPLETE  
**Architecture freeze:** 2026-08-24 — PROTECTED FLAGSHIP BASELINE (extend in place)  
**Intelligence polish:** 2026-08-25 — continuity / digest / short follow-ups extended in place  
**Final closure attempt:** 2026-08-25 — local gates PASS; Gates 1–3 external BLOCKED (no fake deploy / billing / voice).  
**Rule:** Do not replace this architecture unless a task explicitly authorizes a change. Extend in place. Preserve fail-closed honesty.

OR (the companion chat) is a flagship product surface. Before any OR change, re-read this checkpoint and confirm the live path still matches.

---

## Conversation quality freeze

Tone and conversation qualities are frozen separately in [`OR_BASELINE_CONVERSATION_QUALITY.md`](./OR_BASELINE_CONVERSATION_QUALITY.md). Architecture stays here; warmth/naturalness stays there.

## Intelligence polish (2026-08-25) — local, in place

| Area | Change |
|------|--------|
| Short follow-ups | `CompanionShortFollowUp` + policy/router — `peki / neden / devam / emin misin?` continue thread |
| Held topic | `CompanionHeldTopic` — concrete topic wins over vague `kararsızlık` |
| Long chat | `CompanionThreadDigest` — compact earlier-thread hint into styleHint (no transcript dump) |
| Live path | `CompanionLiveReply` passes `fullHistory` into context selection |
| Prompt | Short-follow-up + adaptive length rules in `ChatPromptBuilder` |
| Handoff IDs | `_stripIds` also strips alphanumeric `id:…` tokens |
| Job leave | `CompanionJobChange` recognizes `ayrılmayı` / `iş…ayr` |
| Tests | `or_master_intelligence_scenarios_test.dart` (scenarios A/C + digest + handoff) |

External product experience (live Premium OR on TECNO) remains unverified.

## Conversation quality master (2026-08-25) — extend in place

| Area | Change |
|------|--------|
| Correction | `CompanionCorrection` + intent/policy/continuity — no defense, no quiz |
| Short follow-ups | Expanded: sonra / yani diyorsun / sen olsan / bunu nasil |
| Adaptive length | Advice skips forced concise; deep wins over short when both |
| Prompt | `ChatPromptQualityAddon` — openings/closings/mysticism/voice |
| Polish | Filler guard strips more stock openers + stock closings |
| Tests | `or_conversation_quality_master_test.dart` |

**OR CONVERSATION QUALITY STATUS = NOT COMPLETE** — local behavior gates PASS; live Premium OR on TECNO and real multi-turn judgment remain unverified.



---

## 1. Canonical route

| Item | Value |
|------|--------|
| Route constant | `OraclyRoutes.chat` |
| Path string | `/chat` |
| File | `lib/core/navigation/oracly_routes.dart` |
| Generator mount | `OraclyRouteGenerator` case `OraclyRoutes.chat` |
| Transition | `OraclyPageTransitions.chamber` + `ChamberTransitionPersonality.orPresence` |
| Generator file | `lib/core/navigation/oracly_route_generator.dart` |

**Canonical open APIs**

- `OraclyNavigationService.openChat` — `lib/core/navigation/oracly_navigation_service.dart`
- `openOracleConversation(...)` — `lib/features/ai/oracle_conversation/navigation/oracle_conversation_route.dart` (wraps handoff + `openChat`)
- Feature registry: `OraclyFeatureId.aiChat` → `OraclyRoutes.chat`

Evidence: `test/features/companion/or_canonical_path_test.dart`

---

## 2. Canonical screen (live UI)

| Role | Class | Path |
|------|--------|------|
| **LIVE only** | `CompanionReferenceScreen` | `lib/features/companion/presentation/reference/companion_reference_screen.dart` |

### Quarantined — DO NOT rewire as production entry

| Class | Path | Note |
|--------|------|------|
| `CompanionScreen` | `lib/features/companion/presentation/screens/companion_screen.dart` | LEGACY |
| `OracleConversationScreen` | `lib/features/ai/presentation/screens/oracle_conversation_screen.dart` | Quarantined |

---

## 13. OR Master Release Gate — CURRENT

**Verdict: NOT COMPLETE** — local intelligence + honesty gates green; external TECNO / production / billing gates **BLOCKED**.

### LOCAL CODE GATES — PASS (2026-08-25 polish)

| Gate | Result |
|------|--------|
| Canonical `/chat` → `CompanionReferenceScreen` | **PASS** |
| Continuity / digest / short follow-up scenarios | **PASS** (`or_master_intelligence_scenarios_test`) |
| Baseline conversation quality | **PASS** |
| Discovery handoff quality | **PASS** |
| `flutter analyze` companion + chat prompt | **0 errors** (pre-existing infos on legacy screen) |

### EXTERNAL RELEASE GATES — unchanged BLOCKED

1. **Production HTTPS ORACLY AI proxy** — not deployed (`tool/dart_defines.production.json` absent)  
2. **Real Play Billing Premium** — products / device purchase not verified  
3. **Premium voice E2E on TECNO KN8** — `adb` unavailable; depends on (1)(2)

### Exact remaining weakness (product bar)

- Live multi-turn quality on production provider not proven on device  
- Voice interruption / recovery not proven on TECNO  
- Premium entitlement not proven with real Play purchase  
- Digest is local compaction (not LLM summarizer) — mid-thread nuance beyond anchors still limited by 8-turn window  

**OR MASTER STATUS = NOT COMPLETE**

Until external gates clear: do **not** convert BLOCKED → COMPLETE.

*End of OR Master Checkpoint.*
