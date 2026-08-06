/// OR-1140 — Numerology reduction calculator.
library;

abstract class NumerologyCalculator {
  int lifePathNumber(DateTime birthDate);
  int nameNumber(String name);
  int reduce(int value);
}

class PythagoreanNumerologyCalculator implements NumerologyCalculator {
  @override
  int lifePathNumber(DateTime birthDate) {
    final raw = birthDate.day + birthDate.month + birthDate.year;
    return reduce(raw);
  }

  @override
  int nameNumber(String name) {
    final sum = name.toUpperCase().runes.fold<int>(0, (total, code) {
      final letter = String.fromCharCode(code);
      return total + (_letterValue[letter] ?? 0);
    });
    return reduce(sum);
  }

  @override
  int reduce(int value) {
    var current = value;
    while (current > 9 && current != 11 && current != 22 && current != 33) {
      current = current
          .toString()
          .split('')
          .map(int.parse)
          .fold(0, (a, b) => a + b);
    }
    return current;
  }

  static const _letterValue = {
    'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'F': 6, 'G': 7, 'H': 8, 'I': 9,
    'J': 1, 'K': 2, 'L': 3, 'M': 4, 'N': 5, 'O': 6, 'P': 7, 'Q': 8, 'R': 9,
    'S': 1, 'T': 2, 'U': 3, 'V': 4, 'W': 5, 'X': 6, 'Y': 7, 'Z': 8,
    'Ç': 3, 'Ğ': 7, 'İ': 9, 'Ö': 6, 'Ş': 1, 'Ü': 3,
  };
}
