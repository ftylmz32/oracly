# P3E — Astrology product quality

Live path: Home → `OraclyFeatureNavigation` → `OraclyNavigationService.openAstrology` → `OraclyRoutes.astrology` → `AstrologyReferenceScreen` → `AstrologyReferenceScreenView`.

This is the local sun-sign daily reading. It is not Birth Chart, Star Map, or Yıldızname, and it does not call a provider.

Detail opens `AstrologyReferenceDetailScreen` from the hub CTA. A second tap is ignored while the first route is still opening.

## Findings

| Surface | Observation | Defect | Severity | Fix | Test |
|---|---|---|---|---|---|
| Profile gate | The hub set `isLoading` while `personalDiscoveryProfileProvider` was still loading and had no value. The sun-sign reading is built locally from sign and calendar day. The screen comment already said the local reading does not depend on profile load. A stalled profile kept the whole hub on the loading cinema until the 28s retry. | YES | High | Loading waits only for sign restore. Theme labels arrive when the profile does. A missing profile still shows the base reading. | `astrology_reference_loading_retry_test` |
| OR chrome | The OR header shows source, deck, and summary. Astrology hardcoded `Astroloji`, `Burç Yorumu`, `Burç:`, and `Günlük` for every language. | YES | Medium | Those labels use `home.discovery.astrology.title` and `astro.or.*`. The reading body is not translated. | `astrology_p3e_polish_test` |

## Unchanged by design

- Sign order stays birth-chart sun, then a saved browse choice, then Aries. An unknown saved id is ignored.
- The daily tone uses the local calendar day (`year`, `month`, `day`), not a UTC date string.
- Personalization still overlays real themes. Empty history does not invent an inner theme. The presentation already hides the insufficient placeholder.
- The sky section states sun-sign support and does not present Moon, Ascendant, or houses as calculated facts.
- Detail still opens one route. The selected sign is captured when the CTA is tapped.
- Share, favorite, and continuation still use the reading already on screen.
- Birth Chart, Star Map, Yıldızname, prompts, and the backend were not edited.
