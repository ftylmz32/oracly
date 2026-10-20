import 'package:flutter/material.dart';

import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_gold_button.dart';
import '../copy/reading_commerce_copy.dart';
import '../models/reading_commerce_view.dart';

class ReadingCommerceBody extends StatelessWidget {
  const ReadingCommerceBody({
    super.key,
    required this.view,
    this.onBuy,
  });

  final ReadingCommerceView view;
  final void Function(String productId)? onBuy;

  @override
  Widget build(BuildContext context) {
    final message = view.message ??
        (view.showCoffee || view.showPalm || view.showPack
            ? null
            : ReadingCommerceCopy.closed);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      children: [
        Text(
          ReadingCommerceCopy.title,
          textAlign: TextAlign.center,
          style: ReadingTypography.sectionLabel(color: OraclyChrome.goldLight),
        ),
        SizedBox(height: AppSpacing.s16),
        Text(
          ReadingCommerceCopy.credits(
            coffee: view.coffeeCredits,
            palm: view.palmCredits,
          ),
          textAlign: TextAlign.center,
          style: ReadingTypography.body(color: OraclyChrome.cream),
        ),
        if (message != null) ...[
          SizedBox(height: AppSpacing.s16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ReadingTypography.footnote(
              color: OraclyChrome.cream.withValues(alpha: 0.72),
            ),
          ),
        ],
        SizedBox(height: AppSpacing.s24),
        if (view.showCoffee)
          _Offer(
            title: ReadingCommerceCopy.coffee,
            price: view.coffeePrice!,
            onBuy: onBuy == null
                ? null
                : () => onBuy!(ReadingCommerceView.coffeeId),
          ),
        if (view.showPalm)
          _Offer(
            title: ReadingCommerceCopy.palm,
            price: view.palmPrice!,
            onBuy: onBuy == null
                ? null
                : () => onBuy!(ReadingCommerceView.palmId),
          ),
        if (view.showPack)
          _Offer(
            title: ReadingCommerceCopy.pack,
            price: view.packPrice!,
            onBuy: onBuy == null
                ? null
                : () => onBuy!(ReadingCommerceView.packId),
          ),
      ],
    );
  }
}

class _Offer extends StatelessWidget {
  const _Offer({required this.title, required this.price, this.onBuy});

  final String title;
  final String price;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: ReadingTypography.body(color: OraclyChrome.cream)),
          SizedBox(height: AppSpacing.s8),
          Text(price, style: ReadingTypography.reflection(color: OraclyChrome.goldLight)),
          SizedBox(height: AppSpacing.s8),
          OraclyGoldButton(
            label: ReadingCommerceCopy.buy,
            expanded: true,
            onPressed: onBuy,
          ),
        ],
      ),
    );
  }
}
