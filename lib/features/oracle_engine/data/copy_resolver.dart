/// OR-1140 — Locale-aware copy resolver contract.
library;

abstract class CopyResolver {
  String resolve(String key, String locale);
}

class KeyPassthroughCopyResolver implements CopyResolver {
  @override
  String resolve(String key, String locale) => key;
}
