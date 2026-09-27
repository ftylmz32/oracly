/// Dream Phase 4B — backend premium golden fixtures, read verbatim from the
/// backend test tree so client and backend judge the same synthetic prose.
library;

import 'dart:convert';
import 'dart:io';

import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/openai/dream_analysis_parser.dart';

class DreamGolden {
  const DreamGolden(this.id, this.language, this.narrative, this.data);

  final String id;
  final String language;
  final String narrative;
  final Map<String, dynamic> data;

  /// Parsed exactly as a live provider body is parsed.
  DreamAiAnalysis get analysis => DreamAnalysisParser.fromMap(data)!;

  DreamAiAnalysis withField(String key, Object value) =>
      DreamAnalysisParser.fromMap({...data, key: value})!;
}

List<DreamGolden> loadDreamGoldens() {
  final raw = File('backend/tests/fixtures/dream-premium-golden.json')
      .readAsStringSync();
  return [
    for (final item in jsonDecode(raw) as List<dynamic>)
      DreamGolden(
        item['id'] as String,
        item['language'] as String,
        item['narrative'] as String,
        Map<String, dynamic>.from(item['data'] as Map),
      ),
  ];
}

DreamGolden dreamGolden(String id) =>
    loadDreamGoldens().firstWhere((g) => g.id == id);
