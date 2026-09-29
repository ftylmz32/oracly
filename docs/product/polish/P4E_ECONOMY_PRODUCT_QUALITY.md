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
