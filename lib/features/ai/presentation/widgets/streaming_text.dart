/// OR-1110 — Streaming text renderer for token-by-token display.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class StreamingText extends StatelessWidget {
  const StreamingText({
    super.key,
    required this.text,
    this.isStreaming = false,
    this.style,
  });

  final String text;
  final bool isStreaming;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ??
        AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.55,
        );

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text),
          if (isStreaming)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(left: 2),
                child: _BlinkingCursor(color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({required this.color});

  final Color color;

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _blink,
      child: Container(
        width: 2,
        height: 14,
        color: widget.color,
      ),
    );
  }
}
