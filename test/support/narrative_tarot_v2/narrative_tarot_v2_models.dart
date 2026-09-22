/// Phase 2 CONTRACT HARNESS models — NOT production NarrativeQualityValidator.
library;

class Ntv2Corpus {
  Ntv2Corpus({
    required this.corpusId,
    required this.scenarioCount,
    required this.scenarios,
    this.legacyCorpusNote,
  });

  final String corpusId;
  final int scenarioCount;
  final String? legacyCorpusNote;
  final List<Ntv2Scenario> scenarios;

  factory Ntv2Corpus.fromJson(Map<String, dynamic> json) {
    final list = (json['scenarios'] as List<dynamic>)
        .map((e) => Ntv2Scenario.fromJson(e as Map<String, dynamic>))
        .toList();
    return Ntv2Corpus(
      corpusId: json['corpusId'] as String,
      scenarioCount: json['scenarioCount'] as int,
      legacyCorpusNote: json['legacyCorpusNote'] as String?,
      scenarios: list,
    );
  }
}

class Ntv2Scenario {
  Ntv2Scenario({
    required this.id,
    required this.locale,
    required this.tags,
    required this.category,
    required this.input,
    required this.candidate,
    required this.expected,
  });

  final String id;
  final String locale;
  final List<String> tags;
  final String category;
  final Map<String, dynamic> input;
  final Map<String, dynamic> candidate;
  final Ntv2Expected expected;

  factory Ntv2Scenario.fromJson(Map<String, dynamic> json) {
    return Ntv2Scenario(
      id: json['id'] as String,
      locale: json['locale'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      category: json['category'] as String,
      input: Map<String, dynamic>.from(json['input'] as Map),
      candidate: Map<String, dynamic>.from(json['candidate'] as Map),
      expected: Ntv2Expected.fromJson(json['expected'] as Map<String, dynamic>),
    );
  }
}

class Ntv2Expected {
  Ntv2Expected({
    required this.pass,
    required this.hardFailures,
    required this.flags,
    required this.notes,
  });

  final bool pass;
  final List<String> hardFailures;
  final Map<String, dynamic> flags;
  final String notes;

  factory Ntv2Expected.fromJson(Map<String, dynamic> json) {
    return Ntv2Expected(
      pass: json['pass'] as bool,
      hardFailures: (json['hardFailures'] as List<dynamic>).cast<String>(),
      flags: Map<String, dynamic>.from(json['flags'] as Map),
      notes: json['notes'] as String? ?? '',
    );
  }
}
