import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../widgets/luxury_glass_surface.dart';

class RecentSection extends StatelessWidget {
  const RecentSection({super.key, this.lastConversation});

  final String? lastConversation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.38),
              letterSpacing: 2.0,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          LuxuryGlassSurface(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            child: Column(
              children: [
                _RecentRow(label: 'Last Tarot', value: 'No reading yet'),
                _divider(),
                _RecentRow(label: 'Last Dream', value: 'No dream recorded'),
                _divider(),
                _RecentRow(
                  label: 'Last Conversation',
                  value: lastConversation ?? 'No conversation yet',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.07),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.42),
              letterSpacing: 0.5,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTextStyles.subtitle.copyWith(
              fontSize: 13.5,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
        ),
      ],
    );
  }
}
