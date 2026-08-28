/// Version chain for one persisted reading — journal uses [rootId] once.

library;



import 'reading_version_entry.dart';

import 'reading_version_kind.dart';



class ReadingVersionGroup {

  const ReadingVersionGroup({

    required this.rootId,

    required this.kind,

    required this.entries,

    this.activeNumber = 1,

  });



  final String rootId;

  final ReadingVersionKind kind;

  final List<ReadingVersionEntry> entries;

  final int activeNumber;



  ReadingVersionEntry? entryFor(int number) {

    for (final item in entries) {

      if (item.number == number) return item;

    }

    return null;

  }



  ReadingVersionEntry? get activeEntry => entryFor(activeNumber);

  ReadingVersionEntry? get originalEntry => entryFor(1);

  bool get hasRevisions => entries.length > 1;

  bool get viewingLatest => activeNumber == entries.last.number;



  Map<String, dynamic> toJson() => {

        'rootId': rootId,

        'kind': kind.name,

        'activeNumber': activeNumber,

        'entries': entries.map((e) => e.toJson()).toList(),

      };



  factory ReadingVersionGroup.fromJson(Map<String, dynamic> json) {

    return ReadingVersionGroup(

      rootId: json['rootId'] as String? ?? '',

      kind: ReadingVersionKind.values.byName('${json['kind']}'),

      activeNumber: json['activeNumber'] as int? ?? 1,

      entries: (json['entries'] as List<dynamic>? ?? [])

          .map((e) => ReadingVersionEntry.fromJson(e as Map<String, dynamic>))

          .toList(),

    );

  }



  ReadingVersionGroup copyWith({

    List<ReadingVersionEntry>? entries,

    int? activeNumber,

  }) {

    return ReadingVersionGroup(

      rootId: rootId,

      kind: kind,

      entries: entries ?? this.entries,

      activeNumber: activeNumber ?? this.activeNumber,

    );

  }

}


