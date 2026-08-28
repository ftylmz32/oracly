/// One product experiment — inactive until explicitly configured remotely.
library;

class ExperimentDefinition {
  const ExperimentDefinition({
    required this.id,
    required this.variants,
    required this.defaultVariant,
    required this.version,
  });

  final String id;
  final List<String> variants;
  final String defaultVariant;
  final int version;

  List<String> get assignmentVariants => variants;

  bool isValidVariant(String value) => variants.contains(value);
}
