/// AdMob configuration.
///
/// While developing we use Google's official TEST ad unit ids — they are safe
/// and will never get your AdMob account flagged. Replace them with your real
/// unit ids (from AdMob > Apps > Ad units) before going live.
class AdConfig {
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  // ---- Real AdMob ids (from admob file) ----
  static const String realAppId = 'ca-app-pub-1796422203430894~3151400144';
  static const String realBanner = 'ca-app-pub-1796422203430894/2925003581';
  static const String realInterstitial =
      'ca-app-pub-1796422203430894/3851072442';

  // ---- TODO: use real ids for production ----
  static const String appId = realAppId;
  static const String bannerUnitId = realBanner;
  static const String interstitialUnitId = realInterstitial;

  /// Show an interstitial after every N successful translations.
  static const int interstitialEveryN = 4;

  /// Minimum gap between two interstitials (seconds).
  static const int interstitialCooldownSec = 60;
}
