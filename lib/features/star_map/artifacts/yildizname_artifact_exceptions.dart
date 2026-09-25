/// Typed Yıldızname artifact failures — fail closed, never regenerate.
library;

sealed class YildiznameArtifactException implements Exception {
  const YildiznameArtifactException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class YildiznameArtifactOwnerUnavailableException
    extends YildiznameArtifactException {
  const YildiznameArtifactOwnerUnavailableException([
    super.message = 'owner unavailable',
  ]);
}

final class YildiznameArtifactCorruptException
    extends YildiznameArtifactException {
  const YildiznameArtifactCorruptException([super.message = 'corrupt artifact']);
}

final class YildiznameArtifactUnsupportedSchemaException
    extends YildiznameArtifactException {
  const YildiznameArtifactUnsupportedSchemaException([
    super.message = 'unsupported artifact schema',
  ]);
}

final class YildiznameArtifactDuplicateConflictException
    extends YildiznameArtifactException {
  const YildiznameArtifactDuplicateConflictException([
    super.message = 'artifact id conflict',
  ]);
}
