/// Which palm the user photographed.
library;

enum PalmHand {
  right,
  left;

  String get label => this == PalmHand.right ? 'Sağ el' : 'Sol el';
}
