/// Center slot of [OraclyAppBar] — identity widget or engraved title.
library;

import 'package:flutter/material.dart';

import 'oracly_chrome.dart';

class OraclyAppBarTitle extends StatelessWidget {
  const OraclyAppBarTitle({
    super.key,
    required this.title,
    this.titleChild,
    this.titleIcon,
    this.titleIconSize = OraclyChrome.titleMarkSize,
  });

  final String title;
  final Widget? titleChild;
  final IconData? titleIcon;
  final double titleIconSize;

  @override
  Widget build(BuildContext context) {
    final custom = titleChild;
    if (custom != null) {
      return Semantics(
        header: true,
        label: title,
        child: Center(
          child: FittedBox(fit: BoxFit.scaleDown, child: custom),
        ),
      );
    }
    final mark = titleIcon;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mark != null) ...[
          Icon(
            mark,
            size: titleIconSize,
            color: OraclyChrome.goldHighlight.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 2),
        ],
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            style: OraclyChrome.engravedTitle(size: 12.5),
          ),
        ),
      ],
    );
  }
}
