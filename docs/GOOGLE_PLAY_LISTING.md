# ORACLY — Google Play Production Listing Preparation

**Scope:** Store presentation only. No feature changes.  
**Date:** August 2026  
**Primary locale:** Turkish (tr-TR) · **Secondary:** English (en-US)

---

## 1. App identity verification

| Item | Required | Current state | Action |
|------|----------|---------------|--------|
| **Display name** | `ORACLY` | Manifest label was `oracly_new` | Set `android:label="ORACLY"` before submit |
| **Package name** | Stable production id | `applicationId` in Gradle (verify in Play Console) | No rename at listing stage |
| **Version** | Matches binary | `1.0.0+1` (pubspec) | Align release notes with build |
| **App icon** | Approved ORACLY identity | `@mipmap/ic_launcher` referenced; mipmap assets must exist in repo | Export 512×512 PNG from canonical mark; adaptive layers 1080-safe |
| **Category** | Matches actual product | — | **Lifestyle** (primary). Optional tags: Entertainment, Personalization. **Not** Medical, Finance, or Dating |

**Product positioning:** A calm digital sanctuary for reflection — tarot, coffee cup reading, astrology, star-name (yıldızname), OR conversation, and personal discovery. **Not** fortune-telling certainty, medical advice, or real-world soulmate identification.

---

## 2. Store assets — concept & specification

### 2.1 App icon (512×512)

- **Concept:** Deep midnight field (`#04030A`) with a single engraved gold crystal / observatory mark — same family as Home hero and chamber chrome.
- **Rules:** No text inside icon. No third-party tarot clipart. One focal mark, soft gold rim light, no busy gradients.
- **Deliverables:** 512×512 PNG (Play), adaptive foreground + background layers (Android), preview on dark and light launchers.

### 2.2 Feature graphic (1024×500)

- **Concept:** Wide cinematic still — ORACLY wordmark (small, top or bottom third) over the shared universe: star field, violet haze, one gold geometry arc. Optional faint module silhouettes (cup, wheel, card) at ≤15% opacity — decorative only.
- **Rules:** No screenshot paste-up. No “100% accurate predictions” copy. Readable at phone listing width.
- **Copy overlay (optional, max 6 words TR):** `Dur · Çek · Yansı` or EN: `Pause · Draw · Reflect`

### 2.3 Phone screenshots (8-frame sequence)

**Device profile for capture:** 390×844 logical (e.g. Pixel 6) → export **1080×1920** or **1440×2560** PNG.  
**Locale:** Turkish UI for tr-TR listing; English set for en-US.  
**Data:** Fresh install, onboarding complete, **demo profile name only** (e.g. “Deniz”) — no real emails, API keys, debug banners, or `localhost` URLs.

| # | Frame title | Live screen / route | Recommended state |
|---|-------------|---------------------|-------------------|
| 1 | Home / identity | `HomeReferencePage` via `OraclyAppShell` (Home tab) | Daily ritual visible, 3×2 module grid, gems banner — universe atmosphere on |
| 2 | Coffee | `CoffeeReferenceScreen` (Coffee tab) | Landing chamber — camera/gallery CTAs, no half-uploaded personal photo |
| 3 | Astrology | `AstrologyReferenceScreen` (Astrology tab) | Hub with zodiac tabs; preview note visible if shown in UI |
| 4 | Yıldızname | `StarMapReferenceScreen` (Star Map tab) | Reference hub — honest preview copy, no fake natal math |
| 5 | Tarot | `TarotEpic031Page` / tarot entry | Spread selection (1/3/5/7) or single card reveal — no debug spread labels |
| 6 | OR | `CompanionReferenceScreen` (`/chat`) | Welcome + empty composer or one short **generic** assistant line — no user journal text |
| 7 | SoulMate | `SoulMateDrawScreen` → result | Result with **honesty** line visible (`soulmate.honesty`); symbolic portrait — not “your real partner” |
| 8 | Personal Discovery / Profile | `ProfileReferenceScreen` with discovery **or** `DiscoveryJournalScreen` | Profile: insight card + journal entry row; **or** Journal: timeline with 2–3 seeded demo entries |

**Per-frame quality gate**

- Shows a **shipped** feature (see table — no mock numerology, moon calendar, or unwired settings).
- Clean composition: status bar time generic, full battery, no red error overlays.
- Localized copy readable; no lorem ipsum.
- No debug overlays (`DEBUG`, `PremiumDevOverride`, frame times, proxy URLs).
- No private user data (real names, photos, chat content, reading text from QA accounts).

**Capture aid:** `test/visual/hub_reference_capture_test.dart` captures Coffee, Astrology, Yıldızname at 390×844 — extend similarly for Home, Tarot, OR, SoulMate, Profile.

### 2.4 Promotional imagery (optional)

- **7-inch tablet:** Same eight frames if tablet layout is supported; otherwise omit.
- **Promo video (30s):** Home → single tarot draw → one calm reading beat → OR whisper → close on Profile journal. Voiceover: reflection, not prediction.

---

## 3. Store copy

Tone: **premium · intriguing · clear · honest**

### 3.1 Short description (≤80 characters)

**TR:**  
`Sakin bir evren: tarot, kahve, astroloji, yıldızname ve OR ile yansıma.`

**EN:**  
`A calm universe: tarot, coffee, astrology, star map & OR for reflection.`

### 3.2 Full description

**TR:**

ORACLY, acele etmeden durup kendinle bağ kurman için tasarlanmış sakin bir dijital evren.

Burada tarot çekimi, kahve falı, burç yorumları, yıldızname, OR sohbeti ve keşif günlüğü tek bir zarif ritimde buluşur. Her yorum **sembolik bir yansımadır** — geleceği garanti etmez, tıbbi veya hukuki tavsiye vermez.

**Öne çıkanlar**
- **Evren:** Günlük ritüel, keşif modülleri ve mücevher ekonomisi — sakin, tutarlı bir yer hissi  
- **Kahve & El:** Fotoğrafından sembolik fincan yorumu; kişisel keşiflerinle uyumlu anlatım  
- **Astroloji & Yıldızname:** Burç ve isim temelli **yansıma** deneyimleri — doğum haritası iddiası yok  
- **Tarot:** 1, 3, 5 veya 7 kart; seçimden okumaya kesintisiz ritüel  
- **OR:** Sıcak, düşündürücü sohbet; kararlar her zaman senin  
- **Ruh Eşi:** Sembolik portre ve yaratıcı yorum — gerçek bir kişiyi tanımlamaz  
- **Keşif & Profil:** Cihazında kalan kişisel arşiv; istediğin zaman silme kontrolü  

**Gizlilik**
Keşiflerin ve profilin cihazında saklanır; OR sohbeti veya görüntü analizi için gereken içerik güvenli şekilde işlenebilir. Keşiflerini silebilir, anonim kullanım ölçümünü kapatabilirsin. ORACLY seni izlemek için tasarlanmadı — **yansıtman** için tasarlandı.

**EN:**

ORACLY is a calm digital universe for slowing down and reconnecting with yourself.

Tarot, coffee cup reading, sun-sign reflections, star-name (yıldızname), conversation with OR, and a personal discovery journal share one crafted rhythm. Every reading is **symbolic reflection** — not guaranteed prediction, not medical or legal advice.

**Highlights**
- **Universe:** Daily ritual, discovery modules, gem economy — one consistent sanctuary  
- **Coffee & Palm:** Symbolic readings from your photo, woven with your discovery themes  
- **Astrology & Star map:** Sign- and name-based **reflection** — not a calculated natal chart  
- **Tarot:** 1, 3, 5, or 7 cards; one continuous select → reveal → reading flow  
- **OR:** Warm, thoughtful chat — your choices remain yours  
- **Soulmate:** Symbolic portrait and creative reading — does not identify a real person  
- **Discovery & Profile:** A quiet archive on your device; delete anytime  

**Privacy**
Discoveries and profile stay on your device; content needed for OR chat or image analysis may be processed securely. Clear discoveries, opt out of anonymous usage measurement. ORACLY was built to **reflect**, not to predict.

### 3.3 Feature highlights (Play Console bullets)

1. **Sakin evren** — Günlük ritüel ve keşif modülleri tek zarif akışta  
2. **Tarot ritüeli** — Kart seç, nefes al, oku  
3. **Kahve & el** — Fotoğrafla sembolik yorum  
4. **OR sohbeti** — Sıcak yansıma, net sınırlar  
5. **Senin arşivin** — Keşif günlüğü; silme kontrolü sende  

*(EN mirrors above in en-US listing.)*

### 3.4 Copy — do NOT claim

- Guaranteed future prediction or certainty  
- Real soulmate / partner identification  
- Medical, psychological, or legal diagnosis  
- Official natal chart / ephemeris accuracy (where preview honesty applies)  
- Streak pressure, spiritual rank, or fear-based retention  

---

## 4. Privacy & permissions (listing must match app)

| Claim in listing | In-app behavior |
|------------------|-----------------|
| Data on device | Readings, journal, settings via local storage |
| Delete anytime | Privacy screen + history delete flows |
| Optional analytics | `analyticsEnabled` toggle; anonymous metadata only |
| AI is reflection | `TransparencyCopy`, trust footnotes in readings/chat |
| Camera / photos | Coffee & palm input only — manifest permissions |
| Notifications | Optional daily ritual — user-controlled in settings |
| No sale of reading text in analytics | `ProductAnalyticsParams` blocks message/content keys |

Link Play **Privacy policy URL** (required) — must describe local storage, optional Firebase/analytics, AI proxy processing for features that use cloud AI, and deletion rights.

---

## 5. Pre-submission checklist

- [ ] `android:label` = `ORACLY`
- [ ] Launcher icon mipmap set present and matches brand
- [ ] Eight screenshots captured from live routes (table §2.3)
- [ ] Feature graphic 1024×500 exported
- [ ] Short + full description pasted (TR + EN)
- [ ] Category: Lifestyle
- [ ] Content rating questionnaire completed honestly (AI-generated content, symbolic themes)
- [ ] Privacy policy URL live
- [ ] No financial A/B experiments in production config

---

## 6. Final assessment

| Gate | Status | Notes |
|------|--------|-------|
| **STORE ASSETS** | **FAIL** | Spec complete; **icon mipmap set missing** in repo; feature graphic & screenshots not yet exported |
| **SCREENSHOTS** | **PASS** (spec) | Eight-frame plan uses **only implemented screens**; quality rules defined; assets not captured yet |
| **COPY** | **PASS** | TR + EN short, full, highlights ready; tone premium and honest |
| **HONESTY** | **PASS** | No prediction/soulmate/medical claims; aligns with `TransparencyCopy` and in-app preview notes |

**Overall:** Listing **copy and screenshot plan are production-ready**. **Binary identity assets (icon, label, exported PNGs) must be completed before Play upload.**
