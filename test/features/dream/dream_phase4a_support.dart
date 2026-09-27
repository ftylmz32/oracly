/// Dream Phase 4A — saved-dream builders for history tests.
library;

import 'package:oracly_new/core/domain/repositories/dream_repository.dart';
import 'package:oracly_new/features/dream/data/dream_record_mapper.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_emotion.dart';
import 'package:oracly_new/features/dream/models/dream_entry_selection.dart';
import 'package:oracly_new/features/dream/services/dream_understanding_service.dart';

const doorTr = 'Rüyamda eski bir kapı aralanıyordu ve içeri serin bir rüzgâr doldu.';
const doorTr2 = 'Rüyamda sessiz bir koridorun sonunda kapı duruyordu.';
const doorTr3 = 'Rüyamda kapının önünde uzun süre bekledim, ses yoktu.';
const doorEn = 'I dreamt of a narrow door at the end of a quiet hallway.';
const gardenTr = 'Rüyamda sessiz bir bahçede yürüdüm, çiçekler açmıştı.';
const catSeaTr = 'Rüyamda bir kedi denizin kıyısında oturuyordu.';

/// An analyzed saved Dream — understanding built exactly as the service
/// builds it, in [language].
Dream savedDream(
  String id,
  String narrative,
  DateTime at, {
  String language = 'tr',
  List<DreamEmotionId> emotions = const [],
  DreamEntrySelection? entry,
  List<String> tags = const [],
}) {
  final selected = [for (final e in emotions) DreamEmotion(id: e)];
  return Dream(
    id: id,
    narrative: narrative,
    recordedAt: at,
    tags: tags,
    entry: entry,
    selectedEmotions: selected,
    understanding: DreamUnderstandingService().build(
      narrative: narrative,
      selectedEmotions: selected,
      language: language,
    ),
  );
}

Future<void> seed(DreamRepository repo, List<Dream> dreams) async {
  for (final dream in dreams) {
    await repo.save(DreamRecordMapper.toRecord(dream));
  }
}

DateTime day(int d) => DateTime(2026, 9, d, 8);
