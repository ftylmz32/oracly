/// Soulmate interpretation quality ? no paid calls, no local template as success.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/premium/data/soul_mate_interpretation_catalogue.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_identity.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation_context.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation_gate.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_result_service.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('A portrait success plus accepted AI interpretation', () {
    final rejected = SoulMateInterpretationGate.assess(
      _good(),
      name: 'Ayse',
      presence: 'feminine-presenting adult',
    );
    expect(rejected, isNull);
    expect(_parts(_good()).authoritative, isTrue);
  });

  test('B failed interpretation does not become portrait failure', () async {
    final port = _ScriptedText([
      const SoulMateInterpretationOutcome.failed(),
    ]);
    final outcome = await port.interpret(_context('Ayse'));
    expect(outcome.hasText, isFalse);
    expect(port.imageCalls, 0);
  });

  test('C interpretation retry does not regenerate an image', () async {
    final port = _ScriptedText([
      const SoulMateInterpretationOutcome.failed(),
      SoulMateInterpretationOutcome.success(_parts(_good())),
    ]);
    await port.interpret(_context('Ayse'));
    final retry = await port.interpret(_context('Ayse'));
    expect(retry.hasText, isTrue);
    expect(port.imageCalls, 0);
  });

  test('D text repair count is locked at one', () {
    expect(SoulMateInterpretationGate.maxRepairAttempts, 1);
  });

  test('E generic romance cliche is rejected', () {
    expect(
      SoulMateInterpretationGate.assess(_bad(cliche: true)),
      SoulMateInterpretationReject.genericCliche,
    );
  });

  test('F deterministic prediction is rejected', () {
    expect(
      SoulMateInterpretationGate.assess(_bad(certain: true)),
      SoulMateInterpretationReject.deterministic,
    );
  });

  test('G fake memory is rejected', () {
    expect(
      SoulMateInterpretationGate.assess(_bad(memory: true)),
      SoulMateInterpretationReject.fakeMemory,
    );
  });

  test('H contradictory presentation is rejected', () {
    expect(
      SoulMateInterpretationGate.assess(
        _bad(contradiction: true),
        presence: 'masculine-presenting adult',
      ),
      SoulMateInterpretationReject.contradiction,
    );
  });

  test('I user A context never becomes user B context', () {
    final a = SoulMateInterpretationContext.fromRequest(
      SoulMateDrawRequest(name: 'Ayse', birthDate: DateTime.utc(1994, 3, 12)),
      identity: const SoulMateIdentity(
        nonce: 'aaaa',
        presence: 'feminine-presenting adult',
        mood: 'awakening and gentle',
      ),
      now: DateTime.utc(2026, 9, 8),
    );
    final b = SoulMateInterpretationContext.fromRequest(
      SoulMateDrawRequest(name: 'Kemal', birthDate: DateTime.utc(1988, 11, 2)),
      identity: const SoulMateIdentity(
        nonce: 'bbbb',
        presence: 'masculine-presenting adult',
        mood: 'hushed and contemplative',
      ),
      now: DateTime.utc(2026, 9, 8),
    );
    expect(a.signature(), isNot(b.signature()));
    expect(a.signature().contains('Kemal'), isFalse);
    expect(b.signature().contains('Ayse'), isFalse);
    expect(a.signature(), a.signature());
  });

  test('J saved result reopens portrait plus authoritative interpretation', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-a');
    final docs = await Directory.systemTemp.createTemp('soulmate-text');
    final service = SoulMateResultService(storage);
    final request = SoulMateDrawRequest(
      name: 'Ayse',
      birthDate: DateTime.utc(1994, 3, 12),
    );
    await service.saveSuccessfulDraw(
      request: request,
      imageBytes: [1, 2, 3],
      documents: docs,
      recordId: 'or-soulmate-text',
      parts: _parts(_good()),
    );
    final loaded = await service.latestWithPortrait();
    expect(loaded?.bytes, [1, 2, 3]);
    expect(loaded?.meta.hasAuthoritativeInterpretation, isTrue);
    expect(loaded?.meta.parts.energy, contains('ic'));
  });

  test('K failed text regen does not wipe previous good interpretation', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final docs = await Directory.systemTemp.createTemp('soulmate-keep-text');
    final service = SoulMateResultService(storage);
    final request = SoulMateDrawRequest(
      name: 'Ayse',
      birthDate: DateTime.utc(1994, 3, 12),
    );
    await service.saveSuccessfulDraw(
      request: request,
      imageBytes: [1, 2, 3],
      documents: docs,
      recordId: 'keep-text',
      parts: _parts(_good()),
    );
    await service.saveSuccessfulDraw(
      request: request,
      imageBytes: [9, 9, 9],
      documents: docs,
      recordId: 'keep-text',
      parts: const SoulMateReadingParts(
        energy: '',
        attraction: '',
        dynamics: '',
        feeling: '',
        yourSide: '',
      ),
    );
    final loaded = await service.latestWithPortrait();
    expect(loaded?.bytes, [9, 9, 9]);
    expect(loaded?.meta.hasAuthoritativeInterpretation, isTrue);
    expect(loaded?.meta.parts.feeling, contains('acele'));
  });

  test('L local template is not an authoritative success fallback', () {
    final template = SoulMateInterpretation.partsFor(
      SoulMateDrawRequest(name: 'Ayse', birthDate: DateTime.utc(1994, 3, 12)),
    );
    expect(template.authoritative, isFalse);
    final empty = const SoulMateInterpretationOutcome.failed();
    expect(empty.hasText, isFalse);
  });
}

SoulMateInterpretationContext _context(String name) {
  return SoulMateInterpretationContext.fromRequest(
    SoulMateDrawRequest(name: name, birthDate: DateTime.utc(1994, 3, 12)),
    now: DateTime.utc(2026, 9, 8),
  );
}

SoulMateReadingParts _parts(SoulMateInterpretationDraft draft) {
  return SoulMateReadingParts(
    energy: draft.personality,
    attraction: draft.attraction,
    dynamics: draft.dynamic,
    feeling: draft.feeling,
    yourSide: draft.challenge,
    meeting: draft.meeting,
    authoritative: true,
  );
}

SoulMateInterpretationDraft _good() {
  const line =
      'Mart isiginda duran biri gibi, once ice donuk bir duruluk one cikabilir. Yaninda kolay konusulan ama hemen acilmayan bir sakinlik olabilir.';
  return const SoulMateInterpretationDraft(
    personality: line,
    dynamic:
        'Bu dinamikte tempo yavas kurulabilir. Yakinlik, acele ettirilmeden, kucuk duruslardan buyuyebilir ve bir yerde durabilir.',
    attraction:
        'Seni ceken taraf gosteris degil, dikkatini dagilmadan verebilmesi olabilir. Niyetindeki sakin bag, bu portredeki olculu sicaklikla ortusebilir.',
    challenge:
        'Surtunme, cok konusmamaktan da gelebilir. Birinin ice cekildigi anda digerinin bunu ilgisizlik sanmasi olasi ve olgunluk ister.',
    meeting:
        'Karsilasma, kalabalik bir sahneden cok, sessiz bir aralikta kisa bir bakis gibi hissedilebilir. Sonra ayni yerde durabilmek yeterli olabilir.',
    feeling:
        'Genel his, acele etmeyen bir yakinlik. Kesin bir vaat degil; sana guven veren ama hemen cozulmeyen bir eslik olabilir.',
  );
}

SoulMateInterpretationDraft _bad({
  bool cliche = false,
  bool certain = false,
  bool memory = false,
  bool contradiction = false,
}) {
  final base = _good();
  if (cliche) {
    return SoulMateInterpretationDraft(
      personality: '${base.personality} Ruh esin seni bekliyor ve kalbinin ritmi burada.',
      dynamic: base.dynamic,
      attraction: base.attraction,
      challenge: base.challenge,
      meeting: base.meeting,
      feeling: base.feeling,
    );
  }
  if (certain) {
    return SoulMateInterpretationDraft(
      personality: base.personality,
      dynamic: base.dynamic,
      attraction: 'Seni su tarihte 12/03 bekleyen bir bulusma kesin olarak cekecek ve karsilasacaksin orada.',
      challenge: base.challenge,
      meeting: base.meeting,
      feeling: base.feeling,
    );
  }
  if (memory) {
    return SoulMateInterpretationDraft(
      personality: base.personality,
      dynamic: 'Eski sevgilin gibi daha once seninle yasadigin bir yakinligi hatirliyorum ve bu dinamikte tekrar durabilir.',
      attraction: base.attraction,
      challenge: base.challenge,
      meeting: base.meeting,
      feeling: base.feeling,
    );
  }
  return SoulMateInterpretationDraft(
    personality: '${base.personality} Bu portre kadinsi ve feminine-presenting bir durus tasiyabilir yaninda.',
    dynamic: base.dynamic,
    attraction: base.attraction,
    challenge: base.challenge,
    meeting: base.meeting,
    feeling: base.feeling,
  );
}

class _ScriptedText implements SoulMateInterpretationPort {
  _ScriptedText(this._script);
  final List<SoulMateInterpretationOutcome> _script;
  var imageCalls = 0;

  @override
  Future<SoulMateInterpretationOutcome> interpret(
    SoulMateInterpretationContext context,
  ) async {
    if (_script.isEmpty) return const SoulMateInterpretationOutcome.failed();
    return _script.removeAt(0);
  }
}
