/// Google Play / App Store closed-test reviewer access — code field only.
/// Grants a reviewer entitlement distinct from real Premium purchases; never
/// touches store commerce, purchase credentials, or billing verification.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/ui/oracly_bottom_sheet.dart';
import '../../../tarot/presentation/epic031/tarot_epic031_primary_button.dart';
import '../../providers/premium_providers.dart';

abstract final class ReviewAccessSheet {
  ReviewAccessSheet._();

  static Future<void> show(BuildContext context) {
    return OraclyBottomSheet.show<void>(
      context,
      title: 'Review access',
      child: const ReviewAccessBody(),
    );
  }
}

class ReviewAccessBody extends ConsumerStatefulWidget {
  const ReviewAccessBody({super.key});

  @override
  ConsumerState<ReviewAccessBody> createState() => _ReviewAccessBodyState();
}

enum _Status { idle, submitting, success, failure }

class _ReviewAccessBodyState extends ConsumerState<ReviewAccessBody> {
  final _controller = TextEditingController();
  _Status _status = _Status.idle;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() {
        _status = _Status.failure;
        _message = 'Enter the access code from the review instructions.';
      });
      return;
    }
    setState(() {
      _status = _Status.submitting;
      _message = null;
    });
    final granted = await ref
        .read(premiumStatusProvider)
        .activateReviewAccess(code);
    if (!mounted) return;
    setState(() {
      _status = granted ? _Status.success : _Status.failure;
      _message = granted
          ? 'Access granted. Premium areas are now unlocked for review.'
          : 'This code is not valid right now.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final busy = _status == _Status.submitting;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'For Google Play / App Store reviewers only. Enter the access '
            'code provided in the review notes to unlock Premium areas for '
            'this review.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: OraclyChrome.cream.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            enabled: !busy && _status != _Status.success,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            decoration: const InputDecoration(
              labelText: 'Review access code',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _activate(),
          ),
          if (_message != null) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: _status == _Status.success
                    ? OraclyChrome.goldLight
                    : OraclyChrome.cream.withValues(alpha: 0.82),
              ),
            ),
          ],
          SizedBox(height: AppSpacing.md),
          TarotEpic031PrimaryButton(
            label: busy
                ? 'Checking…'
                : (_status == _Status.success ? 'Access granted' : 'Activate'),
            onPressed: (busy || _status == _Status.success) ? null : _activate,
          ),
        ],
      ),
    );
  }
}
