/// Versioned Coffee result contracts (server `coffeeResultContract`).
///
/// Absent / null = the legacy Coffee result, handled exactly as before.
/// `m2_public_v1` = the frozen V3 interpretation result: its `overall` is the
/// server's authoritative, already-gated reading and is stored and shown
/// VERBATIM (no legacy parser, composer, scrub or length rule). Any other
/// non-null value is unknown and fails closed — it is never reinterpreted as
/// a legacy reading. Only this explicit marker selects the behavior.
/// `v3_narrative_v1` = the versioned V3 narrative successor: same public
/// shape and the same verbatim treatment (its `overall` may contain
/// paragraphs separated by a blank line).
library;

const String coffeeM2PublicV1ResultContract = 'm2_public_v1';
const String coffeeV3NarrativeV1ResultContract = 'v3_narrative_v1';

/// Server-gated V3 results: `overall` is authoritative and shown verbatim.
const Set<String> serverGatedCoffeeResultContracts = {
  coffeeM2PublicV1ResultContract,
  coffeeV3NarrativeV1ResultContract,
};

const Set<String> knownCoffeeResultContracts = serverGatedCoffeeResultContracts;

/// null → null (legacy); a known value → that value; anything else throws.
String? parseCoffeeResultContract(Object? raw) {
  if (raw == null) return null;
  if (raw is String && knownCoffeeResultContracts.contains(raw)) return raw;
  throw const FormatException('unsupported_coffee_result_contract');
}
