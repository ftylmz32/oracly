/// Phase 2 — load canonical Narrative Tarot V2 corpus (offline).
library;

import 'dart:convert';
import 'dart:io';

import 'narrative_tarot_v2_models.dart';

abstract final class Ntv2CorpusLoader {
  static const relativePath = 'test/fixtures/narrative_tarot_v2_corpus.json';

  static Ntv2Corpus load() {
    final file = File(relativePath);
    if (!file.existsSync()) {
      throw StateError('Missing canonical corpus at $relativePath');
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return Ntv2Corpus.fromJson(json);
  }
}
