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

## P4D.1 — OWNER-SAFE DURABLE PROFILE RENAME

Independent verification after the first P4D report found the rename race still open. The epoch check above called `saveProfile`. That method writes `profile_name`, `user_name`, job, interests, goals, streak, readings, spiritual level, favorite deck, and achievements in sequence, and it ignores a `LocalStorage` result of `false`. Clearing the name when the stored string matched the attempt could keep those leaked fields, and it could erase a later owner's legitimate name when the strings were the same.

P4D's other fixes stay as the accepted base. This repair starts from `88866ae83fbfa9422826dfb1a52ad3d9f3d6e7e6`.

### Repair

- A rename calls `renameDisplayName`. It writes only `profile_name` and `user_name`.
- `stillOwner` is read immediately before each of those writes and before any rollback. After the owner epoch moves, the operation stops. It does not treat a matching name string as proof of ownership.
- `false` and thrown name writes fail through `requireDurable`. While the same owner is still current, a failed second write restores the previous name pair so the two keys do not stay split. Profile still shows `ResilienceCopy.genericLoadFailed`. A successful rename refreshes only when the epoch is unchanged.

### Evidence

- A rename is held after `profile_name` is written. A real `UserLocalDataIsolation.onSignedIn` then wipes owner A and commits owner B. When the held rename resumes, B storage has no owner A name, `user_name`, job, interests, goals, streak, readings, spiritual level, favorite deck, or achievements. The notifier does not publish the in-flight name.
- Owner B's legitimate name `Alex` remains `Alex` when owner A's held rename to `Alex` resumes.
- A false `profile_name` write, a false `user_name` write, and a thrown `user_name` write leave both keys on the previous name. The Profile screen shows the existing failure copy. An unchanged name performs no durable write.

## P4D.2 — PROFILE RENAME / ACCOUNT SWITCH ATOMICITY

Independent verification after P4D.1 found one remaining race. `stillOwner()` ran before and after each awaited storage call. A `setString` future could be in flight, with the value not stored yet, while `onSignedIn` finished the wipe and committed owner B. Releasing that future then wrote owner A's name into B. The P4D.1 hold sat after the value was already stored, so it did not show this.

This repair starts from `4ca6d959b30a057e26ead3d548b15cb67c320511`. The narrow rename and `requireDurable` behavior stay.

### Repair

`UserLocalDataIsolation.runOwnerScopedMutation` is the same gate `onSignedIn` uses for its wipe, owner commit, and epoch bump. Profile rename enters that gate and reads the captured owner epoch again before any name write. The instance single-flight queue is unchanged. A waiting switch cannot pass an active rename, and a rename that enters after B is committed writes nothing. Rollback of a failed second key stays inside the gate, so it cannot repair owner B's storage.

### Evidence

Before the gate, a `profile_name` future and a `user_name` future held before mutation both left `A-RENAMED` in B after a real `onSignedIn('owner-b')`.

After the gate:

- Rename holds `profile_name` before mutation. The switch stays queued and owner A remains current until the write is released. The switch then wipes. B has no A name.
- The same hold on `user_name` cannot land `A-RENAMED` after B commits.
- A switch that already holds the gate leaves a queued rename with zero name writes. Owner B's legitimate `Alex` stays `Alex`.
- False and thrown name writes still fail, and a failed second key still restores the previous pair for the same owner.
