/// HEDEF ANLATIM ÖRNEĞİ.
///
/// Yerel yeniden yazım. 16 Ekim 2026 tarihli gerçek haritanın anlamını,
/// o çağrının raporu yerine bir insana anlatır. Yeni bir sağlayıcı çıktısı
/// değildir. Bu metnin yapısal denetimi geçmesi, ürün kalitesinin canlı
/// modelle doğrulandığı anlamına gelmez.
library;

import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_section.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_structured_result.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_section_kind.dart';
import 'package:oracly_new/features/star_map/narrative/versions.dart';

const kYildiznameTargetExampleLabel = 'HEDEF ANLATIM ÖRNEĞİ';

/// No second provider call exists. Keep this false until one does.
const bool kYildiznameLiveProductQualityVerified = false;

YildiznameNarrativeStructuredResult yildiznameTargetPortraitExample() {
  return YildiznameNarrativeStructuredResult(
    contractVersion: kYildiznameResultContractVersion,
    languageCode: 'tr',
    scope: YildiznameNarrativeScope.full,
    summary: YildiznameNarrativeBlock(
      text: 'İnsanlarla bir araya geldiğinde kendini göstermek ve fikirlerini '
          'paylaşmak senin için önemli bir tema. Herkesin içinde görünür '
          'olmakla, gerçekten anlaşıldığını hissetmek aynı şey değil. '
          'Dışarıdan daha ölçülü durursun; karşı tarafı hesaba katarsın. '
          'Bir kez yöneldiğin yerde kalmak da sana kolay gelir. Seçtiğin '
          'şeye süre veren bir yanın var.',
      factRefs: const [
        'placement.sun',
        'placement.moon',
        'placement.venus',
        'placement.mars',
        'angle.ascendant',
        'balance.elements',
      ],
      themeRefs: const ['theme.0'],
    ),
    sections: [
      YildiznameNarrativeSection(
        kind: YildiznameSectionKind.coreIdentity,
        text: 'Bir işe girdiğinde yarım bırakmak sana eksik gelebilir. Bir kez '
            'evet dedikten sonra o eveti çabuk geri almak kolay gelmeyebilir. '
            'Yön değiştirmek sana pahalı gelir, çünkü seçtiğin şey hâlâ senin '
            'tarafında durur. Buna inat demek doğru olmaz. Bu, sevdiğin şeyi '
            'sürdürme isteğidir. Kararını aceleyle vermen gerekmez; bir evet, '
            'senin için hafif bir laf olmaktan çok, arkasında durulacak bir '
            'söz gibi durabilir. Kararını bugün bitirmek zorunda değilsin; '
            'süre, senin tarafında çalışan bir şeydir.',
        factRefs: const ['placement.sun', 'aspect.sun.saturn.trine'],
        themeRefs: const [],
      ),
      YildiznameNarrativeSection(
        kind: YildiznameSectionKind.relationshipsAndValues,
        text: 'Yakınlıkta iki ihtiyaç birlikte durur. Biri, ilişkinin içinde '
            'kendi hareket alanının kalması. Diğeri, güvenin acele bir sözle '
            'değil, zaman içindeki tutarlı davranışla kurulması. Bir plan '
            'son anda değiştiğinde bu sana canlı gelebilir. Aynı kişi uzun '
            'süre ortada yoksa o canlılık yerini yoklamaya bırakabilir. Bu '
            'iki ihtiyacı birbirine düşman etmek zorunda değilsin. Sınır, '
            'burada mesafe koyup gitmek demek değil; buradayım, ve kendi '
            'tempom da var.',
        factRefs: const [
          'placement.venus',
          'aspect.venus.uranus.opposition',
          'aspect.venus.saturn.square',
        ],
        themeRefs: const ['theme.0'],
      ),
      YildiznameNarrativeSection(
        kind: YildiznameSectionKind.driveAndGrowth,
        text: 'Harekete geçmen, önünde bir hedef netleşince kolaylaşabilir. Zor '
            'olan, niyetin kafanda bitip elde henüz küçük bir adımın '
            'olmaması. O anda ya çok büyük bir yük alırsın ya da başlamayı '
            'ertelersin. İkisi de aynı yerden gelir. İlhamın geldiği gün işi '
            'bitmiş saymak, ertesi sabah hâlâ ilk adımın duruyor olmasıdır. '
            'Yarın için tek bir sayfa, tek bir mesaj ya da tek bir saat, '
            'niyeti küçültmez; elle tutulur hale getirir.',
        factRefs: const [
          'placement.mars',
          'placement.jupiter',
          'aspect.mars.saturn.square',
          'aspect.mars.neptune.opposition',
        ],
        themeRefs: const [],
      ),
      YildiznameNarrativeSection(
        kind: YildiznameSectionKind.patternsAndTensions,
        text: 'Paylaştığın şeyde sağlam bir zemin ararsın. Üretirken ise '
            'şaşırmak, alışılmışın dışına çıkmak istersin. Aynı haftanın '
            'içinde hem buna güvenir miyim diye bakan hem de rutini zorlayan '
            'bir hal bir arada durabilir. Birini seçip diğerini susturmak '
            'gerekmez. Sağlam olan, yeniliğin üstünde durabildiği yerdir. '
            'İkisini sıraya koymak, birini silmek anlamına gelmez.',
        factRefs: const [
          'placement.saturn',
          'placement.uranus',
          'aspect.saturn.uranus.square',
          'aspect.saturn.neptune.square',
        ],
        themeRefs: const [],
      ),
      YildiznameNarrativeSection(
        kind: YildiznameSectionKind.practicalReflection,
        text: 'Günün dolu hali seni yorabilir. Sessiz hali ise toparlar. Bir '
            'konuşma bittikten sonra zihninin onu bir kez daha yoklaması '
            'şüphe olmak zorunda değil; bu sindirme de olabilir. Dinlenmek '
            'için önce tükenmen gerekmez. Ne bir bağ ne ortak bir iş, sen '
            'durunca bitmek zorunda değil. O ara yeni bir yük almak zorunda '
            'da değilsin.',
        factRefs: const [
          'placement.moon',
          'placement.mercury',
          'aspect.moon.mercury.conjunction',
        ],
        themeRefs: const ['theme.1'],
      ),
    ],
    reflectionPrompt: 'Bir sofrada hem özgür hem güvende hissettiğin anı '
        'düşün. O anı ayakta tutan şey neydi: söylenmiş açık bir söz mü, '
        'kimsenin seni tutmaması mı, yoksa ertesi gün de orada olunacağı mı?',
    closingMessage: 'İnsanları bir araya getiren bir yanın var. Bunu her gün aynı '
        'tempoda sürdürmek zorunda değilsin. Kendi ritmine yer verdiğinde '
        'bağın da o ritimle birlikte durabilir.',
  );
}
