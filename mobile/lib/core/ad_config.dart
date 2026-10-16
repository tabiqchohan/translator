/// AdMob configuration.
///
/// While developing we use Google's official TEST ad unit ids — they are safe
/// and will never get your AdMob account flagged. Replace them with your real
/// unit ids (from AdMob > Apps > Ad units) before going live.
class AdConfig {
  // ---- Google-provided test ids ----
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  // ---- TODO: replace with real ids before release ----
  static const String appId = testAppId;
  static const String bannerUnitId = testBanner;
  static const String interstitialUnitId = testInterstitial;
  static const String rewardedUnitId = testRewarded;

  /// Show an interstitial after every N successful translations.
  static const int interstitialEveryN = 4;

  /// Minimum gap between two interstitials (seconds).
  static const int interstitialCooldownSec = 60;
}
