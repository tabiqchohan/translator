import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/ad_config.dart';

/// Central AdMob helper. Initialised once at app start.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  int _translationCount = 0;
  DateTime? _lastInterstitialAt;

  /// Whether ads should be suppressed (e.g. Pro users). Phase B will set this.
  bool adFree = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await MobileAds.instance.initialize();
      _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      debugPrint('AdService init error: $e');
    }
  }

  // ---------------------------------------------------------------- interstitial
  void _loadInterstitial() {
    if (adFree) return;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (err) {
          _interstitial = null;
          debugPrint('Interstitial failed to load: $err');
        },
      ),
    );
  }

  /// Call once after a successful translation.
  void onTranslationSuccess() {
    _translationCount++;
    if (_translationCount % AdConfig.interstitialEveryN != 0) return;
    _showInterstitial();
  }

  void _showInterstitial() {
    if (adFree) return;
    final now = DateTime.now();
    if (_lastInterstitialAt != null &&
        now.difference(_lastInterstitialAt!).inSeconds <
            AdConfig.interstitialCooldownSec) {
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    _lastInterstitialAt = now;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }

  // -------------------------------------------------------------------- rewarded
  void _loadRewarded() {
    if (adFree) return;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (err) {
          _rewarded = null;
          debugPrint('Rewarded failed to load: $err');
        },
      ),
    );
  }

  bool get rewardedReady => _rewarded != null;

  /// Shows a rewarded ad. [onReward] fires only after the user earns it.
  void showRewarded({required VoidCallback onReward}) {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return;
    }
    _rewarded = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        _loadRewarded();
      },
    );
    ad.show(onUserEarnedReward: (_, __) => onReward());
  }
}
