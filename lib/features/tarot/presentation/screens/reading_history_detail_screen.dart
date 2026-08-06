/// OR-1170 — Reading history detail with hero transition.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/copy/transparency_copy.dart';
import '../../../../core/copy/session_ending_copy.dart';
import '../../../../core/domain/models/reading.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../theme/tarot_tokens.dart';
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
    final summary = model?.aiSummary ?? widget.entry.aiSummary;
    final closing = _extractSection(summary, 'kapanış').trim();

    return AiReadingContent(
      cardName: widget.entry.cardName,
      tagline: widget.entry.spreadType,
      generalMeaning: summary,
      love: _extractSection(summary, 'aşk'),
      career: _extractSection(summary, 'kariyer'),
      money: _extractSection(summary, 'para'),
      spiritualGuidance: _extractSection(summary, 'ruhsal'),
      luckyEnergy: widget.entry.spreadType,
      dailyAdvice: _extractSection(summary, 'tavsiye'),
      closingMessage:
          closing.isNotEmpty ? closing : SessionEndingCopy.closingFallback,
      imageAsset: widget.entry.cardImageAsset,
      rarityColor: AppColors.purpleLight,
      fullInterpretation: summary,
    );
  }

  String _extractSection(String text, String key) {
    final pattern = RegExp('##\\s+$key[\\s\\S]*?(?=##|\$)', caseSensitive: false);
    final match = pattern.firstMatch(text);
    if (match == null) return text.split('\n').first;
    return match.group(0)!.replaceFirst(RegExp('##\\s+$key\\s*', caseSensitive: false), '').trim();
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

  Future<void> _toggleFavorite() async {
    await ref.read(readingServiceProvider).toggleFavorite(widget.entry.id);
    ref.invalidate(readingHistoryProvider);
    if (!mounted) return;
    setState(() => _isFavorite = !_isFavorite);
  }

  Future<void> _deleteReading() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(TransparencyCopy.deleteReadingTitle),
        content: const Text(TransparencyCopy.deleteReadingBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(TransparencyCopy.deleteReadingCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              TransparencyCopy.deleteReadingConfirm,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(historyServiceProvider).remove(widget.entry.id);
    ref.invalidate(readingHistoryProvider);
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
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: TarotTokens.screenPadding.horizontal,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.goldLight,
                        ),
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
                              '${widget.entry.dateLabel} · ${widget.entry.spreadType}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleFavorite,
                        tooltip: _isFavorite ? 'Hatıradan çıkar' : 'Hatıra olarak işaretle',
                        icon: Icon(
                          _isFavorite
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          color: _isFavorite
                              ? AppColors.goldLight
                              : AppColors.textSecondary,
                        ),
                      ),
                      Hero(
                        tag: widget.entry.heroTag,
                        child: ClipRRect(
                          borderRadius: AppRadius.xs,
                          child: Image.asset(
                            widget.entry.cardImageAsset,
                            width: 44,
                            height: 64,
                            fit: BoxFit.cover,
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
                        _reveal.value,
                      );
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: TarotTokens.screenPadding.copyWith(top: 0),
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
                                      'Bu yansımayı sil',
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

PageRouteBuilder<T> historyDetailRoute<T>({
  required ReadingHistoryEntry entry,
}) {
  return PageRouteBuilder<T>(
    settings: RouteSettings(name: '/tarot/history/${entry.id}'),
    transitionDuration: const Duration(milliseconds: 900),
    reverseTransitionDuration: const Duration(milliseconds: 700),
    pageBuilder: (context, animation, secondaryAnimation) =>
        ReadingHistoryDetailScreen(entry: entry),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );
      return FadeTransition(opacity: fade, child: child);
    },
  );
}
