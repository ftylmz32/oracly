/// OR-1160 — Domain template catalogues aggregated for registry bootstrap.
library;

import '../../formatters/output_format_catalogue.dart';
import '../../models/prompt_template.dart';
import '../../models/prompt_variable.dart';
import '../sections/shared_sections.dart';

abstract final class PromptTemplateCatalogue {
  PromptTemplateCatalogue._();

  static List<PromptTemplate> bootstrap() => [
        tarotReading,
        dreamAnalysis,
        astrologyReading,
        dailyEnergyBrief,
        compatibilityReport,
        numerologyReading,
      ];

  static final tarotReading = PromptTemplate(
    id: 'tarot.reading',
    version: '1.0.0',
    domain: 'tarot',
    systemBody: '''
{{> base_persona}}
{{> personality_block}}
{{@locale.role}}

{{> output_format_block}}
''',
    userBody: '''
Açılım: {{spreadType}}
Niyet: {{intention}}
Kartlar:
{{cardsSummary}}
{{#if reversedSummary}}
Ters kartlar: {{reversedSummary}}
{{/if}}
''',
    sections: {
      'base_persona': SharedTemplateSections.basePersona,
      'personality_block': SharedTemplateSections.personalityBlock,
      'output_format_block': SharedTemplateSections.outputFormatBlock,
    },
    localizations: {
      'tr': {
        'role': 'Tarot uzmanısın. Kart sembolizmini derinlemesine yorumla.',
      },
      'en': {
        'role': 'You are a tarot expert. Interpret card symbolism in depth.',
      },
    },
    variables: [
      const PromptVariable(key: 'spreadType', type: PromptVariableType.string),
      const PromptVariable(key: 'intention', type: PromptVariableType.string),
      const PromptVariable(
        key: 'cardsSummary',
        type: PromptVariableType.string,
        required: true,
      ),
      const PromptVariable(
        key: 'reversedSummary',
        type: PromptVariableType.string,
        required: false,
      ),
    ],
    outputFormatId: 'tarot',
    expectedOutputTokens: 1200,
  );

  static final dreamAnalysis = PromptTemplate(
    id: 'dream.analysis',
    version: '1.0.0',
    domain: 'dream',
    systemBody: '''
{{> base_persona}}
{{> personality_block}}
{{@locale.role}}
{{> output_format_block}}
''',
    userBody: '''
Rüya metni:
{{dreamText}}

{{#if emotions}}
Duygular: {{emotions}}
{{/if}}

{{#if symbols}}
Semboller: {{symbols}}
{{/if}}
''',
    sections: {
      'base_persona': SharedTemplateSections.basePersona,
      'personality_block': SharedTemplateSections.personalityBlock,
      'output_format_block': SharedTemplateSections.outputFormatBlock,
    },
    localizations: {
      'tr': {
        'role': 'Rüya analisti olarak sembolik dil yorumluyorsun.',
      },
    },
    variables: [
      const PromptVariable(
        key: 'dreamText',
        type: PromptVariableType.string,
        maxLength: 4000,
      ),
      const PromptVariable(
        key: 'emotions',
        type: PromptVariableType.list,
        required: false,
      ),
      const PromptVariable(
        key: 'symbols',
        type: PromptVariableType.list,
        required: false,
      ),
    ],
    outputFormatId: 'dream',
    expectedOutputTokens: 1000,
  );

  static final astrologyReading = PromptTemplate(
    id: 'astrology.reading',
    version: '1.0.0',
    domain: 'astrology',
    systemBody: '''
{{> base_persona}}
{{> personality_block}}
{{@locale.role}}
{{> output_format_block}}
''',
    userBody: '''
Burç: {{zodiacSign}}
Soru: {{question}}
{{#if birthDate}}Doğum tarihi: {{birthDate}}{{/if}}
{{#if birthTime}}Doğum saati: {{birthTime}}{{/if}}
{{#if birthPlace}}Doğum yeri: {{birthPlace}}{{/if}}
''',
    sections: {
      'base_persona': SharedTemplateSections.basePersona,
      'personality_block': SharedTemplateSections.personalityBlock,
      'output_format_block': SharedTemplateSections.outputFormatBlock,
    },
    localizations: {
      'tr': {
        'role': 'Astroloji rehberi olarak danışmanlık veriyorsun.',
      },
    },
    variables: [
      const PromptVariable(key: 'zodiacSign', type: PromptVariableType.string),
      const PromptVariable(key: 'question', type: PromptVariableType.string),
      const PromptVariable(
        key: 'birthDate',
        type: PromptVariableType.string,
        required: false,
      ),
      const PromptVariable(
        key: 'birthTime',
        type: PromptVariableType.string,
        required: false,
      ),
      const PromptVariable(
        key: 'birthPlace',
        type: PromptVariableType.string,
        required: false,
      ),
    ],
    outputFormatId: 'standard',
  );

  static final dailyEnergyBrief = PromptTemplate(
    id: 'daily_energy.brief',
    version: '1.0.0',
    domain: 'daily_energy',
    systemBody: '''
{{> base_persona}}
{{> personality_block}}
{{@locale.role}}
{{> output_format_block}}
''',
    userBody: '''
Tarih: {{date}}
Enerji seviyesi: {{energyLevel}}%
Ruh hali: {{moodLabel}}
{{#if zodiacSign}}Burç: {{zodiacSign}}{{/if}}
{{#if focusArea}}Odak alanı: {{focusArea}}{{/if}}
''',
    sections: {
      'base_persona': SharedTemplateSections.basePersona,
      'personality_block': SharedTemplateSections.personalityBlock,
      'output_format_block': SharedTemplateSections.outputFormatBlock,
    },
    localizations: {
      'tr': {
        'role': 'Günlük kozmik enerji rehberi olarak kısa rehberlik ver.',
      },
    },
    variables: [
      const PromptVariable(key: 'date', type: PromptVariableType.string),
      const PromptVariable(key: 'energyLevel', type: PromptVariableType.number),
      const PromptVariable(key: 'moodLabel', type: PromptVariableType.string),
      const PromptVariable(
        key: 'zodiacSign',
        type: PromptVariableType.string,
        required: false,
      ),
      const PromptVariable(
        key: 'focusArea',
        type: PromptVariableType.string,
        required: false,
      ),
    ],
    outputFormatId: 'standard',
    expectedOutputTokens: 600,
  );

  static final compatibilityReport = PromptTemplate(
    id: 'compatibility.report',
    version: '1.0.0',
    domain: 'compatibility',
    systemBody: '''
{{> base_persona}}
{{> personality_block}}
{{@locale.role}}
{{> output_format_block}}
''',
    userBody: '''
Kişi A: {{subjectA}}
Kişi B: {{subjectB}}
{{#if chartSummary}}
Harita özeti: {{chartSummary}}
{{/if}}
''',
    sections: {
      'base_persona': SharedTemplateSections.basePersona,
      'personality_block': SharedTemplateSections.personalityBlock,
      'output_format_block': SharedTemplateSections.outputFormatBlock,
    },
    localizations: {
      'tr': {
        'role': 'Astrolojik uyum analisti olarak ilişki dinamiklerini yorumluyorsun.',
      },
    },
    variables: [
      const PromptVariable(key: 'subjectA', type: PromptVariableType.string),
      const PromptVariable(key: 'subjectB', type: PromptVariableType.string),
      const PromptVariable(
        key: 'chartSummary',
        type: PromptVariableType.string,
        required: false,
      ),
    ],
    outputFormatId: 'standard',
    expectedOutputTokens: 1000,
  );

  static final numerologyReading = PromptTemplate(
    id: 'numerology.reading',
    version: '1.0.0',
    domain: 'numerology',
    systemBody: '''
{{> base_persona}}
{{> personality_block}}
{{@locale.role}}
{{> output_format_block}}
''',
    userBody: '''
Doğum tarihi: {{birthDate}}
{{#if fullName}}Tam ad: {{fullName}}{{/if}}
Yaşam yolu sayısı: {{lifePathNumber}}
{{#if nameNumber}}İsim sayısı: {{nameNumber}}{{/if}}
''',
    sections: {
      'base_persona': SharedTemplateSections.basePersona,
      'personality_block': SharedTemplateSections.personalityBlock,
      'output_format_block': SharedTemplateSections.outputFormatBlock,
    },
    localizations: {
      'tr': {
        'role': 'Numeroloji rehberi olarak sayısal enerjileri yorumluyorsun.',
      },
    },
    variables: [
      const PromptVariable(key: 'birthDate', type: PromptVariableType.string),
      const PromptVariable(
        key: 'fullName',
        type: PromptVariableType.string,
        required: false,
      ),
      const PromptVariable(
        key: 'lifePathNumber',
        type: PromptVariableType.number,
      ),
      const PromptVariable(
        key: 'nameNumber',
        type: PromptVariableType.number,
        required: false,
      ),
    ],
    outputFormatId: 'standard',
  );

  static String outputInstructionFor(String? formatId) {
    final schema = formatId == null
        ? OutputFormatCatalogue.standard
        : OutputFormatCatalogue.byId(formatId) ?? OutputFormatCatalogue.standard;
    return schema.instructionTemplate;
  }
}
