# P4D — Profile + Settings product quality

Start HEAD: `a56fd2cf3da184d66318e100d3e7099a1f38a711`
Branch: `fix/final-product-remediation-20260922`
P4C + P4C.1 left frozen. No Daily / Insights / Memory persistence change.

## Live paths

Profile: shell Profile tab → `ProfileReferenceScreen` → `ProfileReferenceBody` → `ProfileReferenceScrollStack`.

Settings: `OraclyNavigationService.openSettings` → `/settings` → `SettingsReferenceScreen` → `SettingsReferenceContent` → `SettingsReferenceBody`.

`ProfileReferenceMembershipCard` is not constructed anywhere outside its own file. It stays unused. Its hardcoded Turkish strings were not edited.

## Confirmed defects

1. Continue-where-you-left-off owner leak. `continueWhereYouLeftOffProvider` is a non-autoDispose `FutureProvider` that `ref.read`s storage and does not watch the owner epoch. `PrivacyDataRefresh.afterAccountSwitch` did not invalidate it. Profile rendered `.valueOrNull` above the discovery loading block, so owner A’s resume CTA stayed visible after A → B.
2. Settings profile name stayed in widget state. `_profileName` loaded once from `userRepository.getProfile()` and did not follow `localDataOwnerEpochProvider`.
3. Settings load captured `mounted` as a bool. After dispose, the helper still treated that snapshot as true and could `setState` or snackbar.
4. Settings cold-open treated `premiumStatus.isPremium` as fact while `PremiumStatusController.loaded` was still false, so an unresolved entitlement rendered as Standard.
5. Settings save completion wrote the in-flight result back over a newer toggle, and the `settingsProvider` listener did the same while a save was unsettled.
6. `UserProfileNotifier.saveName` could finish a profile write after the owner epoch had already moved.

## Fixes

- Resume provider watches `localDataOwnerEpochProvider` and returns null if the epoch changed before publish. `PrivacyDataRefresh.afterAccountSwitch` invalidates it. Profile hides the CTA while the provider is loading, including a refresh that still holds the previous value.
- Profile `userProfileProvider.when` does not skip loading on refresh, so owner A’s name is not kept on screen while B resolves.
- Settings listens to the owner epoch, clears the visible name, and reloads. A load started under A cannot publish after the epoch moves. `isMounted()` is read after each await. Snackbars also require `context.mounted`.
- Settings membership badge and the Premium subtitle render only when `premiumStatus.loaded` is true. Review access still uses canonical `isPremium`. Profile Premium/Gems footer still receives `premium.loaded`.
- Each settings save has a generation. An older save does not apply audio correction, notification rollback, or snackbars after a newer edit. The provider listener does not overwrite an unsettled edit.
- `saveName` checks the owner epoch before and after the write. If the epoch moved and the stored name is still the in-flight name, that write is cleared and not refreshed into the new owner.

Device `settings_*` values are not wiped.

## Evidence

- Late owner A tarot session `session-owner-a` resolves, then the epoch bumps while a second read is held. The published target is null. The session id is not on the button.
- Profile hides “Devam Et” on the epoch bump, before the held read completes, and after a real `onSignedIn` A → B wipe.
- Open Settings shows “Owner A” and a photo file. After a completed A → B switch the name is “Yolcu” and the avatar photo is null. Photo epoch bump matches the existing `PrivacyDataRefresh` host. Device settings are untouched.
- A held Settings load that completes after the screen is removed does not throw `setState` after dispose and does not snackbar.
- Unloaded Premium shows no Standard/Standart badge. After load, active and review-access show Premium. Inactive shows Standart (Turkish settings language).
- Sound off, then on, while the first atmosphere apply is held: the switch ends ON.
- Profile and Settings at 320×568 with text scale 1.4 throw no layout exception.

## Not reopened

P4C daily / insights / memory contracts, OR conversation, Premium verifier, billing, owner-wipe architecture, auth architecture, backend.
