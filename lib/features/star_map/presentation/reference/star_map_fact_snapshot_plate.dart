/// Natal fact snapshot — a quiet observatory plate above the reading.
///
/// Renders ONLY the finished, localized [YildiznameFactSnapshot] it is handed:
/// no request maps, no wire values, no fact references, no certainty words.
/// Sun · Moon · Ascendant · Midheaven lead; the personal planets follow as one
/// calm line; everything deeper stays folded behind a single toggle so the
/// reading summary — not the data — remains the hero of the screen.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../result/yildizname_fact_snapshot.dart';

class StarMapFactSnapshotPlate extends StatefulWidget {
  const StarMapFactSnapshotPlate({super.key, required this.snapshot});

  final YildiznameFactSnapshot snapshot;

  @override
  State<StarMapFactSnapshotPlate> createState() =>
      _StarMapFactSnapshotPlateState();
}

class _StarMapFactSnapshotPlateState extends State<StarMapFactSnapshotPlate> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.snapshot;
    if (s.isEmpty) return const SizedBox.shrink();
    final showDeeper = s.hasDeeper;
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        container: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: OraclyChrome.cardRadius,
            color: OraclyChrome.cream.withValues(alpha: 0.035),
            border: Border.all(
              color: OraclyChrome.goldLight.withValues(alpha: 0.20),
              width: 0.8,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    s.title,
                    style: ReadingTypography.metadata(
                      color: OraclyChrome.goldLight.withValues(alpha: 0.78),
                    ),
                  ),
                ),
                if (s.primary.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.sm + 2),
                  _PrimaryGrid(facts: s.primary),
                ],
                if (s.secondary.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.sm + 2),
                  const _Hairline(),
                  SizedBox(height: AppSpacing.sm + 2),
                  _InlineFacts(facts: s.secondary),
                ],
                if (showDeeper) ...[
                  SizedBox(height: AppSpacing.xs),
                  _MoreToggle(
                    label: s.moreLabel,
                    open: _open,
                    onToggle: () => setState(() => _open = !_open),
                  ),
                  if (_open) _Deeper(snapshot: s),
                ] else
                  SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sun / Moon / Ascendant / Midheaven — one or two columns by real width.
class _PrimaryGrid extends StatelessWidget {
  const _PrimaryGrid({required this.facts});

  final List<YildiznameDisplayFact> facts;

  static const double _gap = 10;
  static const double _minTile = 116;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final minTile = _minTile * (1 + (scale - 1).clamp(0.0, 1.0) * 0.6);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ((constraints.maxWidth + _gap) / (minTile + _gap))
            .floor()
            .clamp(1, 2);
        final tileWidth =
            (constraints.maxWidth - _gap * (columns - 1)) / columns;
        return Wrap(
          spacing: _gap,
          runSpacing: AppSpacing.sm + 2,
          children: [
            for (final fact in facts)
              SizedBox(
                width: tileWidth,
                child: _PrimaryTile(fact: fact),
              ),
          ],
        );
      },
    );
  }
}

class _PrimaryTile extends StatelessWidget {
  const _PrimaryTile({required this.fact});

  final YildiznameDisplayFact fact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey(fact.subject),
      container: true,
      label: fact.semanticsLabel,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fact.label,
              style: ReadingTypography.metadata(
                color: OraclyChrome.goldLight.withValues(alpha: 0.70),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              fact.value,
              style:
                  ReadingTypography.body(
                    color: OraclyChrome.cream.withValues(alpha: 0.96),
                  ).copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
            ),
            if (fact.detail != null)
              Text(
                fact.detail!,
                style: ReadingTypography.metadata(
                  color: OraclyChrome.cream.withValues(alpha: 0.62),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Personal / outer planets — one wrapping line of "Body Sign detail" items.
class _InlineFacts extends StatelessWidget {
  const _InlineFacts({required this.facts});

  final List<YildiznameDisplayFact> facts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [for (final fact in facts) _InlineFact(fact: fact)],
    );
  }
}

class _InlineFact extends StatelessWidget {
  const _InlineFact({required this.fact});

  final YildiznameDisplayFact fact;

  @override
  Widget build(BuildContext context) {
    final muted = ReadingTypography.metadata(
      color: OraclyChrome.cream.withValues(alpha: 0.62),
    ).copyWith(fontSize: 13);
    return Semantics(
      key: ValueKey(fact.subject),
      container: true,
      label: fact.semanticsLabel,
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${fact.label} ',
                style: muted.copyWith(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.70),
                ),
              ),
              TextSpan(
                text: fact.value,
                style: muted.copyWith(
                  color: OraclyChrome.cream.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (fact.detail != null)
                TextSpan(text: ' ${fact.detail}', style: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      height: 1,
      color: OraclyChrome.goldLight.withValues(alpha: 0.12),
    ),
  );
}

/// The single interactive element — a full-width, ≥44px toggle.
class _MoreToggle extends StatelessWidget {
  const _MoreToggle({
    required this.label,
    required this.open,
    required this.onToggle,
  });

  final String label;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      expanded: open,
      label: label,
      onTap: onToggle,
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: const ValueKey('starFactMoreToggle'),
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: ReadingTypography.footnote(
                        color: OraclyChrome.goldLight.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                  Icon(
                    open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: OraclyChrome.goldLight.withValues(alpha: 0.78),
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

/// Outer planets · closest aspects · dominant balance — restrained, compact.
class _Deeper extends StatelessWidget {
  const _Deeper({required this.snapshot});

  final YildiznameFactSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    final muted = ReadingTypography.metadata(
      color: OraclyChrome.cream.withValues(alpha: 0.62),
    ).copyWith(fontSize: 13);
    Widget heading(String text) => Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs + 2),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: ReadingTypography.metadata(
            color: OraclyChrome.goldLight.withValues(alpha: 0.70),
          ),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (s.outer.isNotEmpty) ...[
            heading(s.outerLabel),
            _InlineFacts(facts: s.outer),
            SizedBox(height: AppSpacing.sm + 2),
          ],
          if (s.aspects.isNotEmpty) ...[
            heading(s.aspectsLabel),
            for (final a in s.aspects)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Semantics(
                  container: true,
                  label: a.semanticsLabel,
                  child: ExcludeSemantics(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${a.first} · ${a.second}',
                            style: muted.copyWith(
                              color: OraclyChrome.cream.withValues(alpha: 0.92),
                            ),
                          ),
                          TextSpan(text: ' — ${a.type}', style: muted),
                        ],
                      ),
                      softWrap: true,
                    ),
                  ),
                ),
              ),
            SizedBox(height: AppSpacing.sm),
          ],
          for (final b in s.balances)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Semantics(
                container: true,
                label: b.semanticsLabel,
                child: ExcludeSemantics(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${b.label} ', style: muted),
                        TextSpan(
                          text: b.value,
                          style: muted.copyWith(
                            color: OraclyChrome.cream.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
