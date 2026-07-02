import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lazy_games/services/ad_free_service.dart';

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
  
  // Future to track the active load progress
  Future<void>? _loadFuture;
  bool _isLoading = false;

  // ── Initialization ────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('[AdMobService] Initialized');
      // Pre-load the first ad immediately on startup
      loadRewardedAd();
    } catch (e) {
      debugPrint('[AdMobService] Init error: $e');
    }
  }

  // ── Ad Loading ────────────────────────────────────────────────────────────
  Future<void> loadRewardedAd() async {
    if (kIsWeb || !_initialized) return;
    if (AdFreeService.instance.isAdFreeCached) {
      debugPrint('[AdMobService] Skip loading: User is ad-free');
      return;
    }
    if (_rewardedAd != null) return; // Ad already loaded
    if (_isLoading) return; // Load already in progress

    _isLoading = true;
    final completer = Completer<void>();
    _loadFuture = completer.future;

    try {
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isLoading = false;
            _loadFuture = null;
            debugPrint('[AdMobService] Rewarded ad loaded');
            completer.complete();
          },
          onAdFailedToLoad: (error) {
            _rewardedAd = null;
            _isLoading = false;
            _loadFuture = null;
            debugPrint('[AdMobService] Load failed: ${error.message}');
            completer.complete();
            // Retry loading after a delay (e.g. 5 seconds) to avoid spamming requests
            Future.delayed(const Duration(seconds: 5), () {
              loadRewardedAd();
            });
          },
        ),
      );
    } catch (e) {
      _isLoading = false;
      _loadFuture = null;
      debugPrint('[AdMobService] loadRewardedAd error: $e');
      completer.complete();
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

    // Immediately trigger success callback if user is ad-free
    if (AdFreeService.instance.isAdFreeCached) {
      debugPrint('[AdMobService] Skip showing ad: User is ad-free');
      onRewarded();
      return;
    }

    // If no ad is loaded, wait for any active load to complete or start a new load
    if (_rewardedAd == null) {
      debugPrint('[AdMobService] No ad loaded — waiting for load completion');
      if (_loadFuture != null) {
        await _loadFuture;
      } else {
        await loadRewardedAd();
        if (_loadFuture != null) {
          await _loadFuture;
        }
      }
    }

    // Check again if we now have a loaded ad
    if (_rewardedAd == null) {
      debugPrint('[AdMobService] Ad still not available after waiting');
      onFailed?.call();
      return;
    }

    final adToShow = _rewardedAd!;
    _rewardedAd = null; // Clear immediately so we don't double show

    adToShow.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        debugPrint('[AdMobService] Ad dismissed — preloading next ad');
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        debugPrint('[AdMobService] Show failed: ${error.message} — preloading next ad');
        onFailed?.call();
        loadRewardedAd();
      },
    );

    try {
      await adToShow.show(
        onUserEarnedReward: (_, reward) {
          debugPrint('[AdMobService] Reward earned: ${reward.amount} ${reward.type}');
          onRewarded();
        },
      );
    } catch (e) {
      debugPrint('[AdMobService] Error showing ad: $e');
      adToShow.dispose();
      onFailed?.call();
      loadRewardedAd();
    }
  }
}
