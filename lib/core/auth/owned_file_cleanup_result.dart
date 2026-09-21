/// Result of STRICT Coffee/Palm owned-file cleanup for account-boundary wipe.
library;

/// Tells [UserLocalDataWipe] whether Coffee/Palm reading metadata may be
/// cleared after a (possibly incomplete) owned-file cleanup pass.
///
/// - [complete]: every known owned file was proven deleted.
/// - [metadataMayBeCleared]: every failed path (if any) still has a durable
///   locator — either the cleanup journal, or the reading metadata itself.
///   When this is `false`, metadata MUST NOT be erased or the surviving file
///   becomes unrecoverable forever.
class OwnedFileCleanupResult {
  const OwnedFileCleanupResult({
    required this.complete,
    required this.metadataMayBeCleared,
  });

  final bool complete;
  final bool metadataMayBeCleared;

  static const ok = OwnedFileCleanupResult(
    complete: true,
    metadataMayBeCleared: true,
  );

  /// Files remain, but every failed path was durably journaled.
  static const incompleteJournaled = OwnedFileCleanupResult(
    complete: false,
    metadataMayBeCleared: true,
  );

  /// Files remain AND the journal could not retain them — keep metadata.
  static const retainMetadata = OwnedFileCleanupResult(
    complete: false,
    metadataMayBeCleared: false,
  );
}
