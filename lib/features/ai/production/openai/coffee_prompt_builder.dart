/// Coffee vision prompt — describe only what is in the photo.
library;

import 'coffee_prompt_style.dart';

abstract final class CoffeePromptBuilder {
  CoffeePromptBuilder._();

  static const system = CoffeePromptStyle.system;

  static List<Map<String, dynamic>> messages({
    required String base64,
    required String mimeType,
  }) {
    return [
      {'role': 'system', 'content': system},
      {
        'role': 'user',
        'content': [
          {
            'type': 'text',
            'text': CoffeePromptStyle.userLead,
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
