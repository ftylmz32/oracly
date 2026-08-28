/// Long-form reading scroll — calm physics, contextual kicker when useful.
library;

import 'package:flutter/material.dart';

import '../theme/craftsmanship_rhythm.dart';
import 'reading_sticky_kicker.dart';

class ReadingLongFormScroll extends StatefulWidget {
  const ReadingLongFormScroll({
    super.key,
    required this.children,
    this.padding,
    this.kicker,
    this.controller,
    this.restorationId,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final String? kicker;
  final ScrollController? controller;
  final String? restorationId;

  @override
  State<ReadingLongFormScroll> createState() => _ReadingLongFormScrollState();
}

class _ReadingLongFormScrollState extends State<ReadingLongFormScroll> {
  bool _showKicker = false;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification.metrics.axis != Axis.vertical) return false;
    final show = notification.metrics.pixels > 56;
    if (show != _showKicker) setState(() => _showKicker = show);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.kicker?.trim() ?? '';
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          CustomScrollView(
            controller: widget.controller,
            restorationId: widget.restorationId,
            physics: CraftsmanshipRhythm.scrollPhysics,
            slivers: [
              SliverPadding(
                padding: widget.padding ?? EdgeInsets.zero,
                sliver: SliverList.list(children: widget.children),
              ),
            ],
          ),
          if (_showKicker && title.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ReadingStickyKicker(title: title),
            ),
        ],
      ),
    );
  }
}
