/// G1 — in-memory SoulMate Journal and a counting interpretation port.
library;

import 'dart:io';

import 'package:oracly_new/features/premium/data/soul_mate_interpretation_catalogue.dart';
import 'package:oracly_new/features/premium/models/soul_mate_saved_result.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_identity.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation_context.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_result_service.dart';

const g1PartialParts = SoulMateReadingParts(
  energy: '',
  attraction: '',
  dynamics: '',
  feeling: '',
  yourSide: '',
);

const g1FullParts = SoulMateReadingParts(
  energy: 'e',
  attraction: 'a',
  dynamics: 'd',
  feeling: 'f',
  yourSide: 'y',
  authoritative: true,
);

/// Keeps every saved row by id, so a repair that mints a second row shows.
class G1MemorySoulMateJournal extends SoulMateResultService {
  G1MemorySoulMateJournal(super.storage);

  final rows = <String, SoulMateSavedResult>{};
  SoulMateSavedResult? _latest;

  @override
  Future<SoulMateSavedResult?> latestMeta() async => _latest;

  @override
  Future<({SoulMateSavedResult meta, List<int> bytes})?>
      latestWithPortrait() async {
    final meta = _latest;
    return meta == null ? null : (meta: meta, bytes: const [1, 2, 3]);
  }

  @override
  Future<bool> hasSavedResult() async => _latest != null;

  @override
  Future<SoulMateSavedResult?> saveSuccessfulDraw({
    required SoulMateDrawRequest request,
    required List<int> imageBytes,
    SoulMateReadingParts? parts,
    Directory? documents,
    String? recordId,
    String? expectedOwnerId,
    SoulMateIdentity? identity,
  }) async {
    final id = (recordId ?? '').isEmpty
        ? 'minted-${rows.length + 1}'
        : recordId!;
    final saved = SoulMateSavedResult(
      id: id,
      createdAt: DateTime(2026, 9, 1),
      name: request.name.trim(),
      birthDate: request.birthDate,
      gender: request.gender,
      intention: request.intention,
      portraitPath: 'memory://$id',
      parts: parts ?? g1PartialParts,
      identity: identity,
    );
    rows[id] = saved;
    _latest = saved;
    return saved;
  }

  @override
  Future<void> clear() async {
    rows.clear();
    _latest = null;
  }
}

class G1CountingInterpretation implements SoulMateInterpretationPort {
  G1CountingInterpretation({this.succeed = true});

  final bool succeed;
  int calls = 0;

  @override
  Future<SoulMateInterpretationOutcome> interpret(
    SoulMateInterpretationContext context,
  ) async {
    calls++;
    return succeed
        ? const SoulMateInterpretationOutcome.success(g1FullParts)
        : const SoulMateInterpretationOutcome.failed();
  }
}
