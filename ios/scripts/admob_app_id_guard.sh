#!/bin/sh
# Google Mobile Ads app id guard (Freemium Aşama 3A).
#
# GADApplicationIdentifier in Info.plist is $(ORACLY_ADMOB_APP_ID).
# Debug carries Google's official sample id (ios/Flutter/Debug.xcconfig).
# Any other configuration must carry the real AdMob app id: the Google
# Mobile Ads SDK stops an app whose id is missing or malformed, so a
# Release/Profile build without it is refused here instead of shipping a
# binary that cannot launch. The protected build writes the real id to the
# git-ignored ios/Flutter/AdMobApp.xcconfig (included by Release.xcconfig).
# Google's sample publisher is never accepted outside Debug.

case "${CONFIGURATION:-}" in
  Debug*) exit 0 ;;
esac

id="${ORACLY_ADMOB_APP_ID:-}"
if printf '%s' "$id" | grep -Eq '^ca-app-pub-[0-9]{16}~[0-9]{10}$'; then
  case "$id" in
    ca-app-pub-3940256099942544*) ;;
    *) exit 0 ;;
  esac
fi

echo "error: ${CONFIGURATION:-this} build needs the real AdMob iOS app id in ORACLY_ADMOB_APP_ID (ios/Flutter/AdMobApp.xcconfig). Ads stay BLOCKED until the AdMob app exists; Google's sample id is Debug-only." >&2
exit 1
