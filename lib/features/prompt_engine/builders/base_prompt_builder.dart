/// OR-1160 — Base builder with template rendering and validation.
library;

import '../core/prompt_builder_contract.dart';
import '../formatters/output_format_catalogue.dart';
import '../models/prompt_context.dart';
import '../models/prompt_metadata.dart';
import '../models/prompt_request.dart';
import '../models/prompt_template.dart';
import '../templates/template_engine.dart';
import '../templates/template_registry.dart';
import '../validators/prompt_validation.dart';
import '../validators/prompt_validator.dart';
import '../../tarot/interpretation/services/tarot_prompt_locale.dart';
import '../formatters/output_format_locale.dart';

abstract class BasePromptBuilder<TInput> implements PromptBuilderContract<TInput> {
  BasePromptBuilder({
    required this.registry,
    required this.engine,
    required this.validator,
    this.templateVersion,
  });

  final TemplateRegistry registry;
  final TemplateEngine engine;
  final PromptValidatorPipeline validator;
  final String? templateVersion;

  @override
  PromptRequest build({
    required TInput input,
    required PromptContext context,
  }) {
    final template = registry.resolve(
      id: templateId,
      version: templateVersion,
      locale: context.locale,
    );

    final inputVariables = mapInputToVariables(input);
    final variables = _mergeVariables(context, inputVariables, template);

    final systemResult = engine.renderSystem(template, variables, context.locale);
    final userResult = engine.renderUser(template, variables, context.locale);

    final validation = validator.validate(
      PromptValidationContext(
        template: template,
        variables: variables,
        systemText: systemResult.text,
        userText: userResult.text,
      ),
    );

    if (!validation.isValid) {
      throw PromptValidationException(validation);
    }

    final metadata = PromptMetadata(
      templateId: template.id,
      templateVersion: template.version,
      domain: domain.id,
      createdAt: DateTime.now(),
      builderId: builderId,
      tags: {'locale': context.locale},
    );

    return PromptRequest(
      system: systemResult.text,
      user: userResult.text,
      context: context,
      metadata: metadata,
      resolvedVariables: variables,
    );
  }

  Map<String, dynamic> mapInputToVariables(TInput input);

  Map<String, dynamic> _mergeVariables(
    PromptContext context,
    Map<String, dynamic> inputVariables,
    PromptTemplate template,
  ) {
    final outputSchema = template.outputFormatId == null
        ? OutputFormatCatalogue.standard
        : OutputFormatCatalogue.byId(template.outputFormatId!) ??
            OutputFormatCatalogue.standard;

    final tarot = template.id == 'tarot.reading';
    return {
      ...context.toVariableMap(),
      ...inputVariables,
      'outputFormatInstruction': tarot
          ? TarotPromptLocale.format(context.locale)
          : OutputFormatLocale.instruction(
              outputSchema.id,
              context.locale,
            ),
      if (tarot) 'personaBody': TarotPromptLocale.persona(context.locale),
    };
  }
}
