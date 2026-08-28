/// Detects how OR should meet this turn — fortune is one mode, not the default.
library;

import 'companion_correction.dart';
import 'companion_job_change.dart';
import 'companion_short_followup.dart';

abstract final class CompanionIntent {
  CompanionIntent._();

  static bool isGreeting(String text) {
    const hits = {
      'selam',
      'merhaba',
      'selamlar',
      'hey',
      'hi',
      'hello',
      'привет',
    };
    return hits.contains(_bare(text));
  }

  static bool isLow(String text) {
    final t = text.toLowerCase();
    return t.contains('sıkkın') ||
        t.contains('canım sık') ||
        t.contains('yorgun') ||
        t.contains('içim dar') ||
        t.contains('bunald') ||
        t.contains('üzgün') ||
        _word(t, 'sad') ||
        _word(t, 'tired') ||
        t.contains('груст') ||
        t.contains('скучн');
  }

  static bool _word(String haystack, String word) =>
      RegExp('\\b${RegExp.escape(word)}\\b').hasMatch(haystack);

  static bool isKnowledge(String text) {
    final t = text.toLowerCase();
    if (isFortune(t) || isMedical(t) || isPrediction(t)) return false;
    return t.contains('python') ||
        t.contains('async') ||
        t.contains('nasıl çalışır') ||
        t.contains('how does') ||
        t.contains('how do') ||
        t.contains('что такое') ||
        t.contains('как работает');
  }

  static bool isPythonAsync(String text) {
    final t = text.toLowerCase();
    return t.contains('python') && t.contains('async');
  }

  static bool isPrediction(String text) {
    final t = text.toLowerCase();
    return t.contains('geri dönecek') ||
        t.contains('kesin olacak') ||
        t.contains('hayatına girecek') ||
        t.contains('will come back') ||
        t.contains('definitely happen') ||
        t.contains('точно верн');
  }

  static bool isMedical(String text) {
    final t = text.toLowerCase();
    return t.contains('ölüm') ||
        t.contains('hastalık') ||
        t.contains('ömrüm') ||
        t.contains('teşhis') ||
        t.contains('lifespan') ||
        t.contains('death in') ||
        t.contains('смерть') ||
        t.contains('болезн');
  }

  static bool isFortune(String text) {
    final t = text.toLowerCase();
    return t.contains('kahve') ||
        t.contains('fincan') ||
        t.contains('tarot') ||
        t.contains('açılım') ||
        t.contains('kart') ||
        t.contains('burç') ||
        t.contains('yıldızname') ||
        t.contains('rüya') ||
        t.contains('el fal') ||
        t.contains('horoscope') ||
        t.contains('coffee cup');
  }

  static bool isJobChange(String text) => CompanionJobChange.matches(text);

  static bool isShortFollowUp(String text) =>
      CompanionShortFollowUp.matches(text);

  static bool isCorrection(String text) =>
      CompanionCorrection.matches(text);

  static bool isAdvice(String text) {
    final t = text.toLowerCase();
    return t.contains('ne yapmalıyım') ||
        t.contains('ne yapayım') ||
        t.contains('what should i do') ||
        t.contains('что мне делать');
  }

  static bool isOverconfident(String text) {
    final t = text.toLowerCase();
    if (t.contains('?') || isPrediction(text)) return false;
    return (t.contains('herkes') &&
            (t.contains('olmalı') ||
                t.contains('yapmalı') ||
                t.contains('değiştirmeli'))) ||
        t.contains('kaderimde yaz') ||
        t.contains('garanti') ||
        t.contains('kesin çözüm') ||
        (t.contains('kesin') && t.contains('olacak'));
  }

  static bool isBoss(String text) {
    final t = text.toLowerCase();
    return t.contains('patron') ||
        t.contains('boss') ||
        t.contains('начальник');
  }

  static bool isUndecided(String text) {
    final t = text.toLowerCase();
    return t.contains('kararsız') ||
        t.contains('kafam karış') ||
        t.contains('kafası karış') ||
        t.contains('confused') ||
        t.contains('не реша') ||
        t.contains('путаниц') ||
        (t.contains('bilmiyorum') && t.length < 80) ||
        t.contains('undecided');
  }

  static String _bare(String text) => text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[.!?…,]+$'), '')
      .trim();
}
