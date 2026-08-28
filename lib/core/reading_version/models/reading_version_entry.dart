/// One stored interpretation snapshot — never overwrites siblings.

library;



class ReadingVersionEntry {

  const ReadingVersionEntry({

    required this.number,

    required this.at,

    required this.fingerprint,

    required this.data,

  });



  final int number;

  final DateTime at;

  final String fingerprint;

  final Map<String, dynamic> data;



  bool get isOriginal => number <= 1;



  Map<String, dynamic> toJson() => {

        'number': number,

        'at': at.toIso8601String(),

        'fingerprint': fingerprint,

        'data': data,

      };



  factory ReadingVersionEntry.fromJson(Map<String, dynamic> json) {

    return ReadingVersionEntry(

      number: json['number'] as int? ?? 1,

      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),

      fingerprint: json['fingerprint'] as String? ?? '',

      data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),

    );

  }

}


