/// Remote config fetch port — production backend plugs in here.
library;

abstract class RemoteConfigPort {
  Future<Map<String, Object?>?> fetch();
}

/// Fail-closed local port — returns null so defaults apply.
class LocalRemoteConfigPort implements RemoteConfigPort {
  const LocalRemoteConfigPort();

  @override
  Future<Map<String, Object?>?> fetch() async => null;
}
