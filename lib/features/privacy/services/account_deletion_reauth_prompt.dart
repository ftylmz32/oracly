/// Collects reauth credentials for account deletion — never a general login.
library;

import 'package:flutter/material.dart';

import '../../../../core/auth/auth_service.dart';
import '../../../../core/auth/models/account_reauth_method.dart';
import '../../../../core/auth/models/auth_credentials.dart';
import '../../../../shared/ui/oracly_password_confirm_dialog.dart';
import '../copy/privacy_control_copy.dart';

abstract final class AccountDeletionReauthPrompt {
  AccountDeletionReauthPrompt._();

  /// Returns credentials, or null when the user cancels.
  static Future<AccountReauthCredentials?> collect(
    BuildContext context,
    AuthService auth,
  ) async {
    if (auth.isCurrentUserAnonymous) return null;
    final methods = auth.currentReauthMethods;
    final preferred = AccountReauthMethodResolver.preferred(methods);
    if (preferred == null) {
      // Linked but unknown provider — refuse rather than invent a path.
      return null;
    }
    var method = preferred;
    if (methods.length > 1 && context.mounted) {
      final chosen = await _pickMethod(context, methods);
      if (chosen == null) return null;
      method = chosen;
    }
    if (!context.mounted) return null;
    return switch (method) {
      AccountReauthMethod.google => const AccountReauthCredentials.google(),
      AccountReauthMethod.apple => const AccountReauthCredentials.apple(),
      AccountReauthMethod.email => _email(context, auth),
    };
  }

  static Future<AccountReauthCredentials?> _email(
    BuildContext context,
    AuthService auth,
  ) async {
    final password = await OraclyPasswordConfirmDialog.show(
      context,
      title: PrivacyControlCopy.reauthPasswordTitle,
      message: PrivacyControlCopy.reauthPasswordBody,
      email: auth.currentUserEmail,
      confirmLabel: PrivacyControlCopy.reauthPasswordAction,
    );
    if (password == null || password.isEmpty) return null;
    final email = auth.currentUserEmail?.trim() ?? '';
    if (email.isEmpty) return null;
    return AccountReauthCredentials.email(
      EmailCredentials(email: email, password: password),
    );
  }

  static Future<AccountReauthMethod?> _pickMethod(
    BuildContext context,
    List<AccountReauthMethod> methods,
  ) async {
    return showModalBottomSheet<AccountReauthMethod>(
      context: context,
      backgroundColor: const Color(0xFF120E18),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final m in methods)
                ListTile(
                  title: Text(
                    PrivacyControlCopy.reauthMethodLabel(m),
                    style: const TextStyle(color: Color(0xFFF5F0E8)),
                  ),
                  onTap: () => Navigator.pop(ctx, m),
                ),
              ListTile(
                title: Text(
                  PrivacyControlCopy.reauthCancel,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }
}
