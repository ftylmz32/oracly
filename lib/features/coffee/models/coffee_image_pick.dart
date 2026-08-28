/// A locally selected coffee-cup image.
library;

class CoffeeImagePick {
  const CoffeeImagePick({
    required this.path,
    this.mimeType,
  });

  final String path;
  final String? mimeType;
}
