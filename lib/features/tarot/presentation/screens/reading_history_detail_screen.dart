/// OR-1170 — Reading history detail with hero transition.
library;

import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/oracly_page_transitions.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../personal_discovery/services/personal_discovery_refresh.dart';
import '../../../../core/copy/transparency_copy.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/design_system/app_icons.dart';
import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_header_action.dart';
import '../../../../core/domain/models/reading.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/ui/oracly_dialog.dart';
import '../../art/tarot_major_card_art.dart';
import '../../theme/tarot_tokens.dart';
import '../utils/saved_reading_parser.dart';
import '../widgets/ai_reading/ai_reading_content.dart';
import '../widgets/ai_reading/reading_glass_panel.dart';
import '../widgets/reading_history/reading_history_background.dart';
import '../widgets/reading_history/reading_history_data.dart';
import '../widgets/reading_history/reading_journal_keyword_chips.dart';
import '../widgets/reading_history/reading_journal_note_sheet.dart';
import '../widgets/reading_history/reading_journal_reflection_card.dart';

/// Opens a saved reading with smooth hero card transition.
class ReadingHistoryDetailScreen extends ConsumerStatefulWidget {
  const ReadingHistoryDetailScreen({
    super.key,
    required this.entry,
  });

  final ReadingHistoryEntry entry;

  @override
  ConsumerState<ReadingHistoryDetailScreen> createState() =>
      _ReadingHistoryDetailScreenState();
}

class _ReadingHistoryDetailScreenState
    extends ConsumerState<ReadingHistoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;
  late bool _isFavorite;
  String? _personalNote;

  @override
  void initState() {
    super.initState();
    _personalNote = widget.entry.personalNote;
    _isFavorite = widget.entry.isFavorite;
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  AiReadingContent _contentFromEntry(ReadingModel? model) {
    return SavedReadingParser.toContent(entry: widget.entry, model: model);
  }

  Future<void> _editReflection() async {
    final note = await showReadingJournalNoteSheet(
      context: context,
      initialNote: _personalNote,
      cardName: widget.entry.cardName,
    );
    if (note == null) return;
    await ref.read(readingServiceProvider).updatePersonalNote(
          readingId: widget.entry.id,
          note: note.isEmpty ? null : note,
        );
    ref.invalidate(readingHistoryProvider);
    if (!mounted) return;
    setState(() => _personalNote = note.isEmpty ? null : note);
  }

  bool _favoriteBusy = false;

  Future<void> _toggleFavorite() async {
    if (_favoriteBusy) return;
    _favoriteBusy = true;
    final next = !_isFavorite;
    setState(() => _isFavorite = next);
    try {
      await ref.read(readingServiceProvider).toggleFavorite(widget.entry.id);
      ref.invalidate(readingHistoryProvider);
    } catch (_) {
      if (mounted) setState(() => _isFavorite = !next);
    } finally {
      _favoriteBusy = false;
    }
  }

  Future<void> _deleteReading() async {
    final confirmed = await OraclyDialog.confirm(
      context,
      title: TransparencyCopy.deleteReadingTitle,
      message: TransparencyCopy.deleteReadingBody,
      confirmLabel: TransparencyCopy.deleteReadingConfirm,
      cancelLabel: TransparencyCopy.deleteReadingCancel,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    await ref.read(historyServiceProvider).remove(widget.entry.id);
    ref.invalidate(readingHistoryProvider);
    PersonalDiscoveryRefresh.invalidate(ref);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ReadingModel? model;
    final readings = ref.watch(readingHistoryProvider).valueOrNull;
    if (readings != null) {
      for (final r in readings) {
        if (r.id == widget.entry.id) {
          model = r;
          break;
        }
      }
    }
    return _buildScaffold(_contentFromEntry(model));
  }

  Widget _buildScaffold(AiReadingContent content) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ReadingHistoryBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.screenHorizontal,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      OraclyHeaderAction(
                        icon: AppIcons.back,
                        label: OraclyL10n.t(L10nKeys.back),
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.entry.cardName,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.goldLight,
                              ),
                            ),
                            Text(
                              '${widget.entry.dateLabel} · ${widget.entry.typeLabel}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OraclyHeaderAction(
                        icon: _isFavorite
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        label: _isFavorite
                            ? OraclyL10n.t('tarot.memory.remove')
                            : OraclyL10n.t('tarot.memory.add'),
                        onTap: _toggleFavorite,
                      ),
                      Hero(
                        tag: widget.entry.heroTag,
                        child: ClipRRect(
                          borderRadius: AppRadius.xs,
                          child: SizedBox(
                            width: 44,
                            height: 64,
                            child: Transform.rotate(
                              angle: widget.entry.isReversed ? pi : 0,
                              child: TarotMajorCardArt(
                                imageAsset: widget.entry.cardImageAsset,
                                showChrome: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _reveal,
                    builder: (context, _) {
                      final master = Curves.easeOutCubic.transform(
                        _reveal.value.clamp(0.0, 1.0),
                      );
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: TarotTokens.screenPaddingOf(context)
                            .copyWith(top: 0),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: TarotTokens.maxContentWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (widget.entry.emotionalKeywords.isNotEmpty) ...[
                                  ReadingJournalKeywordChips(
                                    keywords: widget.entry.emotionalKeywords,
                                  ),
                                  SizedBox(height: AppSpacing.md),
                                ],
                                ReadingJournalReflectionCard(
                                  note: _personalNote,
                                  onEdit: _editReflection,
                                ),
                                SizedBox(height: AppSpacing.lg),
                                ReadingGlassPanel(
                                  content: content,
                                  sectionMaster: master,
                                  panelOpacity: master.clamp(0.0, 1.0),
                                ),
                                SizedBox(height: AppSpacing.lg),
                                Center(
                                  child: TextButton.icon(
                                    onPressed: _deleteReading,
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: AppColors.textHint,
                                    ),
                                    label: Text(
                                      OraclyL10n.t('tarot.history.delete_reflection'),
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: AppSpacing.lg),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Route<T> historyDetailRoute<T>({
  required ReadingHistoryEntry entry,
}) {
  return OraclyPageTransitions.fade<T>(
    page: ReadingHistoryDetailScreen(entry: entry),
    settings: RouteSettings(name: '/tarot/history/${entry.id}'),
    duration: const Duration(milliseconds: 480),
    reverseDuration: const Duration(milliseconds: 360),
  );
}
