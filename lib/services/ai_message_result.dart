/// RC-003 — Result wrapper for AI chat — keeps errors out of message bubbles.
library;

class AiMessageResult {
  const AiMessageResult._({this.content, this.errorMessage});

  const AiMessageResult.success(String content)
      : this._(content: content);

  const AiMessageResult.failure(String errorMessage)
      : this._(errorMessage: errorMessage);

  final String? content;
  final String? errorMessage;

  bool get isSuccess => content != null && content!.trim().isNotEmpty;
}
