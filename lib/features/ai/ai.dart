/// OR-1110 — AI feature public API.
library;

// Domain
export 'domain/models/models.dart';
export 'domain/models/token_usage.dart';
export 'domain/repositories/repositories.dart';

// Data
export 'data/repositories/mock_ai_repository.dart';
export 'data/repositories/mock_astrology_ai_repository.dart';
export 'data/repositories/mock_dream_ai_repository.dart';
export 'data/repositories/mock_energy_ai_repository.dart';
export 'data/repositories/mock_tarot_ai_repository.dart';

// Services
export 'services/services.dart';

// Providers
export 'providers/ai_providers.dart';

// Widgets
export 'presentation/widgets/ai_markdown_body.dart';
export 'presentation/widgets/ai_message_actions.dart';
export 'presentation/widgets/ai_message_bubble.dart';
export 'presentation/widgets/ai_typing_indicator.dart';
export 'presentation/widgets/oracle_avatar.dart';
export 'presentation/widgets/streaming_text.dart';
export 'presentation/widgets/suggestion_chip.dart';
export 'presentation/widgets/thinking_animation.dart';

// OR-1190 — Oracle conversation
export 'oracle_conversation/models/oracle_reading_context.dart';
export 'oracle_conversation/navigation/oracle_conversation_route.dart';
export 'oracle_conversation/providers/oracle_conversation_providers.dart';
export 'presentation/screens/oracle_conversation_screen.dart';
export 'presentation/widgets/oracle_conversation_header.dart';
export 'presentation/widgets/oracle_conversation_input.dart';
export 'presentation/widgets/oracle_suggestion_chips.dart';
