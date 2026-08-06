/// OR-1130 — Conflict resolution strategies for sync.
library;

enum ConflictResolutionStrategy {
  serverWins,
  clientWins,
  latestTimestamp,
  merge,
}

abstract class ConflictResolver {
  Map<String, dynamic> resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
    ConflictResolutionStrategy strategy,
  });
}

class TimestampConflictResolver implements ConflictResolver {
  @override
  Map<String, dynamic> resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.latestTimestamp,
  }) {
    return switch (strategy) {
      ConflictResolutionStrategy.serverWins => remote,
      ConflictResolutionStrategy.clientWins => local,
      ConflictResolutionStrategy.latestTimestamp => _latest(local, remote),
      ConflictResolutionStrategy.merge => {...remote, ...local},
    };
  }

  Map<String, dynamic> _latest(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final localTs = DateTime.tryParse(local['updatedAt']?.toString() ?? '');
    final remoteTs = DateTime.tryParse(remote['updatedAt']?.toString() ?? '');
    if (localTs == null) return remote;
    if (remoteTs == null) return local;
    return localTs.isAfter(remoteTs) ? local : remote;
  }
}
