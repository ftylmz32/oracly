/// Client-owned Coffee V3 capture contract. Sent on operation creation as
/// `coffeeCaptureContract` and persisted in the local V3 record as its
/// version/integrity marker. Never inferred from a slot count.
library;

const String coffeeV3CaptureContract = 'four_view_v3';

/// V3 `sourceRequestId` prefix — distinct from V2's `coffee-v2-` and valid
/// under the backend `^[A-Za-z0-9._:-]{8,64}$` contract.
const String coffeeV3SourceRequestPrefix = 'coffee-v3-';
