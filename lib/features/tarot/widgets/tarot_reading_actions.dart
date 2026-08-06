import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/ui/oracly_snackbar.dart';
import 'tarot_buttons.dart';

class TarotReadingActions extends StatelessWidget {
  const TarotReadingActions({super.key, required this.shareText});

  final String shareText;

  Future<void> _share(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: shareText));
    if (!context.mounted) return;
    OraclySnackBar.success(context, 'Yorum panoya kopyalandı');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TarotGlassButton(
            label: 'Yeniden Açılım',
            icon: Icons.refresh_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TarotGoldButton(
            label: 'Paylaş',
            icon: Icons.ios_share_rounded,
            onPressed: () => _share(context),
          ),
        ),
      ],
    );
  }
}
