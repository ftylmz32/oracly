/// OR-020.1 — Central tab navigation for the Oracly app shell.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/audio/oracly_feedback_gate.dart';
import '../../core/navigation/oracly_navigation_service.dart';
import '../../core/voice/oracly_tts_gate.dart';
import '../../features/home/home_page.dart';
import '../../features/companion/presentation/reference/companion_or_tab_placeholder.dart';
import '../../features/explore/presentation/explore_reference_screen.dart';
import '../../features/discovery_journal/presentation/screens/discovery_journal_screen.dart';
import '../../features/premium/models/personalization_models.dart';
import '../../screens/profile/reference/profile_reference_screen.dart';
import '../widgets/oracly_bottom_bar.dart';
import '../widgets/oracly_pressable.dart';
import 'oracly_navigation_scope.dart';
import 'oracly_shell_bridge.dart';
import 'oracly_shell_runtime.dart';
import 'oracly_tab_pane.dart';

export 'oracly_navigation_scope.dart';

/// Root shell — preserves tab state and exposes one shared bottom bar.
///
/// Tab chrome (labels): Ana Sayfa · OR · Keşfet · Günlük · Profil
/// Enum indices stay stable; presentation roots match the Home master reference.
class OraclyAppShell extends ConsumerStatefulWidget {
  const OraclyAppShell({super.key, this.initialTab = OraclyTab.home});

  final OraclyTab initialTab;

  @override
  ConsumerState<OraclyAppShell> createState() => _OraclyAppShellState();
}

class _OraclyAppShellState extends ConsumerState<OraclyAppShell>
    with WidgetsBindingObserver {
  late int _currentIndex = widget.initialTab.index;

  late final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    OraclyTab.values.length,
    (_) => GlobalKey<NavigatorState>(),
  );

  static const List<Widget> _roots = [
    HomePage(),
    CompanionOrTabPlaceholder(),
    ExploreReferenceScreen(),
    DiscoveryJournalScreen(),
    ProfileReferenceScreen(),
  ];

  late final OraclyShellTabSwitcher _bridgeSwitch = _switchFromBridge;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    OraclyShellBridge.bind(_bridgeSwitch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(OraclyShellRuntime.bootstrap(ref));
    });
  }

  @override
  void dispose() {
    OraclyShellBridge.unbind(_bridgeSwitch);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(OraclyTtsGate.stop());
    super.dispose();
  }

  void _switchFromBridge(OraclyTab tab) {
    if (!mounted) return;
    _onDestinationSelected(tab.index);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    OraclyShellRuntime.handleLifecycle(
      state,
      ref.read(oraclySoundServiceProvider),
      ref: ref,
    );
  }

  void _onDestinationSelected(int index) {
    if (index == OraclyTab.coffee.index) {
      // Dedicated full-screen Luna — never host OR under the shell bottom bar.
      OraclyNavigationService.openChat(context);
      return;
    }
    if (_currentIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    OraclyTouchFeedback.selection();
    OraclyFeedbackGate.selection();
    unawaited(OraclyTtsGate.stop());
    OraclyShellRuntime.cancelCompanionVoice(context);
    setState(() => _currentIndex = index);
  }

  bool _allowRootPop() {
    final navigator = _navigatorKeys[_currentIndex].currentState;
    if (navigator != null && navigator.canPop()) return false;
    if (_currentIndex != OraclyTab.home.index) return false;
    return true;
  }

  Future<void> _handleBack() async {
    final navigator = _navigatorKeys[_currentIndex].currentState;
    if (navigator != null && navigator.canPop()) {
      await navigator.maybePop();
      return;
    }
    if (_currentIndex != OraclyTab.home.index) {
      setState(() => _currentIndex = OraclyTab.home.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<PersonalizationSettings>>(settingsProvider, (
      _,
      next,
    ) {
      next.whenData(
        (_) => OraclyShellRuntime.applyPersonalization(ref, syncAudio: false),
      );
    });
    ref.watch(appLocaleProvider);

    return OraclyNavigationScope(
      currentIndex: _currentIndex,
      switchToTab: _onDestinationSelected,
      child: PopScope(
        canPop: _allowRootPop(),
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          unawaited(_handleBack());
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: Stack(
            fit: StackFit.expand,
            children: [
              for (var i = 0; i < _roots.length; i++)
                OraclyTabPane(
                  active: _currentIndex == i,
                  navigatorKey: _navigatorKeys[i],
                  root: _roots[i],
                  personality: OraclyTab.fromIndex(i).chamberPersonality,
                ),
            ],
          ),
          bottomNavigationBar: OraclyBottomBar(
            currentIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
          ),
        ),
      ),
    );
  }
}
