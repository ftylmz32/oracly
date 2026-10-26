/// ORACLY EVRENİM — first read-only vertical slice.
///
/// Every star is backed by an existing real DiscoveryJournalEntry. User-created
/// links are deliberately NOT simulated here; see product issue #45 (slice B).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/oracly_navigation_service.dart';
import '../../discovery_journal/models/discovery_journal_entry.dart';
import '../../discovery_journal/providers/discovery_journal_providers.dart';
import '../../discovery_journal/services/discovery_journal_opener.dart';
import '../domain/evrenim_constellation_layout.dart';

class EvrenimScreen extends ConsumerStatefulWidget {
  const EvrenimScreen({super.key});

  @override
  ConsumerState<EvrenimScreen> createState() => _EvrenimScreenState();
}

class _EvrenimScreenState extends ConsumerState<EvrenimScreen> {
  bool _showList = false;

  static const Color _gold = Color(0xFFE8C872);
  static const Color _ivory = Color(0xFFF3EADF);
  static const Color _night = Color(0xFF02030A);

  @override
  Widget build(BuildContext context) {
    final journal = ref.watch(discoveryJournalEntriesProvider);

    return Scaffold(
      backgroundColor: _night,
      appBar: AppBar(
        backgroundColor: _night,
        foregroundColor: _ivory,
        title: const Text('Evrenim'),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showList = !_showList),
            icon: Icon(
              _showList ? Icons.auto_awesome_outlined : Icons.list_rounded,
              color: _gold,
            ),
            label: Text(
              _showList ? 'Harita' : 'Liste',
              style: const TextStyle(color: _gold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: journal.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _error(),
          data: (entries) {
            if (entries.isEmpty) return _empty();
            final sorted = [...entries]
              ..sort((a, b) => b.date.compareTo(a.date));
            return _showList ? _list(sorted) : _map(sorted);
          },
        ),
      ),
    );
  }

  Widget _error() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Keşiflerin şu anda yüklenemiyor.',
            style: TextStyle(color: _ivory),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.invalidate(discoveryJournalEntriesProvider),
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_outlined, size: 64, color: _gold),
            const SizedBox(height: 24),
            const Text(
              'Evrenin ilk keşfinle başlayacak.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ivory,
                fontSize: 23,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Yıldızların, yalnızca gerçekten tamamladığın deneyimlerden oluşur.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _ivory, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  OraclyNavigationService.startDailyCardDraw(context),
              child: const Text('İlk keşfini başlat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<DiscoveryJournalEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          color: const Color(0xFF16122A),
          child: ListTile(
            leading: const Icon(Icons.auto_awesome_outlined, color: _gold),
            title: Text(
              entry.title,
              maxLines: 2,
              style: const TextStyle(color: _ivory),
            ),
            subtitle: Text(
              '${entry.kind.name} · ${entry.dateLabel}',
              style: const TextStyle(color: Color(0xFFCEBEDC)),
            ),
            trailing: const Icon(Icons.chevron_right, color: _gold),
            onTap: () => _openDetail(entry),
          ),
        );
      },
    );
  }

  Widget _map(List<DiscoveryJournalEntry> entries) {
    // Bounded first viewport: the full collection remains accessible in List.
    final visible = entries.take(12).toList(growable: false);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
          child: Column(
            children: [
              const Text(
                'Her yıldız, sana ait gerçek bir keşif.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _ivory, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                '${visible.length} yıldız gösteriliyor · ${entries.length} kayıt',
                style: const TextStyle(color: _gold, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final width = box.maxWidth;
              final height = box.maxHeight;
              return InteractiveViewer(
                constrained: true,
                boundaryMargin: const EdgeInsets.all(90),
                minScale: 0.8,
                maxScale: 2.5,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 1.1,
                              colors: [
                                Color(0xFF251343),
                                Color(0xFF0A1224),
                                _night,
                              ],
                            ),
                          ),
                        ),
                      ),
                      for (final entry in visible)
                        _star(entry, width: width, height: height),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _star(
    DiscoveryJournalEntry entry, {
    required double width,
    required double height,
  }) {
    const targetWidth = 88.0;
    const targetHeight = 82.0;
    final p = EvrenimConstellationLayout.forReading(
      kind: entry.kind.name,
      id: entry.id,
    );
    return Positioned(
      left: p.x * (width - targetWidth),
      top: p.y * (height - targetHeight),
      child: Semantics(
        button: true,
        label: '${entry.kind.name}, ${entry.dateLabel}, ${entry.title}',
        child: GestureDetector(
          onTap: () => _openDetail(entry),
          child: SizedBox(
            width: targetWidth,
            height: targetHeight,
            child: Column(
              children: [
                Container(
                  height: 49,
                  width: 49,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF241646),
                    border: Border.all(color: _gold, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x665A3FD6),
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: _gold,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _ivory, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail(DiscoveryJournalEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF16122A),
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                entry.title,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${entry.kind.name} · ${entry.dateLabel}',
                style: const TextStyle(color: _ivory),
              ),
              if (entry.preview.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  entry.preview,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _ivory, height: 1.5),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Orijinal deneyimi aç'),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  DiscoveryJournalOpener.open(context, ref, entry);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
