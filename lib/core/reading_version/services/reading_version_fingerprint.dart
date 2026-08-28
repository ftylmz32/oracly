/// Detects meaningful differences between interpretation snapshots.

library;



import '../models/reading_version_kind.dart';



abstract final class ReadingVersionFingerprint {

  ReadingVersionFingerprint._();



  static String of(Map<String, dynamic> data, ReadingVersionKind kind) {

    final text = switch (kind) {

      ReadingVersionKind.tarot => '${data['summary'] ?? ''}',

      ReadingVersionKind.coffee => [

          data['overall'],

          data['love'],

          data['career'],

          data['money'],

          data['nearFuture'],

          data['takeaway'],

        ].join('\n'),

      ReadingVersionKind.palm => [

          data['overall'],

          data['lifeLine'],

          data['headLine'],

          data['heartLine'],

          data['fateLine'],

        ].join('\n'),

      ReadingVersionKind.dream => '${data['analysis'] ?? ''}',

    };

    return _normalize(text);

  }



  static bool isMeaningful(String previous, String next) =>

      _normalize(previous) != _normalize(next);



  static String _normalize(String raw) =>

      raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

}


