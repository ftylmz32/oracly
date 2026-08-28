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
{{@locale.spread_label}}: {{spreadType}}
{{@locale.intention_label}}: {{intention}}
{{@locale.cards_label}}:
{{cardsSummary}}
{{#if reversedSummary}}
{{@locale.reversed_label}}: {{reversedSummary}}
{{/if}}
''',
    sections: {
      'base_persona': '{{personaBody}}',
      'personality_block': '''
{{#if personality}}
{{@locale.personality_label}}: {{personality}}
{{/if}}
''',
      'output_format_block': '''
{{#if outputFormatInstruction}}
{{@locale.format_label}}:
{{outputFormatInstruction}}
{{/if}}
''',
    },
    localizations: {
      'tr': {
        'role': 'Karşında oturan okuyucusun. Kart sözlüğü okuma; soruyu ve kartların birbirine değdiği yeri yorumla.',
        'spread_label': 'Açılım',
        'intention_label': 'Niyet',
        'cards_label': 'Kartlar',
        'reversed_label': 'Ters kartlar',
        'personality_label': 'Kişilik tonu',
        'format_label': 'Yanıt formatı',
      },
      'en': {
        'role': 'You are a reader sitting across from someone. Do not recite a card dictionary; interpret the question and how the cards touch.',
        'spread_label': 'Spread',
        'intention_label': 'Intention',
        'cards_label': 'Cards',
        'reversed_label': 'Reversed cards',
        'personality_label': 'Tone',
        'format_label': 'Response format',
      },
      'ru': {
        'role': 'Ты читатель напротив человека. Не читай словарь карт; толкуй вопрос и то, как карты соприкасаются.',
        'spread_label': 'Расклад',
        'intention_label': 'Намерение',
        'cards_label': 'Карты',
        'reversed_label': 'Перевернутые карты',
        'personality_label': 'Тон',
        'format_label': 'Формат ответа',
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
        'role':
            'Astroloji rehberi olarak net gözlem ver. '
            'Önce anlaşılır bir yorum yaz; soruyla bitirme. '
            'Kullanıcıya işi bırakma, kehanet de etme.',
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
    outputFormatId: 'astrology',
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
        'role': 'Günün temposunu sakin ve somut gözlemle kısa anlat.',
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
        'role': 'Numerolojiyi sembolik bir ayna olarak sakin anlat; sayısal enerji nutku yok.',
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
