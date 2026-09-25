/// OR-1170 — Reading history detail with hero transition.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../personal_discovery/services/personal_discovery_refresh.dart';
import '../../../../core/copy/resilience_copy.dart';
import '../../../../core/copy/transparency_copy.dart';
import '../../../../core/domain/models/reading.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/ui/oracly_dialog.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../utils/saved_reading_parser.dart';
import '../widgets/reading_history/reading_history_background.dart';
import '../widgets/reading_history/reading_history_data.dart';
import '../widgets/reading_history/reading_journal_note_sheet.dart';
import 'reading_history_detail_body.dart';
import 'reading_history_detail_header.dart';

export 'reading_history_detail_route.dart';

/// Opens a saved reading — persisted artifact viewer (Phase 7F).
class ReadingHistoryDetailScreen extends ConsumerStatefulWidget {
  const ReadingHistoryDetailScreen({super.key, required this.entry});

  final ReadingHistoryEntry entry;

  @override
  ConsumerState<ReadingHistoryDetailScreen> createState() =>
      _ReadingHistoryDetailScreenState();
}

class _ReadingHistoryDetailScreenState
    extends ConsumerState<ReadingHistoryDetailScreen> {
  late bool _isFavorite;
  String? _personalNote;
  bool _favoriteBusy = false;

  @override
  void initState() {
    super.initState();
    _personalNote = widget.entry.personalNote;
    _isFavorite = widget.entry.isFavorite;
  }

  Future<void> _editReflection() async {
    final note = await showReadingJournalNoteSheet(
      context: context,
      initialNote: _personalNote,
      cardName: widget.entry.primaryCardLabel,
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

    try {
      await ref
          .read(tarotHistoryDeletionServiceProvider)
          .deleteReading(widget.entry.id);
    } catch (_) {
      if (!mounted) return;
      OraclySnackBar.error(context, ResilienceCopy.temporaryFailure);
      return;
    }

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
    final content = SavedReadingParser.toContent(
      entry: widget.entry,
      model: model,
    );
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
                ReadingHistoryDetailHeader(
                  entry: widget.entry,
                  isFavorite: _isFavorite,
                  onBack: () => Navigator.of(context).pop(),
                  onFavorite: _toggleFavorite,
                ),
                Expanded(
                  child: ReadingHistoryDetailBody(
                    entry: widget.entry,
                    model: model,
                    content: content,
                    personalNote: _personalNote,
                    onEditReflection: _editReflection,
                    onDelete: _deleteReading,
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
