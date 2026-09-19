/// Reference-accurate Yıldızname screen — rebuilt from design reference.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/chamber_header_lead.dart';
import '../../../../features/birth_chart/providers/birth_information_provider.dart';
import '../../../../features/personal_discovery/providers/personal_discovery_providers.dart';
import '../../../quality_loop/widgets/quality_loop_gate.dart';
import '../../../../core/quality/quality_feature.dart';
import '../../../../shared/navigation/oracly_navigation.dart';
import '../../../../shared/widgets/oracly_adaptive_scroll_view.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../copy/star_map_polish_copy.dart';
import '../../services/star_map_reading_service.dart';
import 'star_map_reference_app_bar.dart';
import 'star_map_reference_atmosphere.dart';
import 'star_map_reference_hub_body.dart';
import 'star_map_reference_routes.dart';
import 'star_map_reference_tokens.dart';

/// Entry point for the Yıldızname / star map feature.
class StarMapReferenceScreen extends ConsumerWidget {
  const StarMapReferenceScreen({super.key});

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    OraclyNavigation.switchToTab(context, OraclyTab.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(
      birthInformationProvider.select((async) => async.valueOrNull),
    );
    final discovery = ref.watch(
      personalDiscoveryProfileProvider.select((async) => async.valueOrNull),
    );
    final sunSign = ref.watch(savedSunSignProvider);
    final reading = StarMapReadingService.build(
      sunSign: sunSign,
      discovery: discovery,
    );

    return QualityLoopGate(
      feature: QualityFeature.starMap,
      startOnInit: true,
      child: OraclyScaffold(
      safeArea: false,
      backgroundOverlay: const StarMapReferenceAtmosphere(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            StarMapReferenceTokens.screenHorizontal,
            StarMapReferenceTokens.screenTop,
            StarMapReferenceTokens.screenHorizontal,
            AppLayout.scrollBottomInset(context),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StarMapReferenceAppBar(onBack: () => _handleBack(context)),
                  SizedBox(height: StarMapReferenceTokens.headerToChart),
                  ChamberHeaderLead(text: StarMapPolishCopy.leadLine),
                  SizedBox(height: StarMapReferenceTokens.leadToHero),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final chart = StarMapReferenceTokens.chartDiameterFor(
                          maxHeight: constraints.maxHeight,
                          contentWidth: constraints.maxWidth,
                        );
                        void refresh() =>
                            ref.invalidate(birthInformationProvider);
                        return OraclyAdaptiveScrollView(
                          child: StarMapReferenceHubBody(
                            chart: chart,
                            hasBirth: profile != null,
                            cityName: profile?.birthPlace,
                            reading: reading,
                            profile: profile,
                            onRefresh: refresh,
                            onBirth: () =>
                                StarMapReferenceRoutes.openBirthChart(
                              context,
                              onReturn: refresh,
                            ),
                            onOpenLeaf: () =>
                                StarMapReferenceRoutes.openSkyMessage(
                              context,
                              reading,
                              profile: profile,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
