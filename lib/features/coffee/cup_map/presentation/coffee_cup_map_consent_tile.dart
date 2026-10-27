/// The explicit "keep my photos for Fincan Haritası" choice — off until the
/// user turns it on. Shown before a Coffee V3 reading is sent and again on
/// the map screen so it can be turned off at any time.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../copy/coffee_cup_map_copy.dart';
import '../providers/coffee_cup_map_providers.dart';

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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
      decoration: BoxDecoration(
        borderRadius: OraclyChrome.cardRadius,
        color: OraclyChrome.cardSurface.withValues(alpha: 0.55),
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
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              widget.showFacts
                  ? '${CoffeeCupMapCopy.consentBody}\n${CoffeeCupMapCopy.consentFacts}'
                  : CoffeeCupMapCopy.consentFuture,
              style: ReadingTypography.footnote(),
            ),
          ),
        ],
      ),
    );
  }
}
