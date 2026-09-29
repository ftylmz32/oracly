part of 'user_local_data_isolation.dart';

/// One gate shared by account-switch transitions and profile rename.
/// The next body starts only after the active body has finished, including
/// a storage future that was started and has not mutated yet.
bool _ownerMutationActive = false;
int _queuedOwnerMutations = 0;
final List<void Function()> _ownerMutationWaiters = <void Function()>[];

Future<T> _executeOwnerScopedMutation<T>(Future<T> Function() body) {
  final result = Completer<T>();

  void start() {
    _ownerMutationActive = true;
    scheduleMicrotask(() async {
      try {
        result.complete(await body());
      } catch (error, stackTrace) {
        if (!result.isCompleted) result.completeError(error, stackTrace);
      } finally {
        _ownerMutationActive = false;
        if (_ownerMutationWaiters.isNotEmpty) {
          _ownerMutationWaiters.removeAt(0)();
        }
      }
    });
  }

  if (_ownerMutationActive) {
    _queuedOwnerMutations++;
    _ownerMutationWaiters.add(() {
      _queuedOwnerMutations--;
      start();
    });
  } else {
    start();
  }
  return result.future;
}
