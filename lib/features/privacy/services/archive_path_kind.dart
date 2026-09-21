/// Tri-state ownership for STRICT account-boundary archive cleanup.
library;

enum ArchivePathKind {
  owned,
  notOwned,
  /// path_provider / FS resolution failed — never treat as external success.
  unknown,
}
