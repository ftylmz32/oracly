class SpiritPulse {
  const SpiritPulse({
    required this.energy,
    required this.aura,
    required this.intuition,
    required this.luck,
    required this.mood,
    required this.message,
  });

  final int energy;
  final String aura;
  final String intuition;
  final String luck;
  final String mood;
  final String message;
}

class SpiritPulseService {
  const SpiritPulseService();

  SpiritPulse getTodayPulse() {
    return const SpiritPulse(
      energy: 72,
      aura: 'Dengeli',
      intuition: 'Yüksek',
      luck: 'Açık',
      mood: 'Sakin',
      message:
          'Bugün iç sesine kulak vermek için uygun bir gün. Küçük adımlar büyük netlik getirebilir.',
    );
  }
}
