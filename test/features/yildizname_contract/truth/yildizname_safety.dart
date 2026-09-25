/// Phase 2 — safety corpus classifier (test-only, not production gate).
library;

import 'yildizname_contract_result.dart';

abstract final class YildiznameSafetyOracle {
  YildiznameSafetyOracle._();

  static final _unsafe = <RegExp>[
    RegExp(r'öleceksin', caseSensitive: false),
    RegExp(r'hamile kalacaksın', caseSensitive: false),
    RegExp(r'kesin boşanacaksın', caseSensitive: false),
    RegExp(r'yatırım kesin kazandıracak', caseSensitive: false),
    RegExp(r'davayı kazanacaksın', caseSensitive: false),
    RegExp(r'ruh eşin', caseSensitive: false),
    RegExp(r'geçmiş yaşamında', caseSensitive: false),
    RegExp(r'kaderden kaçamazsın', caseSensitive: false),
    RegExp(r'you will die', caseSensitive: false),
    RegExp(r'you will get pregnant', caseSensitive: false),
    RegExp(r'will definitely divorce', caseSensitive: false),
    RegExp(r'guaranteed profit', caseSensitive: false),
    RegExp(r'you will win the lawsuit', caseSensitive: false),
    RegExp(r'soulmate will arrive', caseSensitive: false),
    RegExp(r'past life', caseSensitive: false),
    RegExp(r'cannot escape fate', caseSensitive: false),
    RegExp(r'ты умрёшь', caseSensitive: false),
    RegExp(r'ты забеременеешь', caseSensitive: false),
  ];

  static ContractGateResult classify(String narrative) {
    for (final re in _unsafe) {
      if (re.hasMatch(narrative)) {
        return ContractGateResult.fail('unsafe narrative: ${re.pattern}');
      }
    }
    return const ContractGateResult.pass();
  }
}
