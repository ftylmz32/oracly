# P4E — Premium, Gems, and Daily Rewards product quality

Evidence from the live paths only. Start HEAD `05f151f936db47cb3530a706040e916c24c550cf` on `fix/final-product-remediation-20260922`. P4D / P4D.1 / P4D.2 were not reopened.

## Confirmed defects

1. **Stale Premium repository.** `premiumRepositoryProvider` allowed access whenever the current Firebase uid equalled the current local owner. An instance created for owner A became allowed again after A→B, because both live and local were then B. A later `grant` could write credentials, the active plan, and the profile premium flag into B.

2. **Purchase and restore after switch.** `PremiumService.purchase` and `restore` verify outside local storage, then `PremiumGrantPolicy.grant` writes credentials, activates the plan (active marker last), and mirrors the profile. That local commit was not bound to the owner captured when the repository was built, and it was not inside the existing owner mutation gate.

3. **Disposed Premium controller.** `premiumStatusProvider` is invalidated on account switch. Async `load`, reconcile, purchase, restore, and review access called `notifyListeners` with no disposed guard.

4. **Review access leak and English chrome.** A granted review code was persisted after the network call with no owner re-check, so A's grant could land after B committed. Review access does not write purchase credentials. The live Premium link and `ReviewAccessSheet` used raw English.

5. **Gem cache write vs switch.** `GemWalletStore.cacheServerBalance` removed the cache, wrote the owner marker, then wrote the balance as separate awaits. An owner check around the method did not stop a write that had passed the check and not yet mutated from landing after B's wipe.

6. **Daily Rewards screen.** The screen kept `_state`, `_loading`, `_loadFailed`, and `_busy` and did not listen for the account-switch epoch. A's claimed day stayed on screen after A→B until the screen was reopened.

7. **Daily claim after switch.** `claim()` wrote `daily_reward_claimed_on` and could call `incrementStreak()` after `claimDaily` returned, without re-checking the owner captured before the request. `_claimedDayInMemory` lived on a service that was not owner-bound, so B could inherit A's same-day claimed status.

8. **Daily claim local flag.** A throw from the UX-cache `setString` was caught by the outer `catch` and reported as a failed server grant even though the server had already applied the reward.

9. **Daily Rewards overflow.** At 320×568 and text scale 1.4 the claim button sat in the gift row and overflowed by a fraction of a pixel.

## Fixes

- Premium repository access is `capturedOwner == liveOwner == localOwner`. The captured uid is the Firebase uid at construction.
- Store verification stays outside the owner gate. `PremiumGrantPolicy.grant` enters `runOwnerScopedMutation` and returns false without writing when the captured owner is no longer current. Purchase and restore then surface unverified, not granted.
- `PremiumStatusController` does not notify after dispose. The Premium screen drops purchase/restore snackbars and invalidation when the account-switch epoch moved.
- Review-access persist and revocation enter the same gate and re-check the captured owner. No purchase credential is written.
- Review access copy is in the Premium TR/EN/RU table.
- Gem server-balance cache commits inside the owner gate. The wallet passes `stillOwner`. Network balance and commands stay outside the gate.
- Daily Rewards listens to `accountSwitchEpoch`, clears A immediately, and ignores a late load or claim whose epoch no longer matches. The service captures the owner before `claimDaily`, then commits the UX flag and streak only inside the gate when that owner is still current. In-memory claimed day is owner-bound.
- A thrown UX-cache write does not turn a server grant into `DailyRewardClaimFailure`. The server ledger remains authoritative. An idempotent replay does not increment streak.
- The daily claim button is full width under the gift amount so 320×568 at text scale 1.4 does not overflow.

## Not a defect / no production change

`GemsRewardedAdCard` is not constructed anywhere except its own file. It is not on the live Gems screen. No rewarded-ad production change. No real ad call.

Gem history is `ref.watch(gemWalletProvider).history`. Account switch already invalidates that provider after the wipe. A disposed controller does not notify. A recreated controller reads storage and does not keep A's lines.

Owner-wipe key coverage was not changed. Economy values, store product IDs, and backend contracts were not changed.

## Local daily-claim contract

`daily_reward_claimed_on` is UX state. The server ledger is authoritative.

- Server success + durable local flag: claimed in this session and after restart.
- Server success + local write returns false: still claimed in this session via memory. Restart asks the server again. The replay is idempotent and does not increment streak.
- Server success + local write throws: still a successful claim. Streak increments once for a genuine applied reward. A later idempotent replay does not increment again.
- Owner changed before the local commit: no flag, no streak, no success snackbar for B.

## Plans

Android: monthly, yearly, lifetime. iOS: monthly and yearly. Lifetime is not purchasable on iOS.

## Tests

Fakes only. No store transaction, no provider call, no deploy.

Red-team coverage:

- stale Premium repository after B is current
- purchase result after A→B
- restore result after A→B
- gem cache `remove` held before mutation, switch stays queued, A's balance does not survive B
- mounted Gems history drops A's line when the provider is recreated
- mounted Daily Rewards clears A's claimed state on the epoch
- daily claim response after A→B does not mark B or increment B's streak
- in-memory claimed day does not follow the new owner

## P4E.1 — GLOBAL REGRESSION GATE CLOSURE

Start HEAD `73a6a6f1764301a57ef07c93675b7e0e3de8f6c1`. P4E economy behavior was not redesigned.

### UserRepository compile regression

P4D.1 added `UserRepository.renameDisplayName` with a concrete body. Dart `implements` does not inherit that body. The full suite stopped compiling at `_FlakyUserRepository` in `test/features/tarot/tarot_reading_autosave_reliability_test.dart`.

Every `implements UserRepository` type was scanned:

- `MockUserRepository` already implements the method. Production contract unchanged.
- `_FlakyUserRepository` now delegates to the wrapped repository.
- Seven `_StubUser` fakes have no backing repository. They now throw `UnsupportedError('renameDisplayName')`, matching the interface default. They previously compiled only because `noSuchMethod` hid the missing member.

Tarot production was not changed. The autosave file passes (23 tests).

### Palm

File: `test/features/reading_operation/server_owned_completion_client_test.dart`.

Test: `(E) LIVE INCIDENT REGRESSION -- Palm`.

Assertion: `expect(restarted.phase, PalmPhase.result)` observed `PalmPhase.error`.

Log: `[PalmAnalysis] stage=restore kind=unknown failed`.

The server-owned payload was `{overall, takeaway}` with no `_handSide`. `PalmHand.fromWire` returned null, and `_restoreServerCompleted` fail-closed with `hand_side_missing`. That is the frozen missing-hand rule. Classification: test fixture contract drift. Reproduced alone before the fixture change. The fixture now includes `'_handSide': 'right'`. Palm production was not changed.

After the fixture change: the isolated test passes, the file passes (5), and `test/features/palm` passes (93), including missing-hand fail-closed and exact-operation recovery.

### Home badge assertions

Completing the suite also failed two Home tests that expected one widget with text `Yeni`. No `HomeReferenceModuleSpec` sets `isNew` after `898ca41f`. Those expectations now use `findsNothing`. Home production was not changed.

### Full suite

Completed. 6379 passed, 16 skipped, 7 failed.

Skips are existing gates: `ORACLY_E2E=1`, the release-manifest test, and the local shadow-corpus dump.

The 7 failures are Yıldızname golden pixel diffs on the pre-existing dirty star-map worktree. They were not caused by this gate, and that worktree was not edited or staged. Because those failures remain on the working tree, P4E is not final frozen.

`flutter analyze --no-fatal-infos`: 0 errors, 0 warnings, 212 pre-existing infos.

## P4E.4 — YILDIZNAME DETERMINISTIC GOLDEN CLOSURE

Start HEAD `e39f9003a7c2760583bf33c470415f297cc7aac0`.

### P4C Row → Wrap provenance

Commit `7ab1bf3075b45eeb49c9c66445243166c7953748` changed `SaveFavoriteMomentLink` from `Row` plus `SizedBox(width: 6)` to `Wrap` (`alignment: center`, `spacing: 6`) so the favorite action stays usable at small widths and large text. Live production stays on that wrap.

### Favorite pixel bound

On production Wrap, the seven Yıldızname goldens differed by 656 or 659 pixels. The changed pixels sat in the favorite action (bookmark icon and “Bu anı kaydet”), x = 144..249.

Historical 7A–7F masters now render that action through a test-only `forensicLegacyRow` path and pass unchanged. The two final-production 7G masters that use the live footer were refreshed. Each differs by exactly 659 pixels, all inside x = 144..249:

- `final_legacy_live_all_actions_390.png` bbox (144,692)–(249,708)
- `final_legacy_artifact_reopen_390.png` bbox (144,717)–(249,733)

No pixel outside that band. No background, scope, fact, status, order, or other typography delta.

### Test-order image cache

Phase 7G pumps already precached `AppAssets.yildiznameArchiveBg` and `AppAssets.yildiznameHero`. The 7A–7C pumps did not. An isolated `--name` run therefore captured a cold archive frame (about 96–99% of the frame). The same test passed in file order because a predecessor had warmed `ImageCache`.

Historical pumps now precache those two assets before capture. Masters that were frozen as the cold first frame of their file, and all of Phase 7F, opt out so their existing PNGs stay valid. Isolated and file-order runs agree. Matcher tolerance is unchanged.

### Forensic layout

`SaveFavoriteMomentLink.forensicLegacyRow` defaults to false. Production uses Wrap. The forensic footer requests the pre-P4C Row. The production footer does not. Save, unsave, label, tap, semantics, and the 44px target are the same for both layouts. Production action order is unchanged: OR → Share → Favorite → Copy → Continue → Feedback. Forensic order is unchanged: Copy → Share → OR → Continue → Favorite → Feedback.

### Hashes

- `final_legacy_live_all_actions_390.png` `c0b609ea9df081e71d94328c105266ca663eb0543fa6f6615d48588e5b5bc5e6` → `ba3c76198b8716200f249e07cb3d6f095cf95a6797a0ac71f2f191082253d428`
- `final_legacy_artifact_reopen_390.png` `1c7a8303b692ac1bceb1d046e35ffd0c7e87be4638e7ae0954027d3b3f472714` → `dafb73b6397caf742e6b421d3f57eff1af4c0b0a62db45c8d8a0aa9151c61247`

The other 15 Phase 7G hashes are unchanged. Historical 7A–7F PNG inventories are unchanged. Phase 7H claims are unchanged.

### Regression

- Yıldızname visual directory: 79 passed, 0 failed, twice (file order), plus isolated cold runs of the previously order-sensitive historical tests.
- `test/features/star_map`: 792 passed, 0 failed.
- P4C favorite, P4E premium / gems / daily rewards / owner switch, P4D, P4D.2, P4C.1, user-data isolation, Tarot autosave, Palm server-owned completion, and full Palm: 218 passed, 0 failed in one invocation.
- Full `flutter test` on a detached tree of this change, with the same gitignored local fixtures the primary checkout uses (`tool/dart_defines.production.json`, `tool/e3e_private`, Firebase config files): 6391 passed, 16 skipped, 0 failed.
- `flutter analyze --no-fatal-infos`: 0 errors, 0 warnings, 212 infos.
