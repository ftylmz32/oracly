/// Personal archive chamber — warm ink, quiet celestial motifs.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_cosmic_background.dart';
import 'discovery_archive_motifs.dart';

class DiscoveryJournalAtmosphere extends StatelessWidget {
  const DiscoveryJournalAtmosphere({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return OraclyCosmicBackground(
      heroGlow: false,
      showStars: false,
      showNebula: false,
      showDust: false,
      child: OraclyChamberVeil(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!light) const DiscoveryArchiveMotifs(),
            if (!light)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        OraclyChrome.midnight.withValues(alpha: 0.22),
                        Colors.transparent,
                        OraclyChrome.midnight.withValues(alpha: 0.72),
                      ],
                      stops: const [0.0, 0.40, 1.0],
                    ),
                  ),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
