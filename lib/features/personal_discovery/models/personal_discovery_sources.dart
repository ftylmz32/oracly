/// Inputs already persisted elsewhere. No parallel store.
library;

import '../../../core/domain/models/conversation_record.dart';
import '../../../core/domain/models/dream_record.dart';
import '../../../core/domain/models/reading.dart';
import '../../../core/domain/models/astrology_record.dart';
import '../../../core/domain/models/birth_chart_record.dart';
import '../../birth_chart/models/birth_profile.dart';
import '../../coffee/models/coffee_reading.dart';
import '../../daily_message/models/daily_message.dart';
import '../../palm/models/palm_reading.dart';
import '../../premium/models/personalization_models.dart';

class PersonalDiscoverySources {
  const PersonalDiscoverySources({
    this.birth,
    this.settings,
    this.readings = const [],
    this.dreams = const [],
    this.coffee = const [],
    this.conversations = const [],
    this.astrology = const [],
    this.dailyMessages = const [],
    this.starChart,
    this.soulmateGenerationCount = 0,
    this.palm = const [],
  });

  final BirthProfile? birth;
  final PersonalizationSettings? settings;
  final List<ReadingModel> readings;
  final List<DreamRecord> dreams;
  final List<CoffeeReading> coffee;
  final List<ConversationRecord> conversations;
  final List<AstrologyRecord> astrology;
  final List<DailyMessage> dailyMessages;
  final BirthChartRecord? starChart;
  final int soulmateGenerationCount;
  final List<PalmReading> palm;
}
