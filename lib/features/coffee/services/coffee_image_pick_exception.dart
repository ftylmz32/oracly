/// Typed camera / gallery failure — never a silent null.
library;

class CoffeeImagePickException implements Exception {
  const CoffeeImagePickException(this.message);

  final String message;
}
