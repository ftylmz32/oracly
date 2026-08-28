/// Yıldızname — form when empty, sun-sign result when saved.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_header_action.dart';
import '../../../../features/star_map/presentation/reference/star_map_reference_atmosphere.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../controllers/birth_chart_controller.dart';
import '../../copy/birth_chart_copy.dart';
import '../../providers/birth_chart_providers.dart';
import '../widgets/birth_chart_phase_body.dart';

class BirthChartScreen extends ConsumerStatefulWidget {
  const BirthChartScreen({super.key});

  @override
  ConsumerState<BirthChartScreen> createState() => _BirthChartScreenState();
}

class _BirthChartScreenState extends ConsumerState<BirthChartScreen> {
  void _handleBack(BirthChartController controller) {
    if (controller.isEditing && controller.chart != null) {
      controller.cancelEdit();
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<void> _handleMenu(
    String action,
    BirthChartController controller,
  ) async {
    switch (action) {
      case 'new':
        await controller.restartOnboarding();
      case 'clear':
        await controller.clearSavedAndRestart();
      case 'regenerate':
        await controller.regenerateFromSavedProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(birthChartControllerProvider);

    ref.listen<BirthChartController>(birthChartControllerProvider, (_, next) {
      final message = next.statusMessage;
      if (message != null) {
        OraclySnackBar.show(context, message: message);
        next.consumeStatusMessage();
      }
    });

    return OraclyScaffold(
      safeArea: false,
      backgroundOverlay: const StarMapReferenceAtmosphere(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            OraclyChrome.screenSide,
            OraclyChrome.screenTop,
            OraclyChrome.screenSide,
            0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OraclyAppBar(
                    title: BirthChartCopy.screenTitle,
                    onLeadingTap: () => _handleBack(controller),
                    trailing: _MenuTrailing(
                      controller: controller,
                      onSelected: (v) => _handleMenu(v, controller),
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      child: BirthChartPhaseBody(controller: controller),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuTrailing extends StatelessWidget {
  const _MenuTrailing({
    required this.controller,
    required this.onSelected,
  });

  final BirthChartController controller;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: BirthChartCopy.newChart,
      padding: EdgeInsets.zero,
      color: OraclyChrome.elevatedSurface,
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem(value: 'new', child: Text(BirthChartCopy.newChart)),
        if (controller.onboardingProfileHint != null ||
            controller.chart != null)
          PopupMenuItem(
            value: 'regenerate',
            child: Text(BirthChartCopy.generateChart),
          ),
        PopupMenuItem(
          value: 'clear',
          child: Text(BirthChartCopy.clearSavedChart),
        ),
      ],
      child: OraclyHeaderAction(
        icon: Icons.more_vert_rounded,
        label: BirthChartCopy.newChart,
      ),
    );
  }
}
