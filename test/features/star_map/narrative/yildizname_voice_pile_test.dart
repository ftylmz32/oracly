/// False pairs stay clear. A real abstract catalogue still fails.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_voice_pile.dart';

void main() {
  test('an adjective and a natural pair are not piles', () {
    expect(
      YildiznameVoicePile.isPile(
        'En sağlıklı denge, yakınlığı sürekli kanıt istemekle karıştırmadan kuruluyor.',
      ),
      isFalse,
    );
    expect(
      YildiznameVoicePile.isPile(
        'Sıcaklığının ve emeğinin gerçekten karşılık bulmasını istersin.',
      ),
      isFalse,
    );
    expect(
      YildiznameVoicePile.isPile(
        'Fakat yakınlık kadar özgürlük de önemlidir.',
      ),
      isFalse,
    );
    expect(
      YildiznameVoicePile.isPile(
        'İnandığın bir amaç olduğunda cesaret, cömertlik ve dayanıklılık gösterebilirsin.',
      ),
      isFalse,
    );
  });

  test('a swapped natural pair is still not a pile', () {
    expect(
      YildiznameVoicePile.isPile(
        'Sakinlik kadar hareket de senin için gerekli olabilir.',
      ),
      isFalse,
    );
    expect(
      YildiznameVoicePile.isPile(
        'Dürüstlük ve açıklık göstermen bu bağda işe yarar.',
      ),
      isFalse,
    );
  });

  test('a stacked abstract catalogue stays a pile when the nouns change', () {
    expect(
      YildiznameVoicePile.isPile(
        'Kamusal yönelimde koruyuculuk, duyarlılık ve aidiyet oluşturma ihtiyacını öne çıkarıyor.',
      ),
      isTrue,
    );
    expect(
      YildiznameVoicePile.isPile(
        'Sabit nitelik yoğunluğu bağlılık ve dayanıklılık verebilir.',
      ),
      isTrue,
    );
    expect(
      YildiznameVoicePile.isPile(
        'İlişkilerde sıcaklık, cömertlik, sadakat ve arkadaşlık temelini önemseyebilir.',
      ),
      isTrue,
    );
    expect(
      YildiznameVoicePile.isPile(
        'Orada şefkat, bağlılık, duyarlılık ve aidiyet aynı cümlede üst üste biner.',
      ),
      isTrue,
    );
  });
}
