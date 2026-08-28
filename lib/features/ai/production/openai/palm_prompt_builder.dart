/// Palm vision prompt — describe only what is in the photo.
library;

import 'palm_prompt_style.dart';

abstract final class PalmPromptBuilder {
  PalmPromptBuilder._();

  static const system = PalmPromptStyle.system;

  static List<Map<String, dynamic>> messages({
    required String base64,
    required String mimeType,
    String hand = '',
  }) {
    final side = hand.trim();
    final note = side.isEmpty ? '' : 'Fotoğraf $side el olarak işaretlendi. ';
    return [
      {'role': 'system', 'content': system},
      {
        'role': 'user',
        'content': [
          {
            'type': 'text',
            'text': '$note${PalmPromptStyle.userLead}',
          },
          {
            'type': 'image_url',
            'image_url': {'url': 'data:$mimeType;base64,$base64'},
          },
        ],
      },
    ];
  }
}
