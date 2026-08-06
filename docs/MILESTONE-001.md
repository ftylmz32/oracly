# MILESTONE-001 — Beta Readiness Report

**Status:** Beta Lock · Product audit  
**Date:** August 2026  
**Audience:** Product owner, closed-beta testers, engineering  
**Scope:** Full application review — no new features, no redesign

**Hierarchy:** [Master Directive](./MASTER_DIRECTIVE.md) → … → [RC-012 First-Time User Experience](./RC-012.md) → **MILESTONE-001 Beta Lock**

---

## Executive Summary

ORACLY is **ready for a carefully scoped closed beta** centered on the **Tarot ritual + reading archive + reflective onboarding** path. That core loop is coherent, visually polished, and mostly resilient.

It is **not ready** to be handed to a general user who expects working premium commerce, live AI everywhere, or the cosmic preview modules (Dream, Astrology, Star Map) to be real.

**Honest beta label:**

> *"ORACLY closed beta — guided Tarot reflection, local readings, reading journal. AI chat requires setup. Some home tiles are previews."*

**Verdict:** Proceed with closed beta **after resolving all P0 items** (11 issues). P1 items can ship in parallel during beta but must be closed before public release.

---

## Recommended Beta Scope

### In scope (test and promote)

| Surface | Why |
|---------|-----|
| Onboarding → first Tarot reading | RC-012 complete; sets expectations well |
| Full Tarot ritual stack | Most polished, offline-capable interpretation |
| Reading history + journal notes | Persistence, empty states, delete confirmation |
| Home (Tarot + daily ritual entry) | Coherent sanctuary composition |
| Profile (name edit, settings, privacy) | Functional local identity |
| Settings + Privacy + About | Transparency and data controls present |

### Out of scope (hide, label, or disable for beta)

| Surface | Why |
|---------|-----|
| Premium purchase CTA | Fake commerce — one tap "buys" premium locally |
| Dream / Astrology / Star Map tiles | Preview modules with canned content |
| Achievements / streak / spiritual level | Gamification conflicts with product charter |
| English language setting | No i18n behind the toggle |
| Post-reading Oracle chat as "AI" | Rule-based local responder, not live model |

---

## Completed Systems

Systems that are **production-quality for closed beta** (with noted caveats):

### Core shell & navigation

- Splash → onboarding (first launch) → `OraclyAppShell` (4 tabs)
- Nested Tarot navigator with full ritual stack
- Global routes for settings, privacy, premium, history
- First-session intent routes new users to guided Tek Kart reading (RC-012)

### Tarot ritual (primary product)

- Home → deck → intention → shuffle → select → reveal → reading
- Cinematic animations (shuffle, spread, reveal) with `OraclySignatureMotion`
- Local interpretation pipeline with emergency fallback (`LocalInterpretationExecutor`)
- Card detail catalogue (Major Arcana)
- Reading typography and craftsmanship rhythm (RC-007, RC-008)

### Reading archive & journal

- `ReadingHistoryScreen` with loading, error retry, empty state, search/filter
- Detail view with favorites, personal notes, journal metadata
- Delete confirmation via `TransparencyCopy`
- Timeline grouping and month markers

### Onboarding & first session (RC-012)

- 3 calm slides: what ORACLY is, how it works, what it is not
- Skip-friendly, under one minute
- First-session copy variants across ritual steps
- Honest new-user defaults (0 readings, no fake streaks in mock data)

### Resilience layer (RC-003)

- Central `ResilienceCopy` for user-facing errors (tested)
- `OraclyErrorState`, `TarotErrorState`, `OraclySnackBar` patterns
- Chat offline/config-missing messages
- Tarot reading never hard-crashes on interpretation failure

### Trust & transparency (RC-014 patterns)

- Privacy screen with local data deletion
- Interpretation footnotes avoid certainty language
- Onboarding explicitly frames reflection, not fortune-telling

### Intelligence foundation (backend-ready, UI-independent)

- RC-009 Intelligence Layer — journey storage architecture
- RC-010 Reflection Engine — pattern recognition from history
- RC-011 Experience Orchestrator — recommendation deciders
- All wired via providers; **not yet consumed by UI** (intentional)

### Test coverage (unit/copy)

- **84 passing tests** as of beta lock audit
- Strong coverage on copy, intelligence, reflection, experience orchestrator, typography, resilience

---

## Remaining Issues

Every issue is classified **P0**, **P1**, or **P2** only.

---

### P0 — Must fix before beta

Issues that will cause **crash, broken core flow, or loss of user trust** in a closed beta.

| ID | Area | Issue | Impact |
|----|------|-------|--------|
| P0-01 | **Startup** | `main()` calls `dotenv.load('.env')` with no fallback; missing asset crashes app at launch | Beta APK/TestFlight build fails for testers without bundled key |
| P0-02 | **AI Chat tab** | Model hardcoded as `gpt-5.5` in `AiService` — likely invalid API model | All live chat requests fail even with valid key |
| P0-03 | **AI Chat tab** | Retry duplicates user message: failed send already appended; retry calls `_sendMessage()` again | Confusing broken conversation on network error |
| P0-04 | **Premium** | "Premium açıldı" activates via local flag only — no IAP, no restore, prices shown (₺149–₺2.499) | Testers believe they purchased; legal/trust risk |
| P0-05 | **Home → Cosmic tiles** | Dream, Astrology, Star Map reachable with **no preview badge**; return canned text regardless of input | User thinks features are broken or deceptive |
| P0-06 | **Astrology** | Primary CTA "Günlük Yorumu Oku" is `onPrimary: () {}` — dead button | Obvious broken UI in reachable screen |
| P0-07 | **Premium decks** | Decks marked `isPremium: true` in data; **no gating** in deck selection UI | Premium value proposition is meaningless; free access to "premium" decks |
| P0-08 | **History storage** | `MockHistoryRepository.getReadings()` — no try/catch on `jsonDecode`; one corrupt entry crashes entire history | Data loss perception; app unusable for returning user |
| P0-09 | **Product honesty** | Two AI systems: tab chat = live OpenAI; post-reading Oracle = rule-based templates — **same "OR" branding** | Testers cannot tell what is real AI vs scripted |
| P0-10 | **Beta distribution** | `.env` listed in assets but gitignored; no documented tester setup for `OPENAI_API_KEY` | AI tab silently broken for most testers without instructions |
| P0-11 | **Dream screen copy** | Description promises "OR AI ile keşfet" but analysis is static `_sampleAnalysis` | Misleading feature promise |

**Recommended P0 actions (no new features — containment only):**

1. Graceful `.env` load; document tester key setup in beta invite
2. Fix chat model string + retry duplication bug
3. Disable or clearly label premium purchase ("Beta — ödeme yok")
4. Add visible **"Önizleme"** badge on cosmic tiles OR remove from home for beta build
5. Wire Astrology primary button to show existing horoscope text (already rendered below)
6. Either gate premium decks or hide them until IAP exists
7. Wrap history JSON parse in per-entry skip
8. Add one-line disclaimer on Oracle post-reading chat: "Yansıma rehberi — canlı AI değil"

---

### P1 — Should fix before public release

Issues that **will not block a informed closed beta** but must not ship to App Store / open beta.

| ID | Area | Issue |
|----|------|-------|
| P1-01 | **Profile** | Streak, spiritual level bar, achievements visible — conflicts with EPIC-011/012 anti-gamification charter |
| P1-02 | **Settings** | Language picker offers English with no i18n system (`OraclyL10n` exists but unused) |
| P1-03 | **Localization** | All strings hardcoded Turkish across ~50+ screens; no `flutter gen-l10n` |
| P1-04 | **Accessibility** | Only ~12 `Semantics` widgets app-wide; chat bubbles, empty states, most CTAs unlabeled |
| P1-05 | **Memory** | `MemoryScreen` orphaned from main nav; English copy in legacy `MemorySection`; raw keys shown to users (`goal • high`) |
| P1-06 | **Chat** | `MemoryExtractor.analyzeMessage()` runs synchronously before AI reply — can delay send |
| P1-07 | **History detail** | Provider error silently shows stale entry — no error UI |
| P1-08 | **Storage** | `StorageService.loadMessages()` — no corrupt JSON handling |
| P1-09 | **Splash** | Bootstrap catch silently routes to shell — masks onboarding/storage failures |
| P1-10 | **Daily Energy** | Marked `live` in registry but content is static mock strings |
| P1-11 | **Deck catalogue** | `MockTarotRepository` — Major Arcana only; minor arcana assets exist but not wired |
| P1-12 | **Analytics** | `AnalyticsService` is assert-only stub — no crash reporting or beta telemetry |
| P1-13 | **Auth** | `MockAuthService` — no account, no cross-device sync despite API client scaffold |
| P1-14 | **Tests** | Zero integration tests for Chat, Memory, Storage, AI service; one widget smoke test |
| P1-15 | **Legacy code** | Dead paths: `HomeScreen`, `MemoryScreen`, `HistoryScreen`, old tarot screens — risk if deep-linked |
| P1-16 | **Loading consistency** | 3 raw `CircularProgressIndicator` instances off-brand vs `ChamberWaitingOrb` |
| P1-17 | **Oracle UI** | Voice/add-on tooltips say "yakında" — acceptable for beta but needs product decision |

---

### P2 — Nice improvement

Polish items; safe to defer past public launch.

| ID | Area | Issue |
|----|------|-------|
| P2-01 | **Chat** | App bar title hardcoded `'OR'` |
| P2-02 | **Error state** | `OraclyErrorState` retry label hardcoded `'Tekrar Dene'` instead of `ResilienceCopy.retryAction` |
| P2-03 | **Snackbars** | Some paths still use raw `ScaffoldMessenger` instead of `OraclySnackBar` |
| P2-04 | **Memory delete** | Uses raw `AlertDialog` instead of `OraclyDialog` |
| P2-05 | **Responsiveness** | Most layouts use fixed spacing; limited `LayoutBuilder` — acceptable on phones, untested on tablets |
| P2-06 | **Provider naming** | Duplicate `readingHistoryProvider` in oracle module — confusing for maintainers |
| P2-07 | **Experience layer** | RC-011 orchestrator not wired to UI — opportunity, not blocker |
| P2-08 | **Animations** | Heavy cinematic layers on low-end devices — no reduced-motion preference hook |

---

## Known Limitations

Be transparent with beta testers about these **by design or by stage**:

| Limitation | User-facing honesty |
|------------|---------------------|
| All data is local (`SharedPreferences`) | "Verilerin cihazında kalır; hesap yok." |
| No real payments | "Premium henüz satın alınamaz — beta." |
| Tarot interpretation is local/template | "Kart yorumu cihazında oluşturulur; internet gerekmez." |
| AI Chat tab needs OpenAI key | "OR sohbeti için beta anahtarı gerekir." |
| Post-reading Oracle chat is guided, not GPT | "Okuma sonrası sohbet yansıma rehberidir." |
| Dream / Astrology / Star Map are previews | "Bu modüller önizlemede — gerçek analiz yakında." |
| Daily Energy is static copy | "Günlük enerji metni henüz kişiselleştirilmiyor." |
| No cloud sync or backup | "Cihaz değiştirince geçmiş taşınmaz." |
| Turkish only (despite settings toggle) | "Beta yalnızca Türkçe." |
| Reserved modules (Numerology, Moon Calendar, Manifestation) | Not shown — no action needed |

---

## Screen Audit

| Screen | Status | Beta note |
|--------|--------|-----------|
| Splash | ✅ Ready | Fix P0-01 startup |
| Onboarding | ✅ Ready | Strong first impression |
| Home | ⚠️ Scope | Hide/labeled cosmic tiles (P0-05) |
| Tarot Home | ✅ Ready | Primary entry |
| Deck Selection | ⚠️ Premium | Hide premium decks or add gate (P0-07) |
| Intention / Shuffle / Select / Reveal | ✅ Ready | Animations solid |
| Reading | ✅ Ready | Local interpretation + fallback |
| Oracle Conversation | ⚠️ Honesty | Add disclaimer (P0-09) |
| Chat (tab) | ❌ Blocked | Fix model + retry + key setup (P0-02, 03, 10) |
| Reading History | ✅ Ready | Fix corrupt data crash (P0-08) |
| History Detail | ⚠️ Edge cases | P1-07 error UI |
| Card Detail | ✅ Ready | Major arcana only |
| Profile | ⚠️ Charter | Gamification visible (P1-01) |
| Achievements | ⚠️ Charter | Consider hiding for beta |
| Premium | ❌ Blocked | Disable purchase (P0-04) |
| Settings | ✅ Ready | Remove or disable English toggle (P1-02) |
| Privacy | ✅ Ready | |
| About | ✅ Ready | v1.0.0 |
| Daily Energy | ⚠️ Mock | Static content (P1-10) |
| Dream | ❌ Misleading | Preview only (P0-05, 11) |
| Astrology | ❌ Broken CTA | P0-06 |
| Star Map | ⚠️ Preview | Canned text (P0-05) |
| Memory (legacy) | 🗄️ Orphan | Not in nav — P1-15 |
| History (legacy chat) | 🗄️ Orphan | Not in nav — P1-15 |

---

## Navigation Map (verified)

```
Splash
  ├─ Onboarding (first launch) → OraclyAppShell (tab: Tarot)
  └─ OraclyAppShell
       ├─ Home → Settings, Premium, Daily Energy, Dream*, Astrology*, Star Map*
       ├─ Tarot → full ritual stack → Oracle chat*
       ├─ AI Chat*
       └─ Profile → History, Achievements, Premium, Settings

* See screen audit for beta readiness
```

No navigation structure changes recommended — only **scope containment** on reachable destinations.

---

## Recommended Launch Blockers

**Do not invite external testers until these are resolved:**

1. **P0-01** — App must launch without `.env` (graceful degradation)
2. **P0-04** — Premium purchase disabled or clearly marked non-functional
3. **P0-05 + P0-06 + P0-11** — Preview modules labeled or removed from home
4. **P0-08** — History must survive corrupt storage entry
5. **P0-09** — Oracle vs live AI distinction documented in-app

**Strongly recommended before first tester session:**

6. **P0-02 + P0-03 + P0-10** — If AI Chat tab stays in beta scope
7. **P0-07** — Premium deck honesty

**Beta invite should include:**

- Explicit scope: Tarot ritual + journal
- Whether AI chat is in scope for this cohort
- How to configure `OPENAI_API_KEY` (if applicable)
- List of preview vs live features
- Known data limitations (local only, no backup)

---

## Animation & Responsiveness

### Animations

- **Strength:** Tarot shuffle, card reveal, home presence loop, premium entrance — consistent motion language
- **Risk:** Heavy layers on low-end Android; no `MediaQuery.disableAnimations` / reduced-motion hook (P2-08)
- **Verdict:** Acceptable for phone closed beta; monitor tester feedback

### Responsiveness

- Safe-area and keyboard insets handled on sheets/footers
- `TextScaler` clamped 0.85–1.35 in `OraclyApp` — good readability bounds
- Limited tablet/large-screen adaptation — P2 for beta

---

## AI Flow Summary

| Flow | Engine | Offline | Beta ready |
|------|--------|---------|------------|
| Tarot reading interpretation | Local executor | ✅ | ✅ |
| Post-reading Oracle chat | Rule-based responder | ✅ | ⚠️ Needs disclaimer |
| Main Chat tab | OpenAI HTTP (`AiService`) | ❌ | ❌ Fix P0-02/03/10 |
| Dream analysis | Static string | ✅ | ❌ Misleading |
| Daily Energy | Static mock | ✅ | ⚠️ OK if labeled mock |

---

## Premium Flow Summary

| Step | Current behavior | Beta action |
|------|------------------|-------------|
| Entry (home, profile, tarot) | Full luxury UI | Keep UI; disable CTA |
| Plan selection | Monthly / yearly / lifetime prices | Show "Beta" badge |
| Purchase | `MockPremiumRepository.activatePlan()` | **Block** |
| Benefits | Profile badge, achievement unlock | OK for internal testing only |
| Deck gating | None | Hide premium decks or gate |

---

## History & Journal Summary

| Capability | Status |
|------------|--------|
| Save reading after ritual | ✅ |
| Timeline + search + filter | ✅ |
| Favorites | ✅ |
| Personal note / journal sheet | ✅ |
| Delete with confirmation | ✅ |
| Corrupt data resilience | ❌ P0-08 |
| Cloud backup | ❌ Not implemented |

---

## Accessibility & Localization

| Dimension | Beta readiness |
|-----------|----------------|
| Localization | Turkish-only OK for TR closed beta; English setting is misleading (P1-02) |
| Screen reader | Insufficient semantics for WCAG-minded beta (P1-04) |
| Text scaling | Clamped but functional |
| Color contrast | RC-008 improved secondary text contrast |

---

## Test & Quality Gate

| Gate | Status |
|------|--------|
| `flutter test` | ✅ 84 passing |
| `flutter analyze` | ✅ Clean (post RC-012 fix) |
| Manual Tarot E2E | Required before invite |
| Manual onboarding E2E | Required before invite |
| AI chat with valid key | Required if in beta scope |
| Premium tap test | Must confirm blocked/disabled |

---

## Success Criteria (MILESTONE-001)

ORACLY now has a **clear, honest understanding** of:

| Question | Answer |
|----------|--------|
| What is ready? | Tarot ritual, onboarding, reading archive, settings/privacy, resilience copy |
| What blocks beta? | 11 P0 issues — mostly trust, crash, and AI honesty |
| What can wait? | P1/P2 — gamification removal, i18n, accessibility, analytics |
| What should testers expect? | Guided reflection tool, not fortune app; previews labeled; no real payments |

**Feature development is frozen.** Next work is P0 containment, beta tester documentation, and manual QA on the Tarot path — not new modules.

---

## Appendix — Issue Count

| Priority | Count | Action |
|----------|-------|--------|
| P0 | 11 | Fix before first external tester |
| P1 | 17 | Fix before public release |
| P2 | 8 | Backlog |

---

*Generated at beta lock. Update this document when P0 items are resolved and before each tester cohort.*
