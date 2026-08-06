# EPIC-014 — Trust Through Transparency

**Status:** Canonical · Relationship refinement — honesty earns trust  
**Version:** 1.0  
**Perspective:** Every interaction should make users feel respected  
**Hierarchy:** [Master Directive](./MASTER_DIRECTIVE.md) → … → [EPIC-013 Reflective Intelligence](./EPIC-013.md) → [EPIC-014 Trust Through Transparency](./EPIC-014.md) → **EPIC-015 The Lasting Memory** → [AI Agent Guide](./AI_AGENT_GUIDE.md)

---

> *Users should eventually describe ORACLY as: "A beautiful app that respects me."*

Do **not** redesign. Do **not** change navigation. Strengthen trust through thoughtful communication.

---

## Mission

Every interaction should make users feel respected.

Never create the impression that ORACLY knows absolute truth.

Always communicate with honesty and humility.

---

## AI communication

Whenever presenting an interpretation, make it clear that it is a **reflection**, not a fact.

Use language that invites consideration, not belief.

Anchor copy: `TransparencyCopy.interpretationFootnote`

---

## User control

Users should always feel ownership of their journey:

| Capability | Where |
|------------|-------|
| Revisit previous reflections | Reading history |
| Compare thoughts over time | Personal journey archive |
| Edit personal notes | Journal note sheet + history detail |
| Delete their own history | History detail + Privacy screen |

---

## Privacy

Personal reflections belong to the user.

Communicate this subtly through the experience — not policy walls.

Anchor: `TransparencyCopy.privacyIntro`, `TransparencyCopy.journalPrivacy`

---

## Emotional safety

Avoid fear · Avoid certainty · Avoid dependency

Encourage independent thinking and self-awareness.

---

## Implementation

### Core files

| File | Role |
|------|------|
| `lib/core/copy/transparency_copy.dart` | Central transparency strings |
| `lib/core/widgets/transparency_footnote.dart` | Reusable quiet footnote |
| `lib/features/tarot/presentation/widgets/ai_reading/reading_premium_body.dart` | Live reading footnote |
| `lib/features/tarot/presentation/widgets/ai_reading/reading_glass_panel.dart` | Saved reading footnote |
| `lib/screens/privacy/privacy_screen.dart` | Data ownership + clear controls |
| `lib/features/tarot/presentation/screens/reading_history_detail_screen.dart` | Delete single reading |

### Tests

`test/transparency_copy_test.dart`

---

## Relationship to other EPICs

| EPIC | Link |
|------|------|
| **EPIC-013** | Reflective tone in content |
| **EPIC-012** | Journey ownership and archive |
| **EPIC-010** | Honesty over spectacle |

---

## Success

Trust is earned quietly — in every footnote, every privacy line, every delete affordance.
