/// OR-1000 — Tarot module public API.
library;

// Components
export 'components/tarot_background.dart';
export 'components/tarot_button.dart';
export 'components/tarot_empty_state.dart';
export 'components/tarot_error_state.dart';
export 'components/tarot_glass_card.dart';
export 'components/tarot_header.dart';
export 'components/tarot_loading.dart';
export 'components/tarot_navigation_bar.dart';
export 'components/tarot_orb.dart';
export 'components/tarot_glow_layer.dart';
export 'components/tarot_section_title.dart';

// Controllers
export 'controllers/tarot_base_controller.dart';
export 'controllers/tarot_deck_controller.dart';
export 'controllers/tarot_flow_controller.dart';
export 'controllers/tarot_reading_controller.dart';

// Domain
export 'domain/models/tarot_session.dart';
export 'domain/models/tarot_spread.dart';
export 'domain/repositories/tarot_reading_repository.dart';

// Navigation
export 'navigation/tarot_module_navigator.dart';
export 'navigation/tarot_navigator.dart';
export 'shared/constants/tarot_routes.dart';
export 'shared/tarot_scope.dart';

// Presentation — screens
export 'presentation/screens/card_detail_screen.dart';
export 'presentation/screens/card_reveal_screen.dart';
export 'presentation/screens/card_selection_screen.dart';
export 'presentation/screens/deck_selection_screen.dart';
export 'presentation/screens/premium_tarot_screen.dart';
export 'presentation/screens/reading_history_detail_screen.dart';
export 'presentation/screens/reading_history_screen.dart';
export 'presentation/screens/reading_screen.dart';
export 'presentation/screens/shuffle_screen.dart';
export 'presentation/screens/tarot_home_screen.dart';

// Presentation — shell & animation
export 'presentation/animations/tarot_transition.dart';
export 'presentation/widgets/tarot_foundation_layout.dart';
export 'presentation/widgets/tarot_screen_shell.dart';

// Theme
export 'theme/tarot_theme.dart';
export 'theme/tarot_tokens.dart';

// Interpretation pipeline (OR-1180)
export 'interpretation/interpretation.dart';
export 'services/tarot_interpretation_service.dart';

// Legacy tab entry — preserved for app shell compatibility.
export 'screens/tarot_select_screen.dart';
