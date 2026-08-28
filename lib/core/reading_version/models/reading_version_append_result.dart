/// Outcome of a reinterpret attempt.

library;



import 'reading_version_group.dart';



class ReadingVersionAppendResult {

  const ReadingVersionAppendResult({

    required this.added,

    required this.group,

  });



  final bool added;

  final ReadingVersionGroup group;

}


