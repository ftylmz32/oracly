/// Canonical Narrative Tarot keyword ontology (FR-M04 / Phase 3C.5E).
///
/// Language-agnostic ids. Soft Evidence Engine signals only.
/// Ontology revision is independent of profileRevision.
library;

abstract final class NarrativeKeywordIds {
  NarrativeKeywordIds._();

  /// Ontology revision — distinct from NarrativeCardProfile.profileRevision.
  static const int ontologyRevision = 1;

  static const abundance = 'abundance';
  static const accountability = 'accountability';
  static const agency = 'agency';
  static const anger = 'anger';
  static const attachment = 'attachment';
  static const authority = 'authority';
  static const avoidance = 'avoidance';
  static const awakening = 'awakening';
  static const balance = 'balance';
  static const belonging = 'belonging';
  static const bias = 'bias';
  static const boast = 'boast';
  static const bondage = 'bondage';
  static const boundary = 'boundary';
  static const burden = 'burden';
  static const change = 'change';
  static const choice = 'choice';
  static const clarity = 'clarity';
  static const closing = 'closing';
  static const coldness = 'coldness';
  static const communication = 'communication';
  static const compassion = 'compassion';
  static const completion = 'completion';
  static const conformity = 'conformity';
  static const confusion = 'confusion';
  static const control = 'control';
  static const coordination = 'coordination';
  static const courage = 'courage';
  static const craft = 'craft';
  static const creation = 'creation';
  static const curiosity = 'curiosity';
  static const cycles = 'cycles';
  static const delay = 'delay';
  static const denial = 'denial';
  static const dependence = 'dependence';
  static const desire = 'desire';
  static const despair = 'despair';
  static const direction = 'direction';
  static const discernment = 'discernment';
  static const discipline = 'discipline';
  static const discord = 'discord';
  static const display = 'display';
  static const doubt = 'doubt';
  static const ending = 'ending';
  static const enough = 'enough';
  static const enthusiasm = 'enthusiasm';
  static const envy = 'envy';
  static const escape = 'escape';
  static const exhaustion = 'exhaustion';
  static const externalDemand = 'externalDemand';
  static const fairness = 'fairness';
  static const fear = 'fear';
  static const flow = 'flow';
  static const focus = 'focus';
  static const freedom = 'freedom';
  static const grief = 'grief';
  static const guidance = 'guidance';
  static const harshSpeech = 'harshSpeech';
  static const haste = 'haste';
  static const holding = 'holding';
  static const hope = 'hope';
  static const illusion = 'illusion';
  static const imbalance = 'imbalance';
  static const impatience = 'impatience';
  static const indecision = 'indecision';
  static const inquiry = 'inquiry';
  static const instability = 'instability';
  static const integration = 'integration';
  static const internalStrain = 'internalStrain';
  static const intimacy = 'intimacy';
  static const intuition = 'intuition';
  static const isolation = 'isolation';
  static const joy = 'joy';
  static const judgment = 'judgment';
  static const labor = 'labor';
  static const learning = 'learning';
  static const listening = 'listening';
  static const mastery = 'mastery';
  static const messenger = 'messenger';
  static const mindBurden = 'mindBurden';
  static const misdirection = 'misdirection';
  static const momentum = 'momentum';
  static const mystery = 'mystery';
  static const notListening = 'notListening';
  static const nurture = 'nurture';
  static const opening = 'opening';
  static const overflow = 'overflow';
  static const pause = 'pause';
  static const perspective = 'perspective';
  static const pressure = 'pressure';
  static const principle = 'principle';
  static const projection = 'projection';
  static const receptivity = 'receptivity';
  static const reciprocity = 'reciprocity';
  static const release = 'release';
  static const renewal = 'renewal';
  static const rescue = 'rescue';
  static const resistance = 'resistance';
  static const resource = 'resource';
  static const restraint = 'restraint';
  static const rigidity = 'rigidity';
  static const roots = 'roots';
  static const scarcity = 'scarcity';
  static const scatter = 'scatter';
  static const shadow = 'shadow';
  static const shame = 'shame';
  static const silence = 'silence';
  static const socialExpectation = 'socialExpectation';
  static const solitude = 'solitude';
  static const spark = 'spark';
  static const stability = 'stability';
  static const stagnation = 'stagnation';
  static const stewardship = 'stewardship';
  static const strain = 'strain';
  static const structure = 'structure';
  static const suppression = 'suppression';
  static const teaching = 'teaching';
  static const threshold = 'threshold';
  static const timing = 'timing';
  static const tradition = 'tradition';
  static const truth = 'truth';
  static const uncertainty = 'uncertainty';
  static const union = 'union';
  static const values = 'values';
  static const vitality = 'vitality';
  static const will = 'will';
  static const wisdom = 'wisdom';
  static const withdrawal = 'withdrawal';

  static const all = <String>{
    abundance,
    accountability,
    agency,
    anger,
    attachment,
    authority,
    avoidance,
    awakening,
    balance,
    belonging,
    bias,
    boast,
    bondage,
    boundary,
    burden,
    change,
    choice,
    clarity,
    closing,
    coldness,
    communication,
    compassion,
    completion,
    conformity,
    confusion,
    control,
    coordination,
    courage,
    craft,
    creation,
    curiosity,
    cycles,
    delay,
    denial,
    dependence,
    desire,
    despair,
    direction,
    discernment,
    discipline,
    discord,
    display,
    doubt,
    ending,
    enough,
    enthusiasm,
    envy,
    escape,
    exhaustion,
    externalDemand,
    fairness,
    fear,
    flow,
    focus,
    freedom,
    grief,
    guidance,
    harshSpeech,
    haste,
    holding,
    hope,
    illusion,
    imbalance,
    impatience,
    indecision,
    inquiry,
    instability,
    integration,
    internalStrain,
    intimacy,
    intuition,
    isolation,
    joy,
    judgment,
    labor,
    learning,
    listening,
    mastery,
    messenger,
    mindBurden,
    misdirection,
    momentum,
    mystery,
    notListening,
    nurture,
    opening,
    overflow,
    pause,
    perspective,
    pressure,
    principle,
    projection,
    receptivity,
    reciprocity,
    release,
    renewal,
    rescue,
    resistance,
    resource,
    restraint,
    rigidity,
    roots,
    scarcity,
    scatter,
    shadow,
    shame,
    silence,
    socialExpectation,
    solitude,
    spark,
    stability,
    stagnation,
    stewardship,
    strain,
    structure,
    suppression,
    teaching,
    threshold,
    timing,
    tradition,
    truth,
    uncertainty,
    union,
    values,
    vitality,
    will,
    wisdom,
    withdrawal,
  };
}
