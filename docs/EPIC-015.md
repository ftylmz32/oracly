# EPIC-015 — The Lasting Memory

**Status:** Canonical · Session ending — peace, not pressure  
**Version:** 1.0  
**Perspective:** The experience continues in the user's mind after the app closes  
**Hierarchy:** [Master Directive](./MASTER_DIRECTIVE.md) → … → [EPIC-014 Trust Through Transparency](./EPIC-014.md) → [EPIC-015 The Lasting Memory](./EPIC-015.md) → [RC-001 Reveal & Reading](./RC-001.md) → [AI Agent Guide](./AI_AGENT_GUIDE.md)

---

> *When users close ORACLY, they should quietly think: "That was worth a few minutes of my time."*

Do **not** redesign. Do **not** change navigation. Strengthen how sessions conclude.

---

## Mission

Review the complete emotional journey. Focus on the ending.

How does every session conclude? How does the user feel after leaving?

---

## Emotional arc

| Phase | Feeling |
|-------|---------|
| Arrival | Curiosity |
| Selection | Presence |
| Reveal | Wonder |
| Reading | Reflection |
| **Closing** | **Peace** |

Every session should naturally follow this rhythm.

---

## Ending experience

Every completed reading leaves **one lasting impression**:

- Not a prediction
- Not a warning
- A meaningful reflection — one sentence that quietly stays

Anchor: `SessionEndingCopy.lastingReflection()` wired from EPIC-013 `closingMessage`.

---

## Memory

Users should remember a **feeling**, not a feature.

Strengthen moments that create emotional memory. Reduce distractions at the closing beat.

---

## Long-term relationship

The goal is not daily usage — it is **meaningful** usage.

If users return, they return because ORACLY added value to their day. Never because they feel pressured.

---

## Quality gates

Every ending should feel:

- Complete — never abrupt
- Full — never empty
- Honest — never manipulative

---

## Implementation

### Core files

| File | Role |
|------|------|
| `lib/core/copy/session_ending_copy.dart` | Central ending copy + resolvers |
| `lib/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart` | `closingMessage` field |
| `lib/features/tarot/interpretation/formatters/interpretation_formatter.dart` | Maps `closingMessage` to UI |
| `lib/features/tarot/presentation/widgets/ai_reading/reading_premium_body.dart` | Shows lasting reflection |
| `lib/features/tarot/presentation/widgets/ai_reading/reading_cosmic_message.dart` | "Son Yansıma" label |
| `lib/features/tarot/presentation/widgets/ai_reading/reading_footer_actions.dart` | Footer whisper |
| `lib/features/insights/services/reflective_intelligence.dart` | `_calmClosing()` synthesis |

### Tests

`test/session_ending_copy_test.dart`

---

## Relationship to other EPICs

| EPIC | Link |
|------|------|
| **EPIC-013** | `closingMessage` synthesis |
| **EPIC-014** | Transparency footnote after closing |
| **EPIC-011** | Daily ritual closing tone template |

---

## Success

The product succeeds when closing feels complete — and the user carries one quiet sentence with them.
