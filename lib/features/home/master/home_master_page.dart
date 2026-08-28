/// Clean Home presentation root - master composition only.
///
/// LIVE: [OraclyAppShell] -> [HomePage] -> [HomeMasterPage] -> [HomeMasterBody]
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_layout.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/universe/oracly_universe_layer.dart';
import '../../../shared/widgets/oracly_scaffold.dart';
import 'home_master_body.dart';

/// Presentation root: scrollable Home. Bottom nav stays in the shell.
class HomeMasterPage extends StatelessWidget {
  const HomeMasterPage({super.key});

  static const double _horizontal = AppSpacing.s20;
  static const double _top = AppSpacing.s4;

  @override
  Widget build(BuildContext context) {
    return OraclyUniverseTicker(
      child: OraclyScaffold(
        safeArea: false,
        usePremiumBackground: true,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(_horizontal, _top, _horizontal, 0),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppLayout.contentMaxWidth(context),
                ),
                child: const SizedBox.expand(child: HomeMasterBody()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
