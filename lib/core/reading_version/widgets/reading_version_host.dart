/// Loads version group and renders strip — parent applies selected payload.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reading_version_group.dart';
import '../models/reading_version_kind.dart';
import '../providers/reading_version_providers.dart';
import '../widgets/reading_version_compare_sheet.dart';
import '../widgets/reading_version_strip.dart';

class ReadingVersionHost extends ConsumerStatefulWidget {
  const ReadingVersionHost({
    super.key,
    required this.rootId,
    required this.kind,
    required this.reloadToken,
    this.onSelect,
  });

  final String rootId;
  final ReadingVersionKind kind;
  final int reloadToken;
  final ValueChanged<ReadingVersionGroup>? onSelect;

  @override
  ConsumerState<ReadingVersionHost> createState() => _ReadingVersionHostState();
}

class _ReadingVersionHostState extends ConsumerState<ReadingVersionHost> {
  ReadingVersionGroup? _group;

  @override
  void didUpdateWidget(covariant ReadingVersionHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken ||
        oldWidget.rootId != widget.rootId) {
      _load();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final group = ref.read(readingVersionServiceProvider).groupFor(widget.rootId);
    if (!mounted) return;
    setState(() => _group = group);
  }

  Future<void> _pick(int number) async {
    final service = ref.read(readingVersionServiceProvider);
    final group = await service.selectVersion(
      rootId: widget.rootId,
      number: number,
    );
    if (!mounted) return;
    setState(() => _group = group);
    widget.onSelect?.call(group);
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    if (group == null || !group.hasRevisions) return const SizedBox.shrink();
    return ReadingVersionStrip(
      group: group,
      onSelect: _pick,
      onCompare: () => showReadingVersionCompareSheet(
        context: context,
        group: group,
        preview: (data) => readingVersionPreview(widget.kind, data),
      ),
    );
  }
}
