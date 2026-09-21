/// Linked-account reauthentication methods for destructive actions.
library;

/// Provider-neutral reauth surface — never a Firebase User object.
enum AccountReauthMethod {
  google,
  apple,
  email,
}

abstract final class AccountReauthMethodResolver {
  AccountReauthMethodResolver._();

  /// Maps Firebase `providerData[].providerId` values to ORACLY methods.
  static List<AccountReauthMethod> fromProviderIds(Iterable<String> ids) {
    final out = <AccountReauthMethod>{};
    for (final raw in ids) {
      final id = raw.trim().toLowerCase();
      if (id == 'google.com') out.add(AccountReauthMethod.google);
      if (id == 'apple.com') out.add(AccountReauthMethod.apple);
      if (id == 'password') out.add(AccountReauthMethod.email);
    }
    return List<AccountReauthMethod>.unmodifiable(_ordered(out));
  }

  /// Prefer Google → Apple → email when several are linked.
  static AccountReauthMethod? preferred(Iterable<AccountReauthMethod> methods) {
    final set = methods.toSet();
    for (final m in AccountReauthMethod.values) {
      if (set.contains(m)) return m;
    }
    return null;
  }

  static List<AccountReauthMethod> _ordered(Set<AccountReauthMethod> set) {
    return [
      for (final m in AccountReauthMethod.values)
        if (set.contains(m)) m,
    ];
  }
}
