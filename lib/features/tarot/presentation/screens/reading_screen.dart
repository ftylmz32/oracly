/// OR-1170 — Premium tarot reading screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/insights/services/journey_personalization_builder.dart';
import '../../../../features/personal_discovery/providers/personal_discovery_providers.dart';
import '../../../../features/personal_discovery/services/personal_discovery_refresh.dart';
import '../../../../app/providers/app_providers.dart';
import '../../copy/tarot_revisit_copy.dart';
import '../../revisit/tarot_revisit_intent_store.dart';
import '../../../../core/copy/session_ending_copy.dart';
import '../../../../core/audio/oracly_feedback_gate.dart';
import '../../copy/tarot_polish_copy.dart';
import '../../economy/tarot_economy.dart';
import '../../economy/tarot_reading_charge.dart';
import '../../economy/tarot_reading_completion.dart';
import '../../../gems/copy/gems_copy.dart';
import '../../../gems/providers/gem_providers.dart';
import '../../../../core/audio/oracly_sound_chamber.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/design_system/app_layout.dart';
import '../../../../core/theme/oracly_quiet_motion.dart';
import '../../../../core/theme/oracly_reduced_motion.dart';
import '../../../../features/ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../../../features/ai/oracle_conversation/navigation/oracle_conversation_route.dart';
import '../../domain/models/reading_session.dart';
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
import '../../../../features/discovery_share/services/discovery_share_builder.dart';
import '../../components/tarot_loading.dart';
import '../../components/tarot_error_state.dart';
import '../../interpretation/models/interpretation_error.dart';
import '../widgets/reading_history/reading_journal_note_sheet.dart';
import '../../../favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import '../../../quality_loop/widgets/quality_loop_gate.dart';
import '../../../../core/quality/quality_feature.dart';
import '../../../favorite_moments/services/favorite_moment_factory.dart';
import '../../../favorite_moments/models/favorite_moment.dart';
import '../../../reading_feedback/models/reading_feedback_category.dart';
import '../../../reading_feedback/presentation/widgets/reading_quality_actions.dart';
import '../../../../core/reading_version/adapters/tarot_version_content.dart';
import '../../../../core/reading_version/models/reading_version_group.dart';
import '../../../../core/reading_version/models/reading_version_kind.dart';
import '../../../../core/reading_version/providers/reading_version_providers.dart';
import '../../../../core/reading_version/services/reading_version_payload.dart';
import '../../../../core/reading_version/widgets/reading_version_host.dart';

/// Cinematic interpretation — intro, staggered sections, premium actions.
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
  String? _loadError;
  bool _loading = true;
  bool _exiting = false;
  bool _journalPersisted = false;
  int _loadToken = 0;
  String? _savedReadingId;
  int _versionReloadToken = 0;

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
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReading());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _ambient);
  }

  Future<void> _loadReading() async {
    final token = ++_loadToken;
    final reading = TarotScope.of(context).reading;
    var session = reading.session;

    if (session == null) {
      await Future<void>.delayed(Duration.zero);
      session = reading.session;
    }

    if (!mounted || token != _loadToken) return;
    if (session == null || session.drawnCards.isEmpty) {
      setState(() {
        _loading = false;
        _loadError = TarotPolishCopy.readingUnavailable;
      });
      return;
    }

    final priorReadings = ref.read(readingHistoryProvider).valueOrNull ?? [];
    final discovery = ref.read(personalDiscoveryProfileProvider).valueOrNull;
    var journeyHints = JourneyPersonalizationBuilder.fromHistory(
      priorReadings,
      excludeSessionId: session.id,
      extraThemeLabels: discovery?.personalizationThemes ?? const [],
    );
    final revisit = await TarotRevisitIntentStore(
      ref.read(localStorageProvider),
    ).consume();
    if (revisit != null) {
      journeyHints = journeyHints.withRevisit(
        priorExcerpt: revisit.priorExcerpt,
        instruction: TarotRevisitCopy.revisitInstruction(revisit.mode),
      );
    }
    AiReadingContent? content;
    String? loadError;
    try {
      content = await TarotReadingCompletion(
        charge: TarotReadingCharge(
          ref.read(gemWalletServiceProvider),
          ref.read(localStorageProvider),
          analytics: ref.read(analyticsServiceProvider),
        ),
      ).complete(
        session,
        load: () => reading.resolveInterpretationContent(
          journeyHints: journeyHints,
        ),
        shouldCommit: () => mounted && token == _loadToken,
      );
    } on InterpretationException catch (e) {
      content = null;
      loadError = e.message;
    } catch (_) {
      content = null;
      loadError = null;
    }
    // Balance must track spend even if the user left mid-load.
    ref.read(gemWalletProvider).reload();
    if (content == null) {
      if (mounted && token == _loadToken) {
        setState(() {
          _loading = false;
          _loadError = loadError;
        });
      }
      return;
    }
    final latest = reading.session ?? session;
    if (latest.interpretation != content.fullInterpretation) {
      await reading.updateSession(
        latest.copyWith(interpretation: content.fullInterpretation),
      );
    }
    // Paid content is persisted before UI gates — navigation must not drop it.
    if (!mounted || token != _loadToken) return;
    setState(() {
      _contentData = content;
      _loadError = null;
      _loading = false;
    });
    OraclyFeedbackGate.playCue(OraclySoundCue.journeyComplete);
    _startRevealSequence();
    _persistToJournal();
  }

  void _startRevealSequence() {
    if (!mounted) return;
    if (OraclyReducedMotion.of(context)) {
      _intro.value = 1;
      _content.value = 1;
      return;
    }

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
        assert(() {
          debugPrint(
            '[ReadingScreen] Section reveal did not start; forcing content animation.',
          );
          return true;
        }());
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
    if (saved != null) {
      await ref.read(readingVersionServiceProvider).seedOriginal(
            rootId: saved.id,
            kind: ReadingVersionKind.tarot,
            data: ReadingVersionPayload.tarot(saved.aiSummary),
          );
    }
    ref.read(analyticsServiceProvider).logReadingCompleted(
          spreadType: completed.spread.name,
        );
    ref.invalidate(readingHistoryProvider);
    PersonalDiscoveryRefresh.invalidate(ref);
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
    PersonalDiscoveryRefresh.invalidate(ref);
  }

  Future<void> _saveReading() async {
    await _persistToJournal(offerNote: true);
    if (!mounted) return;
    OraclySnackBar.success(context, SessionEndingCopy.saveConfirmation);
  }

  FavoriteMoment? _tarotMomentDraft() {
    final session = TarotScope.of(context).reading.session;
    final content = _contentData;
    if (session == null || content == null) return null;
    final card = ReadingPremiumUtils.primaryCard(content);
    return FavoriteMomentFactory.tarotLive(
      sessionId: session.id,
      at: session.completedAt ?? DateTime.now(),
      cardName: content.cardName,
      cardAsset: card?.image ?? content.imageAsset,
      insight: content.fullInterpretation ?? content.generalMeaning,
    );
  }

  Future<FavoriteMoment?> _prepareTarotMoment() async {
    await _persistToJournal();
    final id = _savedReadingId;
    if (id == null) return _tarotMomentDraft();
    final readings = ref.read(readingHistoryProvider).valueOrNull ?? const [];
    for (final reading in readings) {
      if (reading.id == id) return FavoriteMomentFactory.tarot(reading);
    }
    return _tarotMomentDraft();
  }

  Future<bool> _reinterpretWithoutCharge() async {
    final reading = TarotScope.of(context).reading;
    final session = reading.session;
    if (session == null) throw StateError('no session');
    setState(() => _loading = true);
    try {
      final content = await reading.resolveInterpretationContent(
        forceRefresh: true,
      );
      if (!mounted) return false;
      final summary = content.fullInterpretation ?? content.generalMeaning;
      final savedId = _savedReadingId;
      var changed = true;
      if (savedId != null) {
        final result =
            await ref.read(readingVersionServiceProvider).tryAppendRevision(
                  rootId: savedId,
                  kind: ReadingVersionKind.tarot,
                  data: ReadingVersionPayload.tarot(summary),
                );
        if (!mounted) return false;
        changed = result.added;
        if (!changed) {
          setState(() => _loading = false);
          return false;
        }
        final readings = await ref.read(historyRepositoryProvider).getReadings();
        if (!mounted) return false;
        for (final item in readings) {
          if (item.id == savedId || item.sessionId == savedId) {
            await ref.read(historyRepositoryProvider).saveReading(
                  item.copyWith(aiSummary: summary),
                );
            break;
          }
        }
        _versionReloadToken++;
        ref.invalidate(readingHistoryProvider);
        PersonalDiscoveryRefresh.invalidate(ref);
      }
      await reading.updateSession(
        (reading.session ?? session).copyWith(
          interpretation: summary,
        ),
      );
      if (!mounted) return false;
      setState(() {
        _contentData = content;
        _loading = false;
      });
      _content.value = 1;
      return changed;
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      rethrow;
    }
  }

  void _applyTarotVersion(ReadingVersionGroup group) {
    final entry = group.activeEntry;
    final base = _contentData;
    if (entry == null || base == null) return;
    setState(() {
      _contentData = tarotContentWithSummary(
        base,
        ReadingVersionPayload.tarotSummary(entry.data),
      );
    });
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
      return Scaffold(
        backgroundColor: AppColors.background,
        body: TarotLoading(message: TarotPolishCopy.interpreting),
      );
    }

    if (_contentData == null) {
      final session = TarotScope.of(context).reading.session;
      final cost = session == null
          ? TarotEconomy.readingCost
          : TarotEconomy.costFor(session.spread);
      final insufficient =
          cost != null && ref.read(gemWalletServiceProvider).balance < cost;
      return Scaffold(
        backgroundColor: AppColors.background,
        body: TarotErrorState(
          message: insufficient
              ? GemsCopy.insufficient
              : (_loadError ?? TarotPolishCopy.interpretFailed),
          onRetry: () {
            setState(() {
              _loading = true;
              _loadError = null;
            });
            _loadReading();
          },
        ),
      );
    }

    final contentData = _contentData!;
    final card = ReadingPremiumUtils.primaryCard(contentData);
    final elementTheme = ReadingElementTheme.fromCard(card);

    return QualityLoopGate(
      feature: QualityFeature.tarot,
      child: PopScope(
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
                            kicker: contentData.spreadLabel ??
                                contentData.cardName,
                            padding: EdgeInsets.only(
                              top: showIntro ? 0 : AppSpacing.md,
                              bottom: AppLayout.contentBottomBreath,
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
                                final draft = _tarotMomentDraft();
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ReadingPremiumBody(
                                      content: contentData,
                                      sectionMaster: sectionMaster,
                                      panelOpacity:
                                          _panelOpacityFor(sectionMaster),
                                      ambientPhase: _ambient.value,
                                      exitProgress: exitProgress,
                                    ),
                                    ReadingFooterActions(
                                      progress: readingFooterProgress(
                                        sectionMaster,
                                      ),
                                      exitProgress: exitProgress,
                                      onNewReading:
                                          _exiting ? null : _newReading,
                                      onSave: _journalPersisted
                                          ? null
                                          : _saveReading,
                                      onAskOracle: _openOracleConversation,
                                      onAddReflection: _journalPersisted
                                          ? _offerPersonalNote
                                          : null,
                                      shareDiscovery:
                                          DiscoveryShareBuilder.tarot(
                                        theme: contentData.spreadLabel ??
                                            contentData.readingTheme,
                                        cardName: contentData.cardName,
                                        cardAsset: contentData.imageAsset,
                                      ),
                                    ),
                                    if (draft != null && sectionMaster > 0.45)
                                      SaveFavoriteMomentLink(
                                        draft: draft,
                                        prepare: _prepareTarotMoment,
                                      ),
                                    if (_savedReadingId != null &&
                                        sectionMaster > 0.45)
                                      ReadingVersionHost(
                                        rootId: _savedReadingId!,
                                        kind: ReadingVersionKind.tarot,
                                        reloadToken: _versionReloadToken,
                                        onSelect: _applyTarotVersion,
                                      ),
                                    if (sectionMaster > 0.45)
                                      ReadingQualityActions(
                                        feature: QualityFeature.tarot,
                                        retry: _reinterpretWithoutCharge,
                                      ),
                                    SizedBox(
                                      height: AppLayout.scrollBottomInset(
                                        context,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Smooth transition from card reveal into AI reading.
Route<T> readingRitualRoute<T>({
  required Widget page,
  RouteSettings? settings,
}) {
  return tarotRitualDepthHandoffRoute<T>(
    page: page,
    settings: settings,
    duration: TarotTokens.ritualReadingHandoff,
  );
}
