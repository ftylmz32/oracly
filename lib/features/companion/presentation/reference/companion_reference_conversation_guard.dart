/// If conversation is stored but Premium is not active — demote with notice.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui/oracly_snackbar.dart';
import '../../copy/companion_copy.dart';
import '../../models/or_chat_output_mode.dart';
import '../../providers/companion_providers.dart';
import '../../services/companion_voice_conversation_access.dart';

class CompanionReferenceConversationGuard extends ConsumerStatefulWidget {
  const CompanionReferenceConversationGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CompanionReferenceConversationGuard> createState() =>
      _CompanionReferenceConversationGuardState();
}

class _CompanionReferenceConversationGuardState
    extends ConsumerState<CompanionReferenceConversationGuard> {
  bool _demoting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  Future<void> _sync() async {
    if (!mounted || _demoting) return;
    final output = ref.read(companionOutputControllerProvider);
    if (!output.isConversation) return;
    if (CompanionVoiceConversationAccess.isAllowed(context)) return;
    _demoting = true;
    await output.setMode(OrChatOutputMode.voice);
    if (!mounted) return;
    OraclySnackBar.show(
      context,
      message: CompanionCopy.voiceConversationDemoted,
    );
    _demoting = false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(companionOutputControllerProvider, (_, next) {
      if (next.isConversation) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
      }
    });
    return widget.child;
  }
}
