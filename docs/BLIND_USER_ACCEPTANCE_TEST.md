# ORACLY — Blind User Final Acceptance Test

**Status:** Protocol ready · **Live session required**  
**Rule:** Do not add features during or because of this test. Observe only.

---

## Facilitator script

### Before

1. Install a **release-profile** build on a clean device (or reset app data).
2. Recruit someone **not involved in building ORACLY**.
3. Do **not** explain the product, positioning, or navigation.
4. Hand them the phone. Say only:

   > **"Uygulamayı kullan."**

5. Sit silently. Intervene **only** if completely blocked (cannot proceed at all for 60+ seconds).
6. Start a 3-minute timer when they reach the home screen (after onboarding skip/complete).

### During (observe & note verbatim quotes)

| Observation | Notes |
|-------------|--------|
| First tap after home | |
| Stated or implied: "What is ORACLY?" | |
| Coffee — what they think it does | |
| Tarot — what they think it does | |
| Yıldızname — understood? | |
| SoulMate — understood? | |
| OR — found? understood? | |
| Send button in OR chat — found? | |
| Voice mode (YAZILI / SESLİ) — understood? | |
| Premium — found? | |
| Return to previous discovery — possible? | |
| Gems / Mücevherler — understood? | |
| Read onboarding or skip? | |
| Frustration / delight moments | |

### After 3 minutes (exact questions — do not suggest answers)

1. **"Bu uygulamayı arkadaşına nasıl anlatırsın?"**
2. **"En çok hangi bölümü merak ettin?"**
3. **"Bir şeyi değiştirebilseydin neyi değiştirirdin?"**

### Success criterion (north star)

They should describe ORACLY as a **personal discovery experience** — symbolic readings, AI conversation, continuity over time — **not** simply *"bir fal uygulaması."*

---

## Facilitator prep — known navigation map (do not share with participant)

| Feature | Primary entry (live shell) |
|---------|----------------------------|
| Home | Tab: Ana Sayfa |
| Coffee | Tab or Home grid tile |
| Astrology | Tab or Home grid tile |
| Yıldızname | Tab **Yıldızname** or Home grid |
| Tarot | Home grid only (not bottom tab) |
| Palm | Home grid only |
| SoulMate | Home grid (premium mark) |
| OR chat | **Profile tab** (quick actions / OR row) — **not on Home 3×2 grid** |
| Gems | Home banner "MÜCEVHERLER" or header gem capsule |
| Premium | Profile section / premium flows |
| Discovery journal | Profile → journal link |
| Continue previous | Home "kaldığın yer" if visible |

**Watch-list (pre-session, from product audit — not user data):**

- OR is **absent from Home grid**; many users may never find chat in 3 minutes.
- Astrology vs Yıldızname both in tab bar — distinction may blur.
- Gems banner vs Premium — two monetization surfaces.
- Voice mode requires finding OR first, then YAZILI/SESLİ chips above composer.

---

## Report template (fill after live session)

**Participant:** ___ · **Date:** ___ · **Build:** ___ · **Locale:** TR

### Scores

| Gate | PASS / FAIL | Evidence |
|------|-------------|----------|
| First impression | | |
| Understanding (not just "fal app") | | |
| Discoverability | | |
| Memorability (friend description quality) | | |
| Desire to return | | |

### Qualitative

**Confusion points:**  
…

**Strongest feature:**  
…

**Weakest feature:**  
…

**Verbatim — friend description:**  
…

**Verbatim — most curious section:**  
…

**Verbatim — one change:**  
…

### Final product verdict

**PASS / FAIL** — _Requires live blind session. Do not ship on code review alone._

---

## Agent note (Aug 2026)

No live blind participant was available in the development environment. This document is the **official protocol**. Run one session minimum before treating acceptance as complete.
