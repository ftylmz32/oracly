/// Reference dream actions — equal outline gold Write / Voice pills.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../features/dream/copy/dream_copy.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import 'dream_reference_tokens.dart';

class DreamReferenceActionButtons extends StatelessWidget {
  const DreamReferenceActionButtons({
    super.key,
    required this.onWriteTap,
    required this.onVoiceTap,
    this.voiceEnabled = false,
  });

  final VoidCallback onWriteTap;
  final VoidCallback onVoiceTap;
  final bool voiceEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OutlineAction(
            label: DreamCopy.writeDream,
            icon: Icons.edit_note_rounded,
            onTap: onWriteTap,
          ),
        ),
        SizedBox(width: DreamReferenceTokens.actionGap),
        Expanded(
          child: _OutlineAction(
            label: DreamCopy.voiceTell,
            icon: Icons.mic_none_rounded,
            onTap: onVoiceTap,
            enabled: voiceEnabled,
          ),
        ),
      ],
    );
  }
}

class _OutlineAction extends StatefulWidget {
  const _OutlineAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_OutlineAction> createState() => _OutlineActionState();
}

class _OutlineActionState extends State<_OutlineAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final gold = OraclyChrome.gold.withValues(
      alpha: enabled ? 0.70 : 0.40,
    );
    final labelColor = OraclyChrome.goldLight.withValues(
      alpha: enabled ? 0.96 : 0.55,
    );

    return Opacity(
      opacity: enabled ? 1 : 0.78,
      child: OraclyPressable(
        onTap: enabled ? widget.onTap : null,
        enabled: enabled,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        borderRadius: DreamReferenceTokens.actionRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: DreamReferenceTokens.actionRadius,
            color: OraclyChrome.deepNavy.withValues(
              alpha: _pressed ? 0.78 : 0.58,
            ),
            border: Border.all(color: gold, width: AppBorderWidth.thin),
            boxShadow: [
              BoxShadow(
                color: OraclyChrome.gold.withValues(
                  alpha: enabled ? 0.12 : 0.05,
                ),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: OraclyChrome.violet.withValues(
                  alpha: enabled ? 0.10 : 0.04,
                ),
                blurRadius: 12,
              ),
            ],
          ),
          child: SizedBox(
            height: DreamReferenceTokens.actionButtonHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: AppLayout.referenceIconSize,
                    color: labelColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OraclyChrome.sectionLabel(size: 12).copyWith(
                        color: labelColor,
                        letterSpacing: 0.15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
