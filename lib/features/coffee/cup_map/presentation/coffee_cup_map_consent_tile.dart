/// The explicit "keep my photos for Fincan Haritası" choice — off until the
/// user turns it on. Shown before a Coffee V3 reading is sent and again on
/// the map screen so it can be turned off at any time.
///
/// Before a reading it reads in layers: one sentence and three facts (only
/// on this device, never in the cloud or backups, deletable any time) are
/// always visible; the complete explanation is one tap away under
/// "Ayrıntılar". Nothing is hidden behind the switch.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../copy/coffee_cup_map_copy.dart';
import '../providers/coffee_cup_map_providers.dart';
import 'coffee_cup_map_motion.dart';

class CoffeeCupMapConsentTile extends ConsumerStatefulWidget {
  const CoffeeCupMapConsentTile({super.key, this.showFacts = true});

  /// The full explanation (before a reading); the map screen shows the
  /// short "applies from now on" line instead.
  final bool showFacts;

  @override
  ConsumerState<CoffeeCupMapConsentTile> createState() =>
      _CoffeeCupMapConsentTileState();
}

class _CoffeeCupMapConsentTileState
    extends ConsumerState<CoffeeCupMapConsentTile> {
  bool? _keep;
  bool _details = false;

  @override
  void initState() {
    super.initState();
    _keep = ref.read(coffeeCupMapConsentProvider)?.keepPhotos;
  }

  Future<void> _set(bool next) async {
    final consent = ref.read(coffeeCupMapConsentProvider);
    if (consent == null) return;
    setState(() => _keep = next);
    final ok = await consent.setKeepPhotos(next);
    if (!mounted) return;
    // Only what was actually stored is shown.
    if (!ok) setState(() => _keep = consent.keepPhotos);
  }

  @override
  Widget build(BuildContext context) {
    final keep = _keep;
    if (keep == null) return const SizedBox.shrink();
    final duration = CoffeeCupMapMotion.of(context, CoffeeCupMapMotion.pinSelect);
    return AnimatedContainer(
      duration: duration,
      curve: CoffeeCupMapMotion.ease,
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      decoration: BoxDecoration(
        borderRadius: OraclyChrome.cardRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OraclyChrome.deepNavy.withValues(alpha: 0.8),
            OraclyChrome.cardSurface.withValues(alpha: 0.6),
          ],
        ),
        border: Border.all(
          color: OraclyChrome.gold.withValues(
            alpha: keep ? OraclyChrome.borderSelected : OraclyChrome.borderHairline,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: InkWell(
              onTap: () => _set(!keep),
              borderRadius: OraclyChrome.cardRadius,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: OraclyChrome.midnight.withValues(alpha: 0.6),
                          border: Border.all(
                            color: OraclyChrome.gold.withValues(
                              alpha: keep
                                  ? OraclyChrome.borderEmphasis
                                  : OraclyChrome.borderHairline,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.photo_library_outlined,
                          size: 17,
                          color: OraclyChrome.gold.withValues(alpha: keep ? 1 : 0.75),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        CoffeeCupMapCopy.consentTitle,
                        style: ReadingTypography.label(color: OraclyChrome.cream),
                      ),
                    ),
                    Switch(
                      value: keep,
                      onChanged: _set,
                      activeThumbColor: OraclyChrome.midnight,
                      activeTrackColor: OraclyChrome.gold,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!widget.showFacts)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 6),
              child: Text(
                CoffeeCupMapCopy.consentFuture,
                style: ReadingTypography.footnote(),
              ),
            )
          else ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                CoffeeCupMapCopy.consentSummary,
                style: ReadingTypography.secondary(),
              ),
            ),
            const SizedBox(height: 12),
            const _Fact(
              icon: Icons.smartphone_outlined,
              text: CoffeeCupMapCopy.consentFactDevice,
            ),
            const _Fact(
              icon: Icons.cloud_off_outlined,
              text: CoffeeCupMapCopy.consentFactNoBackup,
            ),
            const _Fact(
              icon: Icons.delete_outline,
              text: CoffeeCupMapCopy.consentFactDelete,
            ),
            _DetailsToggle(
              open: _details,
              onTap: () => setState(() => _details = !_details),
            ),
            AnimatedSize(
              duration: CoffeeCupMapMotion.of(context, CoffeeCupMapMotion.sheetOut),
              curve: CoffeeCupMapMotion.ease,
              alignment: Alignment.topCenter,
              child: _details
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(2, 2, 6, 4),
                      child: Text(
                        '${CoffeeCupMapCopy.consentBody}\n\n'
                        '${CoffeeCupMapCopy.consentFacts}',
                        style: ReadingTypography.footnote(),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ],
      ),
    );
  }
}

/// One fact the user should know before turning the choice on.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              icon,
              size: 16,
              color: OraclyChrome.gold.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: ReadingTypography.bodySmall(color: OraclyChrome.cream),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Ayrıntılar": opens the complete explanation in place.
class _DetailsToggle extends StatelessWidget {
  const _DetailsToggle({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = CoffeeCupMapMotion.of(context, CoffeeCupMapMotion.pinSelect);
    return Semantics(
      button: true,
      expanded: open,
      label: open ? CoffeeCupMapCopy.consentDetailsHide : CoffeeCupMapCopy.consentDetails,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: OraclyChrome.pillRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  open ? CoffeeCupMapCopy.consentDetailsHide : CoffeeCupMapCopy.consentDetails,
                  style: ReadingTypography.label(color: OraclyChrome.goldLight),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: duration,
                curve: CoffeeCupMapMotion.ease,
                child: const Icon(
                  Icons.expand_more,
                  size: 20,
                  color: OraclyChrome.goldLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
