/// Registered experiments — catalog only; none run until remote config activates.
library;

import 'experiment_definition.dart';

abstract final class ProductExperiments {
  ProductExperiments._();

  /// Example only: coffee primary CTA copy (`control` vs `open_cup`).
  static const coffeeCtaCopy = ExperimentDefinition(
    id: 'coffee_cta_copy',
    variants: ['control', 'open_cup'],
    defaultVariant: 'control',
    version: 1,
  );

  static const catalog = <ExperimentDefinition>[
    coffeeCtaCopy,
  ];

  static ExperimentDefinition? definitionFor(String id) {
    for (final experiment in catalog) {
      if (experiment.id == id) return experiment;
    }
    return null;
  }
}
