/// Phase 4 — typed natal calculation failures (no fake full chart).
library;

sealed class NatalCalculationException implements Exception {
  const NatalCalculationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NatalTimezoneMissingException extends NatalCalculationException {
  const NatalTimezoneMissingException() : super('timezone_missing');
}

class NatalTimezoneInvalidException extends NatalCalculationException {
  const NatalTimezoneInvalidException(String id)
      : super('timezone_invalid:$id');
}

class NatalDateUnsupportedException extends NatalCalculationException {
  const NatalDateUnsupportedException() : super('date_unsupported');
}

class NatalNonexistentLocalTimeException extends NatalCalculationException {
  const NatalNonexistentLocalTimeException() : super('nonexistent_local_time');
}

class NatalEphemerisFailureException extends NatalCalculationException {
  const NatalEphemerisFailureException([super.message = 'ephemeris_failure']);
}
