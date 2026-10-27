# Fincan Haritası — privacy, deletion and release visibility

Branch `feat/coffee-v3-fincan-haritasi-20261027`. Local evidence only: no
device, iOS build, store, Firebase, App Check, AI or purchase call was made.
Nothing here says the feature is App Store ready.

## 1. What the user gets

| Step | Real behavior |
| --- | --- |
| Before sending a Coffee V3 reading | The review screen shows "Fincan Haritası için fotoğraflarımı sakla" with the explanation. The switch is **off** until the user turns it on. |
| Switch off (default) | Exactly the existing V3 flow: the three working photos are deleted once the result is saved; no map, no door on the result. |
| Switch on | When the result of that same operation is restored, its three photos are re-verified (owned V3 working copy, size, SHA-256) and copied to the cup-map archive before V3 deletes its working copies. Best effort, 10 s cap; the reading never waits on it. |
| Result / history | A "Fincan Haritası" card appears only for a reading that has a map with at least one photo still on the device. |
| Map | Zoom/pan the real photos, place up to 12 pins per photo, optional note (max 240), edit/delete pins. Nothing is detected or labelled by the app. |
| Delete one reading's map | "Bu falın haritasını sil" → confirmation → photo files deleted first, then the map record (pins and notes). If a file cannot be deleted the record stays as its locator and the user is told. The reading text stays. |
| Turn keeping off | The same switch at the bottom of the map. It applies to readings completed from then on; existing maps stay until deleted. |

## 2. Where the photos live and why

`{app cache dir}/coffee_cup_map/` (`path_provider.getApplicationCacheDirectory`:
Android `Context.getCacheDir()`, iOS `Library/Caches`).

- **Backups.** Platform documentation excludes these directories from Android
  Auto Backup / device-to-device transfer and from iCloud / Finder device
  backups. This is a documented platform behavior, **not verified on a
  device in this work**. The previous location (`coffee_images` in the
  documents directory) is included in both platforms' backups — the app's
  `backup_rules.xml` / `data_extraction_rules.xml` only exclude
  `FlutterSecureStorage.xml` — so the map no longer uses it.
- **Trade-off.** The OS may delete cache files to free space; the map then
  shows "Bu fotoğraf artık cihazında değil" and keeps the pins listed.
- **Metadata** (`coffee_cup_map_v1`: owner, reading id, photo paths and
  checksums, pins, notes) and the choice (`coffee_cup_map_consent_v1`) live in
  SharedPreferences, which Android Auto Backup includes. A restored record
  without its photos degrades as above; it is never shown to another owner.
- **Not encrypted at rest beyond the OS sandbox.** No such claim is made.
- **Not uploaded again.** Keeping the photos does not change what is sent for
  the reading (still exactly 2 cup views + 1 saucer, unchanged contract).

## 3. Ownership and deletion matrix

| Event | Photos | Map (pins, notes) | Keep-photos choice |
| --- | --- | --- | --- |
| User deletes one map | deleted (fail-closed) | deleted | unchanged |
| Discovery history clear | whole archive purged | deleted (kept as locator if purge fails, clear reports failure) | unchanged (a setting) |
| Account switch / logout / account deletion (`UserLocalDataWipe`) | whole archive purged | deleted (kept + reported if purge fails) | deleted |
| Another owner signed in | never shown | never shown or changed | read as off |
| Uninstall | removed with the app sandbox | removed | removed |

All of the above is covered by tests (section 6).

## 4. Why `coffee_v3_three_view` is off by default

`CoffeeV3CreationGate.creationAllowed = rolloutEnabled && Turkish UI`, where
`rolloutEnabled = bool.fromEnvironment('ORACLY_COFFEE_V3_ENABLED') ||
remote flag coffee_v3_three_view`. The remote flag is a dark, new-key rollout
switch so that no value ever set for the retired four-view key can switch V3
on; the build define is the explicit path for store builds. The backend keeps
its own `ORACLY_COFFEE_V3_ENABLED` gate.

The flag is not the only gate on a NEW V3 reading:

1. **Build define.** The local production defines file already sets
   `ORACLY_COFFEE_V3_ENABLED=true`. A review build must be made from it (or
   equivalent) — no hidden menu, no debug override.
2. **Turkish UI.** V3 is Turkish-only. A reviewer on an English device
   gets the default Coffee V2 flow and never sees the map unless the app
   language is set to Türkçe (onboarding language choice / Settings → Dil).
3. **A coffee reading right.** Since `de859a39` a fresh coffee capture
   needs a coffee credit: the intro opens the reading-rights screen, which
   only offers "continue" with a credit. With commerce closed the screen
   says purchases are closed and offers no way forward.
4. **Server.** Production serving revision checked read-only:
   `ORACLY_COFFEE_V3_ENABLED=true`, `ORACLY_READING_COMMERCE_ENABLED` absent
   (= off), `ORACLY_READING_TRIAL_ENABLED` absent (= off). The serving code is
   older than the client source here.

**Consequence:** with today's production server a reviewer cannot start a
Coffee V3 reading, so cannot reach Fincan Haritası. Making it reachable
honestly requires one of: (a) open commerce in production with live App Store
consumables that the reviewer buys in sandbox, or (b) a product decision for a
legitimate free first coffee reading (the existing trial flag) — either is a
production/business change outside this branch and was not made.

## 5. How a reviewer reaches the feature (once section 4 is resolved)

1. Install the review build; set app language to **Türkçe** if the device is
   not Turkish (Ayarlar → Dil).
2. Ana Sayfa → **Kahve Falı** → "Başlayalım" → get a coffee reading right on
   the next screen (purchase in sandbox, or the free first reading if
   enabled).
3. Photograph the cup interior from one side, turn it about half a turn and
   photograph the other side, then the saucer (3 real photos).
4. On "Son bir kontrol", turn on **"Fincan Haritası için fotoğraflarımı
   sakla"**, choose an intention, tap **"3 Fotoğrafı İncele"**.
5. Wait for the real reading. Below the reading, tap **"Haritayı aç"**.
6. Pinch to zoom, tap a spot to place a pin, add a note, reopen the reading
   later from Keşif Günlüğü — the pins and notes are there.
7. "Bu falın haritasını sil" removes that reading's photos, pins and notes.

## 6. Local verification

- `test/features/coffee/cup_map/` — store, keeper, consent, deletion,
  owner isolation, V3 handoff through the real controllers, real V3 screens
  end to end with the fake backend (opt-in and opt-out), map UI geometry,
  accessibility, 320 px / 2x text, account wipe and discovery clear.
- `test/visual/coffee_cup_map_capture_test.dart` — real-widget screenshots
  when `CUP_MAP_CAPTURE_DIR` is set.

## 7. Proposed text (not published; legal review needed)

### Privacy policy — add under "Images and content submitted for readings"

> **Fincan Haritası (optional).** If you turn on "Fincan Haritası için
> fotoğraflarımı sakla" before sending a coffee reading, the two cup photos
> and the saucer photo of that completed reading are kept **on your device
> only**, in the app's cache storage, so you can return to them and add your
> own marks and notes. They are not sent to ORACLY again and are not part of
> the server retention above. Your marks and notes are stored on your device
> only. You can delete one reading's map (its photos, marks and notes) from
> the map screen; clearing reading history, account deletion, logging out /
> switching account, or uninstalling the app also removes them. Your device's
> operating system may remove the stored photos to free up space. The setting
> is off unless you turn it on, and turning it off applies to readings
> completed afterwards.

### Privacy policy — "Local storage" list, add

> - Fincan Haritası photos, marks and notes (only if you turned the option on).

### App Store Connect — App Privacy

No new data type is **collected** (stored off-device) by this feature; the
coffee photos are already declared for the reading itself. Local-only storage
does not change the App Privacy answers. Re-check before submission.

### App Review notes (English, draft)

> Fincan Haritası lets users revisit the exact three photos their Turkish
> coffee reading was made from and place their own marks and notes on them.
> It is opt-in ("Fincan Haritası için fotoğraflarımı sakla" on the last
> review screen), stored on the device only, and can be deleted per reading.
> The app does not detect or label symbols on the photos. Steps: set app
> language to Türkçe, Home → Kahve Falı, take three photos, turn the option
> on, submit, then "Haritayı aç" under the reading.
