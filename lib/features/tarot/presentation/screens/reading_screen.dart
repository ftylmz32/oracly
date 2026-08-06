/// OR-1170 — Premium AI tarot reading screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/insights/services/journey_personalization_builder.dart';
import '../../../../app/providers/app_providers.dart';
import '../../../../core/copy/session_ending_copy.dart';
import '../../../../core/copy/reading_flow_copy.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../../../features/ai/oracle_conversation/navigation/oracle_conversation_route.dart';
import '../../domain/models/reading_session.dart';
import '../../services/tarot_interpretation_service.dart';
import '../../shared/tarot_scope.dart';
import '../theme/tarot_emotional_rhythm.dart';
import '../../theme/tarot_tokens.dart';
import '../animations/tarot_transition.dart';
import '../widgets/ai_reading/ai_reading_content.dart';
import '../widgets/ai_reading/reading_premium_body.dart';
import '../widgets/ai_reading/reading_background.dart';
import '../widgets/ai_reading/reading_element_glow.dart';
import '../widgets/ai_reading/reading_element_theme.dart';
import '../widgets/ai_reading/reading_floating_particles.dart';
import '../widgets/ai_reading/reading_footer_actions.dart';
import '../widgets/ai_reading/reading_intro_phase.dart';
import '../widgets/ai_reading/reading_premium_scroll.dart';
import '../widgets/ai_reading/reading_premium_utils.dart';
import '../../components/tarot_loading.dart';
import '../../components/tarot_error_state.dart';
import '../widgets/reading_history/reading_journal_note_sheet.dart';

/// Cinematic AI interpretation — intro, staggered sections, premium actions.
class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({super.key});

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _content;
  late final AnimationController _exit;
  late final AnimationController _ambient;
  AiReadingContent? _contentData;
  bool _loading = true;
  bool _exiting = false;
  bool _journalPersisted = false;
  String? _savedReadingId;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: ReadingIntroTimeline.duration,
    );
    _content = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: TarotTokens.ambientLoop,
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReading());
  }

  Future<void> _loadReading() async {
    final reading = TarotScope.of(context).reading;
    var session = reading.session;

    if (session == null) {
      debugPrint('[ReadingScreen] Session missing on first frame; retrying.');
      await Future<void>.delayed(Duration.zero);
      session = reading.session;
    }

    if (session == null) {
      debugPrint('[ReadingScreen] ERROR: No active reading session.');
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      debugPrint(
        '[ReadingScreen] Generating interpretation for session ${session.id} '
        '(${session.drawnCards.length} cards).',
      );
      final priorReadings = ref.read(readingHistoryProvider).valueOrNull ?? [];
      final journeyHints = JourneyPersonalizationBuilder.fromHistory(
        priorReadings,
        excludeSessionId: session.id,
      );
      final content = await reading.resolveInterpretationContent(
        journeyHints: journeyHints,
      );
      if (!mounted) return;
      setState(() {
        _contentData = content;
        _loading = false;
      });
      _startRevealSequence();
      _persistToJournal();
    } catch (error, stackTrace) {
      debugPrint('[ReadingScreen] Interpretation load failed: $error\n$stackTrace');
      if (!mounted) return;
      final fallback = reading.session;
      if (fallback == null) {
        setState(() => _loading = false);
        return;
      }
      final service = TarotInterpretationService();
      final content = service.emergencyFallback(
        fallback,
        reason: 'Yorum yüklenemedi. Kart anlamları geçici olarak gösteriliyor.',
      );
      await reading.updateSession(
        fallback.copyWith(interpretation: content.fullInterpretation),
      );
      if (!mounted) return;
      setState(() {
        _contentData = content;
        _loading = false;
      });
      _startRevealSequence();
      _persistToJournal();
    }
  }

  void _startRevealSequence() {
    if (!mounted) return;

    void startContentReveal() {
      if (!mounted) return;
      if (_content.status == AnimationStatus.completed) return;
      if (_content.status != AnimationStatus.forward) {
        _content.forward(from: 0);
      }
    }

    if (_intro.status == AnimationStatus.completed) {
      startContentReveal();
      return;
    }

    _intro.forward(from: 0).whenComplete(startContentReveal);

    // Safety net: intro is ~1s — ensure section reveal cannot stall silently.
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_content.value < 0.01) {
        debugPrint(
          '[ReadingScreen] Section reveal did not start; forcing content animation.',
        );
        startContentReveal();
      }
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _content.dispose();
    _exit.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Future<void> _newReading() async {
    if (_exiting) return;
    setState(() => _exiting = true);
    await _exit.forward();
    if (!mounted) return;
    TarotScope.of(context).reading.resetSession();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _persistToJournal({bool offerNote = false}) async {
    if (_journalPersisted) {
      if (offerNote) await _offerPersonalNote();
      return;
    }
    final reading = TarotScope.of(context).reading;
    final session = reading.session;
    final content = _contentData;
    if (session == null || content == null) return;

    final completed = session.status == ReadingSessionStatus.completed
        ? session
        : await reading.completeSession();
    final saved = await ref.read(readingServiceProvider).saveFromSession(
          session: completed,
          aiSummary: content.fullInterpretation ?? content.generalMeaning,
        );
    _journalPersisted = true;
    _savedReadingId = saved?.id;
    ref.read(analyticsServiceProvider).logReadingCompleted(
          spreadType: completed.spread.label,
          cardName: content.cardName,
        );
    ref.invalidate(readingHistoryProvider);
    if (offerNote) await _offerPersonalNote();
  }

  Future<void> _offerPersonalNote() async {
    if (!mounted || _savedReadingId == null) return;
    final content = _contentData;
    final note = await showReadingJournalNoteSheet(
      context: context,
      cardName: content?.cardName ?? '',
    );
    if (note == null || note.isEmpty) return;
    await ref.read(readingServiceProvider).updatePersonalNote(
          readingId: _savedReadingId!,
          note: note,
        );
    ref.invalidate(readingHistoryProvider);
  }

  Future<void> _saveReading() async {
    await _persistToJournal(offerNote: true);
    if (!mounted) return;
    OraclySnackBar.success(context, SessionEndingCopy.saveConfirmation);
  }

  void _openOracleConversation() {
    final reading = TarotScope.of(context).reading;
    final session = reading.session;
    final content = _contentData;
    if (session == null || content == null) return;

    openOracleConversation(
      context,
      readingContext: OracleReadingContext.fromSession(
        session: session,
        content: content,
      ),
    );
  }

  double _panelOpacityFor(double sectionMaster) {
    return Curves.easeOutCubic.transform((sectionMaster / 0.12).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: TarotLoading(),
      );
    }

    if (_contentData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: TarotErrorState(
          message: ReadingFlowCopy.readingSessionMissing,
          onRetry: () {
            setState(() => _loading = true);
            _loadReading();
          },
        ),
      );
    }

    final contentData = _contentData!;
    final card = ReadingPremiumUtils.primaryCard(contentData);
    final elementTheme = ReadingElementTheme.fromCard(card);
    final cardActive = _intro.isCompleted;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) {
                final ambientT = _ambient.value;
                final livingIntensity = 0.62 +
                    _content.value * 0.08 +
                    TarotEmotionalRhythm.peakPulse(
                      _content.value,
                      centre: 0.08,
                      width: 0.10,
                    ) *
                        0.12;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: ReadingBackground(
                        fogIntensity: livingIntensity,
                        phase: ambientT,
                      ),
                    ),
                    ReadingElementGlow(
                      theme: elementTheme,
                      phase: ambientT,
                      intensity: _panelOpacityFor(_content.value) * 0.82,
                    ),
                    ReadingFloatingParticles(
                      phase: ambientT,
                      intensity: livingIntensity,
                    ),
                  ],
                );
              },
            ),
            AnimatedBuilder(
              animation: _intro,
              builder: (context, child) {
                final introOpacity =
                    ReadingIntroTimeline.introOpacity(_intro.value);
                final cardLift = ReadingIntroTimeline.cardLift(_intro.value);
                final showIntro = introOpacity > 0.01;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (showIntro)
                      SafeArea(
                        child: ReadingIntroPhase(
                          content: contentData,
                          progress: introOpacity,
                          cardLift: cardLift,
                        ),
                      ),
                    child!,
                  ],
                );
              },
              child: SafeArea(
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: Listenable.merge([_intro, _content]),
                      builder: (context, _) {
                        final introOpacity =
                            ReadingIntroTimeline.introOpacity(_intro.value);
                        final showIntro = introOpacity > 0.01;
                        final sectionMaster = _content.value;
                        if (!showIntro || sectionMaster > 0.05) {
                          return SizedBox(height: AppSpacing.xl);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _intro,
                        builder: (context, child) {
                          final showIntro =
                              ReadingIntroTimeline.introOpacity(_intro.value) >
                                  0.01;
                          return ReadingPremiumScrollView(
                            padding: EdgeInsets.only(
                              top: showIntro ? 0 : AppSpacing.md,
                              bottom: AppSpacing.md,
                            ),
                            child: child!,
                          );
                        },
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: TarotTokens.maxContentWidth,
                            ),
                            child: AnimatedBuilder(
                              animation: Listenable.merge([_content, _exit]),
                              builder: (context, _) {
                                final sectionMaster = _content.value;
                                final exitProgress = _exit.value;
                                return ReadingPremiumBody(
                                  content: contentData,
                                  sectionMaster: sectionMaster,
                                  panelOpacity:
                                      _panelOpacityFor(sectionMaster),
                                  ambientPhase: _ambient.value,
                                  exitProgress: exitProgress,
                                  cardActive: cardActive,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: Listenable.merge([_content, _exit]),
                      builder: (context, _) {
                        return ReadingFooterActions(
                          progress: readingFooterProgress(_content.value),
                          exitProgress: _exit.value,
                          onNewReading: _exiting ? null : _newReading,
                          onSave: _journalPersisted ? null : _saveReading,
                          onAskOracle: _openOracleConversation,
                          onAddReflection: _journalPersisted
                              ? _offerPersonalNote
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Smooth transition from card reveal into AI reading.
PageRouteBuilder<T> readingRitualRoute<T>({
  required Widget page,
  RouteSettings? settings,
}) {
  return tarotRitualDepthHandoffRoute<T>(
    page: page,
    settings: settings,
    duration: TarotTokens.ritualReadingHandoff,
  );
}
