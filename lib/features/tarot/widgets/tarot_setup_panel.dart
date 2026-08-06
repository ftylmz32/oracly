import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/tarot_select_phase.dart';
import 'tarot_buttons.dart';
import 'tarot_section_heading.dart';
import 'tarot_spread_tile.dart';
import 'tarot_typography.dart';

class _SpreadOption {
  const _SpreadOption(this.count, this.title, this.subtitle, this.icon);
  final int count;
  final String title;
  final String subtitle;
  final IconData icon;
}

const _spreads = [
  _SpreadOption(1, 'Tek Kart', 'Tek bir mesaj', Icons.style_outlined),
  _SpreadOption(3, 'Üç Kart Açılımı', 'Geçmiş · Şimdi · Gelecek', Icons.filter_3_outlined),
  _SpreadOption(3, 'Aşk', 'Kalp & bağ', Icons.favorite_outline),
  _SpreadOption(3, 'Haftalık', '7 günlük rehber', Icons.calendar_today_outlined),
  _SpreadOption(3, 'Karma', 'Dersler & denge', Icons.all_inclusive),
  _SpreadOption(10, 'Kelt Haçı', 'Derin ruhsal açılım', Icons.grid_view_rounded),
];

class TarotSetupPanel extends StatefulWidget {
  const TarotSetupPanel({
    super.key,
    required this.intentionController,
    required this.spread,
    required this.phase,
    required this.onSpreadChanged,
    required this.onShuffle,
  });

  final TextEditingController intentionController;
  final int spread;
  final TarotSelectPhase phase;
  final ValueChanged<int> onSpreadChanged;
  final VoidCallback onShuffle;

  @override
  State<TarotSetupPanel> createState() => _TarotSetupPanelState();
}

class _TarotSetupPanelState extends State<TarotSetupPanel> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _syncIndex();
  }

  @override
  void didUpdateWidget(covariant TarotSetupPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spread != widget.spread) _syncIndex();
  }

  void _syncIndex() {
    final idx = _spreads.indexWhere((s) => s.count == widget.spread);
    if (idx >= 0) _selectedIndex = idx;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.phase.canEditSetup;
    final busy = widget.phase.isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TarotSectionHeading(title: 'Açılım Türleri'),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _spreads.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.35,
              ),
              itemBuilder: (_, i) {
                final s = _spreads[i];
                return TarotSpreadTile(
                  title: s.title,
                  subtitle: s.subtitle,
                  icon: s.icon,
                  selected: _selectedIndex == i,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                TextField(
                  controller: widget.intentionController,
                  enabled: enabled,
                  maxLines: 1,
                  style: TarotTypography.body(size: 14),
                  decoration: InputDecoration(
                    hintText: 'Niyetini yaz (isteğe bağlı)',
                    hintStyle: TarotTypography.captionMuted(),
                    filled: true,
                    fillColor: AppColors.card.withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.15),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TarotGoldButton(
                  label: 'Kartları Karıştır',
                  busy: busy,
                  onPressed: enabled && !busy ? widget.onShuffle : null,
                ),
              ],
            ),
          ),
        ),
        ),
      ],
    );
  }
}
