/// Testable seam around "read this one file's bytes" — lets tests prove
/// sequential, one-slot-at-a-time byte ownership during staging without
/// asserting on device memory.
library;

import 'dart:io';

abstract class CoffeeV2ByteLoader {
  Future<List<int>> loadBytes(String path);
}

class FileCoffeeV2ByteLoader implements CoffeeV2ByteLoader {
  const FileCoffeeV2ByteLoader();

  @override
  Future<List<int>> loadBytes(String path) => File(path).readAsBytes();
}
