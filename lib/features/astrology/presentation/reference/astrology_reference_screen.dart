/// Reference-accurate Astrology screen — rebuilt from design reference.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../shared/navigation/oracly_navigation.dart';
import '../../../quality_loop/widgets/quality_loop_gate.dart';
import '../../../../core/quality/quality_feature.dart';
import '../../../content/astrology/data/astrology_content_catalogue.dart';
import '../../../personal_discovery/providers/personal_discovery_providers.dart';
import '../../providers/astrology_providers.dart';
import '../../services/astrology_daily_reading_service.dart';
import '../../services/astrology_sign_resolver.dart';
import 'astrology_reference_detail_screen.dart';
import 'astrology_reference_screen_view.dart';

/// Entry point for the Astrology feature — reference UI only.
class AstrologyReferenceScreen extends ConsumerStatefulWidget {
  const AstrologyReferenceScreen({super.key});

  @override
  ConsumerState<AstrologyReferenceScreen> createState() =>
      _AstrologyReferenceScreenState();
}

class _AstrologyReferenceScreenState
    extends ConsumerState<AstrologyReferenceScreen> {
  late String _selectedId;
  bool _restoringSign = true;
  bool _openingDetail = false;

  @override
  void initState() {
    super.initState();
    _selectedId = AstrologySignResolver.fallbackId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSign());
  }

  Future<void> _restoreSign() async {
    try {
      final id = await ref.read(astrologySignResolverProvider).resolve();
      if (mounted && id != _selectedId) {
        setState(() => _selectedId = id);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _restoringSign = false);
  }

  Future<void> _selectSign(String id) async {
    setState(() => _selectedId = id);
    try {
      await ref.read(astrologySignResolverProvider).select(id);
    } catch (_) {}
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    OraclyNavigation.switchToTab(context, OraclyTab.home);
  }

  void _openDetailReading() {
    if (_openingDetail) return;
    _openingDetail = true;
    ref.read(analyticsServiceProvider).logAstrologyCompleted();
    final sign = AstrologyContentCatalogue.signById(_selectedId) ??
        AstrologyContentCatalogue.signs.first;
    final profile = ref.read(personalDiscoveryProfileProvider).valueOrNull;
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => AstrologyReferenceDetailScreen(
          sign: sign,
          reading: AstrologyDailyReadingService.build(sign, profile: profile),
          themeLabels: profile?.personalizationThemes ?? const <String>[],
        ),
      ),
    )
        .whenComplete(() {
      _openingDetail = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final signs = AstrologyContentCatalogue.signs;
    final selected = AstrologyContentCatalogue.signById(_selectedId) ??
        signs.first;
    final profileAsync = ref.watch(personalDiscoveryProfileProvider);
    final profile = profileAsync.valueOrNull;
    final themeLabels = profile?.personalizationThemes ?? const <String>[];
    // Profile personalizes themes only — never block the local hub on error.
    final isLoading = _restoringSign ||
        (profileAsync.isLoading && !profileAsync.hasError);
    final reading = AstrologyDailyReadingService.build(
      selected,
      profile: profile,
    );

    return QualityLoopGate(
      feature: QualityFeature.astrology,
      startOnInit: true,
      child: AstrologyReferenceScreenView(
      signs: signs,
      selectedId: _selectedId,
      selected: selected,
      reading: reading,
      themeLabels: themeLabels,
      isLoading: isLoading,
      onBack: _handleBack,
      onSelected: (id) {
        _selectSign(id);
      },
      onDetail: _openDetailReading,
    ),
    );
  }
}
