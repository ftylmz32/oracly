/// Public reading-operation states. Wait finished is not a status.
library;

enum ReadingOperationStatus {
  waiting,
  processing,
  ready,
  failed,
}

enum ReadingType {
  coffee,
  palm,
  soulmate,
}

ReadingOperationStatus? readingOperationStatusFromWire(String? value) {
  return switch (value) {
    'waiting' => ReadingOperationStatus.waiting,
    'processing' => ReadingOperationStatus.processing,
    'ready' => ReadingOperationStatus.ready,
    'failed' => ReadingOperationStatus.failed,
    _ => null,
  };
}

ReadingType? readingTypeFromWire(String? value) {
  return switch (value) {
    'coffee' => ReadingType.coffee,
    'palm' => ReadingType.palm,
    'soulmate' => ReadingType.soulmate,
    _ => null,
  };
}

String readingTypeWire(ReadingType type) {
  return switch (type) {
    ReadingType.coffee => 'coffee',
    ReadingType.palm => 'palm',
    ReadingType.soulmate => 'soulmate',
  };
}
