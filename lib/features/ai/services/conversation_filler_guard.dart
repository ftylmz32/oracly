/// Stock openers / help-desk / meta-AI leading filler.
library;

abstract final class ConversationFillerGuard {
  ConversationFillerGuard._();

  static String shape(String text) {
    var out = text.trim();
    out = out.replaceFirst(
      RegExp(
        r'^(elbette|tabii ki|tabii|anlıyorum|bence|aslında|aslinda|'
        r'şunu söyleyeyim|sunu soyleyeyim|bu enerji|'
        r'işin doğrusu|isin dogrusu)[,!:]?\s*',
        caseSensitive: false,
      ),
      '',
    );
    out = out.replaceFirst(
      RegExp(
        r'^(buradayım|yanındayım)[,!.]?\s*',
        caseSensitive: false,
      ),
      '',
    );
    out = out.replaceFirst(
      RegExp(r"^i'?m here[,!.]?\s*", caseSensitive: false),
      '',
    );
    out = out.replaceFirst(
      RegExp(
        r'^(burada başka bir şey var|işin ilginç tarafı|'
        r'şu ayrıntı (bence )?önemli|analiz tamamlandı)[,:.]?\s*',
        caseSensitive: false,
      ),
      '',
    );
    out = out.replaceFirst(
      RegExp(
        r'^(merhaba!?\s+)?size ((bugün )?nasıl )?yardımcı olabilirim[.!]?\s*',
        caseSensitive: false,
      ),
      '',
    );
    out = out.replaceFirst(
      RegExp(
        r'^(hello!?\s+)?how (can|may) i (help|assist)( you)?( today)?[.!?]?\s*',
        caseSensitive: false,
      ),
      '',
    );
    out = out.replaceFirst(
      RegExp(r'^чем могу помочь[.!]?\s*', caseSensitive: false),
      '',
    );
    out = out.replaceFirst(
      RegExp(
        r'^(as an ai[,:]?\s*|as a language model[,:]?\s*|'
        r'ben bir yapay zeka[,.]?\s*|ben bir dil modeliyim[,.]?\s*|'
        r'i am an ai[,:]?\s*)',
        caseSensitive: false,
      ),
      '',
    );
    out = out.replaceAll(
      RegExp(r'^#{1,3}\s+.+$', multiLine: true),
      '',
    );
    out = _stripStockClosings(out);
    return out.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  static String _stripStockClosings(String text) {
    var out = text.trim();
    out = out.replaceFirst(
      RegExp(
        r'\s*(İstersen devam edebiliriz|Istersen devam edebiliriz|'
        r'Buradayım\.?|Devam edebiliriz\.?|Sen bilirsin\.?)\s*$',
        caseSensitive: false,
      ),
      '',
    );
    out = out.replaceFirst(
      RegExp(
        r'\s*(If you want,? we can continue|I.?m here\.?|'
        r'We can continue\.?|It.?s up to you\.?)\s*$',
        caseSensitive: false,
      ),
      '',
    );
    return out.trim();
  }
}
