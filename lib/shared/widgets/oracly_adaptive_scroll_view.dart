/// Scrolls only when content exceeds the viewport — no rubber-band on short pages.
library;

import 'package:flutter/material.dart';

import '../../core/theme/craftsmanship_rhythm.dart';

/// Fills the viewport when content is short; scrolls only when content overflows.
class OraclyAdaptiveScrollView extends StatefulWidget {
  const OraclyAdaptiveScrollView({
    super.key,
    required this.child,
    this.padding,
    this.physics,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  State<OraclyAdaptiveScrollView> createState() =>
      _OraclyAdaptiveScrollViewState();
}

class _OraclyAdaptiveScrollViewState extends State<OraclyAdaptiveScrollView> {
  final GlobalKey _contentKey = GlobalKey();
  double? _viewportHeight;
  double? _contentHeight;

  bool get _needsScroll {
    // Assume scrollable until measured — avoids a frozen first frame on long pages.
    if (_viewportHeight == null || _contentHeight == null) return true;
    return _contentHeight! > _viewportHeight! + 0.5;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measureContent);
  }

  void _measureContent(_) {
    if (!mounted) return;

    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final height = box.size.height;
    if (_contentHeight != height) {
      setState(() => _contentHeight = height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_viewportHeight != constraints.maxHeight) {
          _viewportHeight = constraints.maxHeight;
          WidgetsBinding.instance.addPostFrameCallback(_measureContent);
        }

        return NotificationListener<SizeChangedLayoutNotification>(
          onNotification: (_) {
            WidgetsBinding.instance.addPostFrameCallback(_measureContent);
            return false;
          },
          child: SingleChildScrollView(
            physics: _needsScroll
                ? (widget.physics ?? CraftsmanshipRhythm.scrollPhysics)
                : const NeverScrollableScrollPhysics(),
            padding: widget.padding,
            child: SizeChangedLayoutNotifier(
              child: KeyedSubtree(
                key: _contentKey,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
