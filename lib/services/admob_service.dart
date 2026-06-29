import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob rewarded ad service.
///
/// Android App ID: ca-app-pub-5331557332775401~5791903798
/// (configured in AndroidManifest.xml)
///
/// Uses Google's official test rewarded ad unit IDs during development.
/// Replace [_androidRewardedId] / [_iosRewardedId] with real unit IDs before release.
///
/// Platform support:
/// - Android ✅
/// - iOS ✅
/// - Web ❌ (isSupported = false, all calls are no-ops)
class AdMobService {
  AdMobService._();
  static final AdMobService instance = AdMobService._();

  // ── Ad Unit IDs ───────────────────────────────────────────────────────────
  // TODO: Replace with live rewarded ad unit IDs from your AdMob dashboard
  // before production release.
  static const _androidRewardedId = 'ca-app-pub-3940256099942544/5224354917'; // test
  static const _iosRewardedId = 'ca-app-pub-3940256099942544/1712485313';     // test

  static String get _rewardedAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) return _iosRewardedId;
    return _androidRewardedId;
  }

  bool get isSupported => !kIsWeb;

  bool _initialized = false;
  RewardedAd? _rewardedAd;

  // ── Initialization ────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('[AdMobService] Initialized');
    } catch (e) {
      debugPrint('[AdMobService] Init error: $e');
    }
  }

  // ── Ad Loading ────────────────────────────────────────────────────────────
  Future<void> loadRewardedAd() async {
    if (kIsWeb || !_initialized) return;
    try {
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            debugPrint('[AdMobService] Rewarded ad loaded');
          },
          onAdFailedToLoad: (error) {
            _rewardedAd = null;
            debugPrint('[AdMobService] Load failed: ${error.message}');
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdMobService] loadRewardedAd error: $e');
    }
  }

  // ── Ad Display ────────────────────────────────────────────────────────────
  /// Shows the loaded rewarded ad.
  /// [onRewarded] is called when the user earns the reward.
  /// [onFailed] is called if the ad cannot be shown.
  Future<void> showRewardedAd({
    required VoidCallback onRewarded,
    VoidCallback? onFailed,
  }) async {
    if (kIsWeb) {
      onFailed?.call();
      return;
    }
    if (_rewardedAd == null) {
      debugPrint('[AdMobService] No ad loaded — attempting reload');
      // Try a one-shot reload before failing
      await loadRewardedAd();
      if (_rewardedAd == null) {
        onFailed?.call();
        return;
      }
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        debugPrint('[AdMobService] Show failed: ${error.message}');
        onFailed?.call();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        _rewardedAd = null;
        debugPrint('[AdMobService] Reward earned: ${reward.amount} ${reward.type}');
        onRewarded();
      },
    );
  }
}
