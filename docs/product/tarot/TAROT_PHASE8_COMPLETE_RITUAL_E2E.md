# TAROT Phase 8 / 8.1 / 8.3 — Complete Ritual E2E Freeze Evidence

**START HEAD:** `53a8bc0741a065098507b0afe96899d3b87c7043`  
**Branch:** `fix/final-product-remediation-20260922`  
**REAL PROVIDER CALLS:** 0

---

## Verdicts

| Gate | Status |
|------|--------|
| **Phase 8.1** (paid restart replay) | **PASS** |
| **Phase 8.3** (transactional draw persist) | **PASS** |
| **Phase 8 FINAL** (full matrix) | **PASS** |
| Phase 8 FROZEN | **YES** |
| Phase 9 READY | **YES** |

---

## 8.1 durable replay envelope

Snapshot ≠ payment. Authority is `TarotReadingCharge.alreadyCharged(session.id)`.

| Case | Behavior |
|------|----------|
| A — no body | Normal completion + generate |
| B — body, not charged | Replay body → charge once, provider=0 |
| C — body + charged | Direct replay — provider=0, charge=0 |

Shared path: `TarotReadingLoadPath.resolve`.

---

## 8.3 transactional draw

`drawCard` / `drawAllRemaining`:

1. Snapshot pre-draw session + drawn ids  
2. Deck produces candidate  
3. Pure candidate `ReadingSession` (no `_session` assign yet)  
4. `saveSession(candidate)`  
5. On success → assign `_session`, notify  
6. On failure → durable read-back:  
   - durable matches candidate → **commit reconciliation** (write-then-throw)  
   - else → restore pile from snapshot + keep pre-draw session (fail-before-write)  
7. Uncertain durable state → `_drawStateUncertain`, lock held

Settle (`advanceAfterReveal` / 7D.1) untouched.

---

## Proven matrix (Phase 8 E2E)

Flagship widget three · happy single/three/five · rapid draw · draw failure · settle failure · restart A–G · flag/locale both · timeout · insufficient+recovery · charge failure · concurrent load · navigate-away · safety / zero-gem / restart · recovery / unpaid reject · journal gate · history roundtrip · new reading / abandon · daily collision · corrupt / empty id / overfull / partial · deck continuity · OR / share / favorite · reinterpret / safety revision / identical version · first reading · custom+topic intention · Crossroads/seven/celtic firewall · 8.3 fail-before / write-then-throw / fan / drawAllRemaining.

---

## Quality gates

| Gate | Result |
|------|--------|
| `flutter test test/features/tarot/e2e/` | **66 PASS** |
| `flutter test test/visual/tarot/` | **PASS** (golden masters + hash parity) |
| Phase 6F1 / 7D / 7E / 7F targeted | **PASS** |
| `flutter analyze` | errors **0** · warnings **0** · infos **202** |
| Full `flutter test` | **4709 PASS** · **16 SKIP** · **0 FAIL** |
| Golden PNG bytes modified by Phase 8 | **0** |
| Backend modified by Phase 8 | **0** (pre-existing dirt preserved) |

---

## Production scope

**8.1:** `reading_session.dart` · `reading_session_codec.dart` · `tarot_reading_controller.dart` · `reading_screen.dart` · `tarot_reading_load_path.dart` · `tarot_session_interpretation_replay*.dart`

**8.3:** `tarot_reading_controller.dart` only (transactional draw)

**8.2/8.3 tests:** `test/features/tarot/e2e/*`

No Phase 8 production expansion beyond 8.1 + 8.3 draw transaction.
