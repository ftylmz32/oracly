# P2 — Home product quality

Live path audited: `OraclyAppShell` → `HomePage` → `HomeMasterPage` → `HomeMasterBody`.
Legacy Home widgets were not treated as live.

## Truth table

| Door | ID | TR title | Asset | Premium | Destination |
|---|---|---|---|---|---|
| Coffee | `coffee` | Kahve Falı | `home_coffee.webp` | no | Coffee |
| Palm | `palm` | El Falı | `home_palm.webp` | no | Palm |
| Astrology | `astrology` | Astroloji | `home_astrology.webp` | no | Astrology |
| Yıldızname | `starMap` | Yıldızname | `home_yildizname.webp` | no | Yıldızname |
| SoulMate | `soulMate` | Ruh Eşi | `home_soulmate.webp` | yes | Premium gate, then SoulMate |
| Tarot | `tarot` | Tarot | `home_tarot.webp` | no | Tarot |
| Dream | `dream` | Rüya Analizi | `home_dream.webp` | no | Dream |

EN and RU titles exist for each door. Registry availability for all seven is live. Navigation goes through `OraclyFeatureNavigation.open`.

## Findings

| Surface | Observation | Defect | Severity | Fix | Test |
|---|---|---|---|---|---|
| Dream badge | `isNew: true` was permanent. No flag, launch record, or expiry defines Dream as new. | YES | stale badge | Badge removed. | `home_discovery_modules_test`, `home_product_contract_test` |
| Optional cards | Continue and NextAction were inserted after `requiresScroll` was decided. A stack that just fit overflowed once those cards appeared. | YES | layout | Their heights now count in the scroll decision. | `home_product_contract_test`, `home_optional_cards_layout_test` |
| Premium loading | Before `loaded`, a configured store showed the join banner. An unconfigured store showed “store not open” before any reconcile. | YES | honesty | Unloaded Home copy is `premium.loading_body`. The button says preparing, not join. | `home_product_contract_test` |
| OR and Premium cards | The whole card and the nested CTA were both buttons for the same action. | YES | accessibility | Nested CTA stays tappable and is excluded from semantics. | existing Home hierarchy tests |
| Art, routes, copy | Seven doors match id, asset, Turkish title, and a live route. No Star Map leak on Home. | NO | — | — | `home_product_contract_test` |
| OR route | Card and CTA both open `/chat`. A second tap sees the route already on top and does not push again. | NO | — | — | navigation service `_isTopNamedRoute` |
| SoulMate first session | `quietPremium` hides the crown mark. The registry still requires Premium, and the tap still gates. RC-012 keeps first-session commercial noise down. | NO | — | kept | contract test covers both mark states |
| Daily ritual | `HomeTodayTrace` wraps the real date-keyed ritual card. No score. | NO | — | — | existing daily ritual Home tests |
| Continue | Resolver uses an unfinished Tarot session, an unanswered OR turn, or an onboarding draft. Empty result hides the button. | NO | — | — | crowded-layout test shows it only when overridden |
| NextAction | Card renders only when `hasEvidence`. Dismiss writes memory and does not invent a replacement. | NO | — | — | existing `home_oracle_next_action_test` |
| See all | Opens `UniverseMapSheet`. Reserved modules are filtered out. Live and preview entries use the same navigation bridge. | NO | — | — | registry filter `isLive \|\| isPreview` |
| P1 atmosphere | Hero and page wash still read `OraclyUniverseScope`. | NO | — | — | `home_ritual_atmosphere_test` |

## Unchanged by design

- SoulMate crown is hidden on a first session and shown afterward. The gate remains.
- The discovery grid stays 3×2 plus the Dream strip.
- OR keeps both the card tap and the visible CTA. TalkBack gets one button.
- Night and day Home lighting from P1 is untouched.
- Loaded, non-Premium, store-unavailable copy still says the store is not open. That state is reached only after `loaded`.
