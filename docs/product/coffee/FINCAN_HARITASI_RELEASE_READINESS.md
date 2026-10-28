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

## 2. Where photos, pins and notes live and why

One app-private directory. Dart derives its path with `path_provider` (iOS:
Application Support; Android: the files dir's parent + `no_backup`), so reads,
deletes and wipes need no platform call. Only backup exclusion crosses the
`app.oracly/cup_map_storage` channel (`MainActivity.kt`, `AppDelegate.swift`),
and the native side accepts a path only inside the directory it computes
itself — a mismatch answers `false` and nothing is kept:

| | Android | iOS |
| --- | --- | --- |
| Directory | `Context.getNoBackupFilesDir()/coffee_cup_map` | `Library/Application Support/coffee_cup_map` |
| Evicted by the OS to free space? | No (not a cache dir) | No (Application Support is not purged) |
| Backup exclusion | `no_backup` is skipped by Auto Backup and device transfer; also stated as a narrow `<exclude domain="root" path="no_backup/coffee_cup_map/"/>` in `backup_rules.xml` and both sections of `data_extraction_rules.xml` | `URLResourceValues.isExcludedFromBackup = true` on the directory and on every file written into it; re-applied after each atomic replace |
| How the app checks | `isExcludedFromBackup` = canonical path strictly inside that directory | `isExcludedFromBackup` reads the resource value back |

Contents: `photo_*.jpg` (the three reading photos) and `maps_v1.json`
(owner, reading id, photo paths + SHA-256, pins, notes).

- **Fail closed on exclusion.** A photo is kept only after the platform
  confirms exclusion; otherwise the copy is deleted and nothing is kept. The
  map file is written to `maps_v1.json.tmp`, confirmed excluded, then
  renamed over the old file; if exclusion is not confirmed the old file is
  left exactly as it was.
- **Pins and notes are no longer in SharedPreferences** (which Android Auto
  Backup and iOS backups include). Only the keep-photos choice
  (`coffee_cup_map_consent_v1`, owner-stamped, a setting) stays there.
- **Migration from `2e85526d`** (prefs key `coffee_cup_map_v1` + photos in
  `{cache}/coffee_cup_map`): on first use each cache photo still present is
  copied, excluded and checked against its recorded SHA-256; already-evicted
  photos keep their old path (shown as missing, pins kept). Old data is
  removed only after the new file is written; any failure removes this
  run's copies, leaves the old data untouched and retries next time.
- **Not synced, not restored.** A new phone, a reinstall or an app-data
  clear does not bring maps back; the copy says so.
- **No encryption claim** beyond the OS app sandbox / iOS data protection.
- **Not uploaded again.** Keeping the photos does not change what is sent for
  the reading (still exactly 2 cup views + 1 saucer, unchanged contract).

### Evidence

- Android: `flutter build apk --debug` compiled the bridge (no install).
  `aapt2 dump xmltree` of the built APK shows both rule files carrying
  `no_backup/coffee_cup_map/` and the manifest pointing at them; the channel
  name and `getNoBackupFilesDir` are in the compiled DEX.
- iOS: **not compiled or run** (no macOS here). The Swift is unverified until
  an Xcode build and a device check of the resource value.
- Dart: a fake bridge with the same contract proves the fail-closed paths,
  the audit that every file in the directory is excluded, restart and
  cache-purge survival, and migration (section 6).

## 3. Ownership and deletion matrix

| Event | Photos | Map (pins, notes) | Keep-photos choice |
| --- | --- | --- | --- |
| User deletes one map | deleted first (fail-closed) | removed once its photos are gone | unchanged |
| Discovery history clear | every file in the directory + old cache purged (best effort) | removed with the directory contents | unchanged (a setting) |
| Account switch / logout / account deletion (`UserLocalDataWipe`) | every file + old cache purged; anything left is reported | removed | deleted |
| Another owner signed in | never shown | never shown or changed | read as off |
| Uninstall / app-data clear | removed with the app sandbox | removed | removed |

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
> only**, in the app's private storage, so you can return to them and add your
> own marks and notes. They are not sent to ORACLY again and are not part of
> the server retention above. Your marks and notes are stored on your device
> only. You can delete one reading's map (its photos, marks and notes) from
> the map screen; clearing reading history, account deletion, logging out /
> switching account, or uninstalling the app also removes them. They are not
> synced or included in device backups, so they do not come back on a new
> device or after reinstalling. The setting is off unless you turn it on, and
> turning it off applies to readings completed afterwards.

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
