/// Phase 5C — immutable SignatureGeometryDescriptor (no UI coordinates).
library;

import 'signature_spread_enums.dart';

class SignatureGeometryDescriptor {
  const SignatureGeometryDescriptor({
    required this.hook,
    required this.slotCount,
    required this.decisionBranching,
  });

  final SignatureGeometryHook hook;
  final int slotCount;
  final bool decisionBranching;
}

abstract final class SignatureGeometryDescriptors {
  SignatureGeometryDescriptors._();

  static const single = SignatureGeometryDescriptor(
    hook: SignatureGeometryHook.single,
    slotCount: 1,
    decisionBranching: false,
  );

  static const threeLinear = SignatureGeometryDescriptor(
    hook: SignatureGeometryHook.threeLinear,
    slotCount: 3,
    decisionBranching: false,
  );

  static const fiveLinear = SignatureGeometryDescriptor(
    hook: SignatureGeometryHook.fiveLinear,
    slotCount: 5,
    decisionBranching: false,
  );

  static const fiveDecision = SignatureGeometryDescriptor(
    hook: SignatureGeometryHook.fiveDecision,
    slotCount: 5,
    decisionBranching: true,
  );

  static const List<SignatureGeometryDescriptor> all = [
    single,
    threeLinear,
    fiveLinear,
    fiveDecision,
  ];

  static SignatureGeometryDescriptor byHook(SignatureGeometryHook hook) {
    return switch (hook) {
      SignatureGeometryHook.single => single,
      SignatureGeometryHook.threeLinear => threeLinear,
      SignatureGeometryHook.fiveLinear => fiveLinear,
      SignatureGeometryHook.fiveDecision => fiveDecision,
    };
  }
}
