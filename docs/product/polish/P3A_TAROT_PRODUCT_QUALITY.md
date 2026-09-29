# P3A — Tarot product quality

Live path audited: Home → `startTarotFlow` → `TarotHomeScreen` → `TarotTableScene` → intention → spread → draw → short reading → `ReadingScreen` → history / OR handoff.

Narrative engine, prompts, scoring, and backend were not changed.

## Findings

| Surface | Observation | Defect | Severity | Fix | Test |
|---|---|---|---|---|---|
| Table title | Literal `Tarot` on the live table. RU users saw English. | YES | Medium | `TarotL10n.chamberTitle` (`home.discovery.tarot.title`: Tarot / Tarot / Таро) | `tarot_p3a_polish_test`, `tarot_p3a_table_chrome_test` |
| OR deck name | Table, full reading, and history handoff stamped `Rider-Waite`. The one live deck's display name is `tarot.deck.classic` (Klasik Tarot / Classic Tarot / Классическое Таро). The chip is visible in the OR header. | YES | Medium | `TarotL10n.deckName` when no explicit name is stored | `tarot_p3a_polish_test` |
| OR topic label | Live chips `future`, `inner`, and `custom` fell through as raw ids (`Tarot · future`). | YES | Medium | Map those ids to the existing chip strings. Source prefix uses the localized chamber title. | `tarot_p3a_polish_test` |
| Table semantics | Intention chip, spread tile, and deck flight each wrapped a labeled button around child text or art. | YES | Low | `excludeSemantics` on the one action node | `tarot_p3a_table_chrome_test` |

## Unchanged by design

- Spread picker stays single / three / five. Seven, Celtic Cross, and Crossroads stay out of the live overlay.
- Whitespace-only custom text is already dropped by `ReadingQuestion.sanitize`. It does not become a question. Topic selection replaces the previous intention text.
- Custom-intention confirm stays on screen at 320×568 with a large keyboard inset. No dialog change.
- Draw single-flight, reduced-motion completion, and active-session recovery already live in the ritual controller. Completed sessions are cleared from the active document. Existing 7D / 7F tests still pass.
- Short-table text already falls back from summary to the card's upright or reversed meaning. Deepen pushes the same `ReadingScreen`. Ask OR uses the current session.
- Loading uses `TarotLoading` cinema copy, not a bare spinner. Safety delivery is already excluded from save and from the reading-screen OR handoff.
- History sample readings stay behind `showSampleData` (default false). Empty history already has a Tarot CTA.
- Card art pairing, reversed rotation, save idempotency, and history reopen fidelity were not found defective in the live contracts already covered by 7D/7F tests.
- An explicitly stored deck name, including an older `Rider-Waite` metadata value, is still shown. Only a missing name uses the catalogue label.
