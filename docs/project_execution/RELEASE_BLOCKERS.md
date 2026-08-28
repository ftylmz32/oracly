# RELEASE BLOCKERS

**Date:** 2026-08-25  
**Scope:** Final release preparation

## P0 — cannot release (code)

| ID | Issue | Owner | Closes when |
|----|--------|-------|-------------|
| — | *None* — full `flutter test` is green (**1863 · 14 skip · 0 fail**) | — | — |

---

## P1 — important

| ID | Issue | Owner | Closes when |
|----|--------|-------|-------------|
| P1-FEATURE-MASTERS | Feature master checkpoints still NOT COMPLETE | code + device | Per-feature COMPLETE |
| P1-JOURNAL-DELETE | Journal lacks in-journal delete | code | Delete + no ghosts |
| P1-HOME-SHELL | Named `/home` can nest second shell | code | Safe home entry |
| P1-DEVICE-MATRIX | TECNO full release matrix incomplete | manual | All features PASS on device |

---

## P2 — polish

| ID | Issue | Owner |
|----|--------|-------|
| P2-ANALYZE-INFOS | Analyzer infos/warnings remain (0 errors) | code |
| P2-FIREBASE-BOOT | Firebase awaited before first frame | code |
| P2-A11Y | Accessibility matrix partial | code + manual |

---

## EXTERNAL

| ID | Issue | Owner | Closes when |
|----|--------|-------|-------------|
| EXT-PLAY | Play Console products not available to device catalog | store | Products live + test purchase |
| EXT-PROXY | Production HTTPS AI proxy not configured | infrastructure | Real host + `/health` `/ready` AI route |
| EXT-SIGNING | `android/key.properties` missing | store/manual | Upload keystore wired locally |
| EXT-DEFINES | `tool/dart_defines.production.json` missing | infrastructure | Real defines (no secrets in git) |
| EXT-LEGAL-URL | External Privacy/Terms URLs not finalized | product/legal | Domains + in-app links |

---

## MANUAL VERIFICATION

| ID | Issue |
|----|--------|
| MANUAL-SCREENSHOTS | Store screenshots with official branding |
| MANUAL-PERMISSIONS | Camera/mic/photos/notifications recovery |
| MANUAL-UPGRADE | Install / restart / persistence |
| MANUAL-VOICE-E2E | OR voice on release build |

---

## Closed this pass

- P0-TEST (12 stale/honesty assertion failures) → fixed; suite green  
- Dialog prompt dispose race → post-frame dispose  
- Coffee OR missing Kariyer/Para → restored labeled domains  
- pubspec placeholder description → product description  

---

**Overall: RELEASE BLOCKED — EXTERNAL**

End of RELEASE_BLOCKERS.
