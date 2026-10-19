/// Validated chat / OR reply — no fabricated fallback text.
library;

class ChatAiReply {
  const ChatAiReply({
    required this.text,
    this.modelId,
    this.speechGrant,
  });

  final String text;
  final String? modelId;
  final String? speechGrant;
}
