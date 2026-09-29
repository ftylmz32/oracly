import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../../daily_message/copy/daily_message_copy.dart';

class HomeDailyMessageTeaserBody extends StatelessWidget {
  const HomeDailyMessageTeaserBody({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${DailyMessageCopy.prompt}. $text',
      child: OraclyPressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 10, 2, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DailyMessageCopy.prompt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _label,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: OraclyChrome.goldLight.withValues(alpha: 0.72),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _label = ReadingTypography.eyebrow(
  color: OraclyChrome.goldLight.withValues(alpha: 0.90),
  fontSize: 11,
).copyWith(letterSpacing: CraftsmanshipRhythm.sectionLabelTracking + 0.2);

final _body = ReadingTypography.bodyCore(
  color: OraclyChrome.cream.withValues(alpha: 0.88),
).copyWith(fontSize: 13.5, height: 1.38);
