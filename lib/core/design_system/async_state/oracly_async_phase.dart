/// Global async phases — one visual universe, five calm states.
library;

enum OraclyAsyncPhase {
  loading,
  empty,
  error,
  offline,
  retry,
}
