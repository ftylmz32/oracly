/// SPRINT-003 — Companion user-facing copy.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/personality/or_conversation_opening.dart';
import '../../../core/personality/or_living_voice.dart';
import '../../../core/personality/or_response_depth.dart';

abstract final class CompanionCopy {
  CompanionCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get screenTitle => _t('or.screen_title');
  static String get guideSubtitle => _t('or.guide_subtitle');
  static String get introHello => _t('or.intro_hello');
  static String get introBody => _t('or.intro_body');
  static String get introBadge => _t('or.intro_badge');
  static String get dayToday => _t('or.day_today');
  static String get privacyNote => _t('or.privacy_note');
  static String get shortcutTarot => _t('or.shortcut.tarot');
  static String get shortcutCoffee => _t('or.shortcut.coffee');
  static String get shortcutDream => _t('or.shortcut.dream');
  static String get shortcutAstrology => _t('or.shortcut.astrology');
  static String get shortcutSoulMate => _t('or.shortcut.soulmate');
  static String get memoryTransparency => _t('or.memory_transparency');
  static String get handoffBannerTarot => _t('or.handoff.banner.tarot');
  static String get handoffBannerGeneric => _t('or.handoff.banner.generic');
  static String get handoffContinuing => _t('or.handoff.banner.continuing');
  static String get viewMemories => _t('or.view_memories');
  static String get saveToMemory => _t('or.save_to_memory');
  static String get memorySaved => _t('or.memory_saved');
  static String get voiceComingSoon => _t('or.voice_coming');
  static String get voiceLabel => _t('or.voice_label');
  static String get voiceListening => _t('or.voice_listening');
  static String get voiceCancel => _t('or.voice_cancel');
  static String get voiceCancelHint => _t('or.voice_cancel_hint');
  static String get voiceRequesting => _t('or.voice_requesting');
  static String get voicePermissionDenied => _t('or.voice_denied');
  static String get voicePermissionPermanent => _t('or.voice_permanent');
  static String get voiceMicUnavailable => _t('or.voice_mic');
  static String get voiceSpeechUnavailable => _t('or.voice_speech_unavailable');
  static String get voiceOutputUnavailable => _t('or.voice_output_unavailable');
  static String get voiceSpeechError => _t('or.voice_speech_error');
  static String get voiceEmpty => _t('or.voice_empty');
  static String get voiceReviewHint => _t('or.voice_review_hint');
  static String get voiceReviewRetry => _t('or.voice_review_retry');
  static String get voiceReviewSend => _t('or.voice_review_send');
  static String get voiceConversationPreviewTitle =>
      _t('or.voice_conversation_preview_title');
  static String get voiceConversationPreviewLead =>
      _t('or.voice_conversation_preview_lead');
  static String get voiceConversationPreviewBody =>
      _t('or.voice_conversation_preview_body');
  static String get voiceConversationPreviewAside =>
      _t('or.voice_conversation_preview_aside');
  static String get voiceConversationDemoted =>
      _t('or.voice_conversation_demoted');
  static String get voiceConversationLocked =>
      _t('or.voice_conversation_locked');
  static String get orPremiumTitle => _t('or.premium_title');
  static String get orPremiumLead => _t('or.premium_lead');
  static String get orPremiumPersonality => _t('or.premium_personality');
  static String get orPremiumSampleLabel => _t('or.premium_sample_label');
  static String get orPremiumSampleNote => _t('or.premium_sample_note');
  static String get orPremiumSampleUser0 => _t('or.premium_sample_user_0');
  static String get orPremiumSampleOr0 => _t('or.premium_sample_or_0');
  static String get orPremiumSampleUser1 => _t('or.premium_sample_user_1');
  static String get orPremiumSampleOr1 => _t('or.premium_sample_or_1');
  static String get orPremiumBody => _t('or.premium_body');
  static String get orPremiumAside => _t('or.premium_aside');
  static String get orPaywallTitle => _t('or.paywall_title');
  static String get orPaywallLead => _t('or.paywall_lead');
  static String get orPaywallPillarDepthTitle =>
      _t('or.paywall_pillar_depth_title');
  static String get orPaywallPillarDepthBody =>
      _t('or.paywall_pillar_depth_body');
  static String get orPaywallPillarContinuityTitle =>
      _t('or.paywall_pillar_continuity_title');
  static String get orPaywallPillarContinuityBody =>
      _t('or.paywall_pillar_continuity_body');
  static String get orPaywallPillarVoiceTitle =>
      _t('or.paywall_pillar_voice_title');
  static String get orPaywallPillarVoiceBody =>
      _t('or.paywall_pillar_voice_body');
  static String get orPaywallPillarContextTitle =>
      _t('or.paywall_pillar_context_title');
  static String get orPaywallPillarContextBody =>
      _t('or.paywall_pillar_context_body');
  static String get orPaywallPillarSessionsTitle =>
      _t('or.paywall_pillar_sessions_title');
  static String get orPaywallPillarSessionsBody =>
      _t('or.paywall_pillar_sessions_body');
  static String get orPaywallPillarDiscoveryTitle =>
      _t('or.paywall_pillar_discovery_title');
  static String get orPaywallPillarDiscoveryBody =>
      _t('or.paywall_pillar_discovery_body');
  static String get orPaywallHonesty => _t('or.paywall_honesty');
  static String get orPaywallCta => _t('or.paywall_cta');
  static String get orEntitlementPending => _t('or.entitlement_pending');
  static String get orEntitlementRestoring => _t('or.entitlement_restoring');
  static String get orEntitlementUnavailable =>
      _t('or.entitlement_unavailable');
  static String get orEntitlementError => _t('or.entitlement_error');
  static String get firstReadingDeepenHint => _t('or.first_reading_deepen');
  static String get outputText => _t('or.output_text');
  static String get outputVoice => _t('or.output_voice');
  static String get outputConversation => _t('or.output_conversation');
  static String get voiceTurnReady => _t('or.voice_turn_ready');
  static String get voiceTurnListening => _t('or.voice_turn_listening');
  static String get voiceTurnSettling => _t('or.voice_turn_settling');
  static String get voiceTurnThinking => _t('or.voice_turn_thinking');
  static String get voiceTurnSpeaking => _t('or.voice_turn_speaking');
  static String depthLabel(OrResponseDepth depth) => switch (depth) {
    OrResponseDepth.veryShort => _t('or.depth.very_short'),
    OrResponseDepth.short => _t('or.depth.short'),
    OrResponseDepth.balanced => _t('or.depth.balanced'),
    OrResponseDepth.deep => _t('or.depth.deep'),
  };
  static String get outputTextLabel => outputText;
  static String get outputVoiceLabel => outputVoice;
  static String get stopSpeaking => _t('or.stop_speaking');
  static String get pauseSpeaking => _t('or.pause_speaking');
  static String get resumeSpeaking => _t('or.resume_speaking');
  static String get replaySpeaking => _t('or.replay_speaking');
  static String get speaking => _t('or.speaking');
  static String get paused => _t('or.paused');

  /// Natural open — varies by day/style; not a help-desk line.
  static String idleCaption({
    String personality = 'mystical',
    DateTime? moment,
    String? name,
  }) => OrConversationOpening.line(
    personality: personality,
    moment: moment,
    name: name,
  );

  static String get idleTitle => _t('or.idle_title');
  static String get idleSubtitle => _t('or.idle_subtitle');

  /// Quiet cue that starters are optional — never a menu title.
  static String get idleOptional => _t('or.idle_optional');
  static String get presence => _t('or.presence');
  static String get plusLabel => _t('or.plus');
  static String get plusSemantics => _t('or.plus_a11y');
  static String get messageYou => _t('or.msg_you');
  static String get messageOr => _t('or.msg_or');
  static String get sendLabel => _t('or.send');
  static String get copyAction => _t('insight.copy');
  static String get copied => _t('insight.copied');
  static String get speakAction => _t('or.speak');
  static String get regenerateAction => _t('or.regenerate');
  static String get newReply => _t('or.new_reply');
  static String get thinking => OrLivingVoice.thinking();
  static String get presenceThinking => _t('or.presence_thinking');
  static String get retry => _t('or.retry');
  static String get offline => _t('or.offline');
  static String get connecting => _t('or.connecting');
  static String get reconnecting => _t('or.reconnecting');
  static String get retrying => _t('or.retrying');
  static String get providerUnavailable => _t('or.provider_unavailable');
  static String get saveFailed => _t('or.save_failed');
  static String get saving => _t('or.saving');
  static String get welcomeTitle => _t('or.welcome_title');
  static String get welcomeBody => _t('or.welcome_body');
  static String get connectionError => _t('or.error');

  static String welcomeLine({
    String? name,
    String personality = 'mystical',
    DateTime? moment,
  }) => idleCaption(personality: personality, moment: moment, name: name);

  static String welcome({
    String? name,
    String personality = 'mystical',
    DateTime? moment,
  }) => welcomeLine(name: name, personality: personality, moment: moment);

  static List<String> get suggestions => [
    _t('or.suggestion.love'),
    _t('or.suggestion.career'),
    _t('or.suggestion.undecided'),
    _t('or.suggestion.dream'),
    _t('or.suggestion.astrology'),
    _t('or.suggestion.mood'),
    _t('or.suggestion.soulmate'),
  ];

  /// Contextual starters — real messages, never decorative labels.
  static List<String> suggestionsForKind(String? kindId) {
    final key = (kindId ?? '').trim().toLowerCase();
    if (key == 'palm') {
      return [
        _t('or.suggestion.palm.0'),
        _t('or.suggestion.palm.1'),
        _t('or.suggestion.palm.2'),
      ];
    }
    if (key == 'tarot') {
      return [
        _t('or.suggestion.tarot.0'),
        _t('or.suggestion.tarot.1'),
        _t('or.suggestion.tarot.2'),
      ];
    }
    if (key == 'coffee') {
      return [
        _t('or.suggestion.coffee.0'),
        _t('or.suggestion.coffee.1'),
        _t('or.suggestion.coffee.2'),
      ];
    }
    if (key == 'dream') {
      return [
        _t('or.suggestion.dream.0'),
        _t('or.suggestion.dream.1'),
        _t('or.suggestion.dream.2'),
      ];
    }
    return suggestions;
  }

  static String get menuNewChat => _t('or.menu.new_chat');
  static String get menuClearContext => _t('or.menu.clear_context');
  static String get menuRemoveReading => _t('or.menu.remove_reading');
  static String get menuPremium => _t('or.menu.premium');
  static String get menuSettings => _t('or.menu.settings');
  static String get contextCleared => _t('or.context_cleared');

  static String get followUpDeepen => _t('or.followup.deepen');
  static String get followUpDecision => _t('or.followup.decision');
  static String get followUpEmotion => _t('or.followup.emotion');
  static String get followUpReading => _t('or.followup.reading');
  static String get followUpRelationship => _t('or.followup.relationship');

  static String get orPremiumHeadline => _t('or.premium_headline');
}
