/// EPIC-031 — Tarot entry screen assembly.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../shared/navigation/oracly_navigation.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../../../core/revisit/services/discovery_revisit_opener.dart';
import '../../domain/models/tarot_spread.dart';
import '../../economy/tarot_economy.dart';
import '../../first_session/tarot_first_reading.dart';
import '../../providers/tarot_revisit_provider.dart';
import '../../revisit/tarot_revisit_intent.dart';
import '../../revisit/tarot_revisit_mode.dart';
import '../../revisit/tarot_revisit_service.dart';
import '../widgets/tarot_entry/tarot_entry_body.dart';
import '../widgets/tarot_entry/tarot_entry_launch.dart';
import '../widgets/tarot_revisit/tarot_revisit_sheet.dart';
import 'tarot_epic031_background.dart';
import 'tarot_epic031_header.dart';
import 'tarot_epic031_spec.dart';

/// Live tarot portal — question, spread, then the ritual.
class TarotEpic031Page extends ConsumerStatefulWidget {
  const TarotEpic031Page({super.key});

  @override
  ConsumerState<TarotEpic031Page> createState() => _TarotEpic031PageState();
}

class _TarotEpic031PageState extends ConsumerState<TarotEpic031Page> {
  late final TextEditingController _question;
  late final FocusNode _questionFocus;
  TarotSpreadType _spread = TarotSpreadType.threeCard;
  bool _spending = false;
  bool _defaultsReady = false;
  bool _revisitOffered = false;
  bool _screenLogged = false;

  @override
  void initState() {
    super.initState();
    _question = TextEditingController();
    _questionFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logHomeOnce();
      _maybeOfferRevisit();
    });
  }

  void _logHomeOnce() {
    if (!mounted || _screenLogged) return;
    _screenLogged = true;
    OraclyNavigationService.logScreen(ref, 'tarot_home');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultsReady) return;
    _defaultsReady = true;
    if (TarotFirstReading.shouldUseFirstSpread(context, ref)) {
      _spread = TarotSpreadType.single;
    }
  }

  @override
  void dispose() {
    _question.dispose();
    _questionFocus.dispose();
    super.dispose();
  }

  Future<void> _maybeOfferRevisit() async {
    if (!mounted || _revisitOffered) return;
    final revisit = ref.read(tarotRevisitProvider);
    if (revisit == null) return;
    _revisitOffered = true;
    await TarotRevisitSheet.show(
      context,
      revisit: revisit,
      onNewSpread: () => _questionFocus.requestFocus(),
      onOpenPrior: () => DiscoveryRevisitOpener.openPrior(context, revisit),
      onDifferentAngle: (TarotRevisitMode mode) => _startReading(
        revisit: TarotRevisitIntent(
          priorReadingId: revisit.reading.id,
          mode: mode,
          priorExcerpt: TarotRevisitService.priorExcerpt(revisit.reading),
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    final inner = Navigator.of(context);
    if (inner.canPop()) {
      inner.pop();
      return;
    }
    final root = Navigator.of(context, rootNavigator: true);
    if (root.canPop()) {
      root.pop();
      return;
    }
    OraclyNavigation.switchToTab(context, OraclyTab.home);
  }

  Future<void> _startReading({TarotRevisitIntent? revisit}) async {
    if (_spending) return;
    setState(() => _spending = true);
    final ok = await TarotEntryLaunch.start(
      context: context,
      ref: ref,
      spread: _spread,
      question: _question.text,
      revisit: revisit,
    );
    if (mounted && !ok) setState(() => _spending = false);
  }

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      safeArea: false,
      backgroundOverlay: const TarotEpic031Background(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            TarotEpic031Spec.horizontalInset,
            TarotEpic031Spec.screenTop,
            TarotEpic031Spec.horizontalInset,
            AppLayout.scrollBottomInset(context),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: TarotEpic031Spec.contentWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TarotEpic031Header(
                    onBack: () => _handleBack(context),
                    onPremiumTap: () =>
                        OraclyNavigationService.openGems(context),
                  ),
                  Expanded(
                    child: TarotEntryBody(
                      heroHeight: TarotEpic031Spec.layoutFor(
                        MediaQuery.sizeOf(context).height,
                      ).heroHeight,
                      question: _question,
                      questionFocusNode: _questionFocus,
                      spread: _spread,
                      onSpreadSelected: (value) =>
                          setState(() => _spread = value),
                      onStart: () => _startReading(),
                      starting: _spending,
                      showCost: TarotEconomy.costFor(_spread) != null,
                      cost: TarotEconomy.costFor(_spread),
                      onHistory: () =>
                          OraclyNavigationService.openReadingHistory(context),
                      onDestem: () =>
                          OraclyNavigationService.openDestem(context),
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
