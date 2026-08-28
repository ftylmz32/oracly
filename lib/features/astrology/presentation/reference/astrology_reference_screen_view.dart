library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/chamber_header_lead.dart';
import '../../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../../shared/widgets/oracly_adaptive_scroll_view.dart';
import '../../../../shared/widgets/oracly_error_state.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../../content/astrology/models/astrology_content.dart';
import '../../copy/astrology_presentation_copy.dart';
import '../../models/astrology_daily_reading.dart';
import 'astrology_reference_app_bar.dart';
import 'astrology_reference_atmosphere.dart';
import 'astrology_reference_hub_body.dart';
import 'astrology_reference_loading_state.dart';
import 'astrology_reference_tokens.dart';

class AstrologyReferenceScreenView extends StatelessWidget {
  const AstrologyReferenceScreenView({
    super.key,
    required this.signs,
    required this.selectedId,
    required this.selected,
    required this.reading,
    required this.themeLabels,
    required this.isLoading,
    required this.profileHasError,
    required this.onRetryProfile,
    required this.onBack,
    required this.onSelected,
    required this.onDetail,
  });

  final List<ZodiacSignContent> signs;
  final String selectedId;
  final ZodiacSignContent selected;
  final AstrologyDailyReading reading;
  final List<String> themeLabels;
  final bool isLoading;
  final bool profileHasError;
  final VoidCallback onRetryProfile;
  final VoidCallback onBack;
  final ValueChanged<String> onSelected;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      safeArea: false,
      backgroundOverlay: const AstrologyReferenceAtmosphere(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AstrologyReferenceTokens.screenHorizontal,
            AstrologyReferenceTokens.screenTop,
            AstrologyReferenceTokens.screenHorizontal,
            AppLayout.scrollBottomInset(context),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AstrologyReferenceAppBar(onBack: onBack),
                  SizedBox(height: AstrologyReferenceTokens.headerToTabs),
                  ChamberHeaderLead(text: AstrologyPresentationCopy.leadLine),
                  SizedBox(height: AstrologyReferenceTokens.leadToStrip),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) =>
                          OraclyAdaptiveScrollView(
                        child: profileHasError
                            ? OraclyErrorState(
                                kind: OraclyLoadingKind.astrology,
                                message: AstrologyPresentationCopy
                                    .unavailableMoreInfo,
                                onRetry: onRetryProfile,
                              )
                            : isLoading
                                ? AstrologyReferenceLoadingState(
                                    sign: selected,
                                    viewportHeight: constraints.maxHeight,
                                  )
                                : AstrologyReferenceHubBody(
                                    signs: signs,
                                    selectedId: selectedId,
                                    selected: selected,
                                    reading: reading,
                                    onSelected: onSelected,
                                    onDetail: onDetail,
                                    themeLabels: themeLabels,
                                    viewportHeight: constraints.maxHeight,
                                  ),
                      ),
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

