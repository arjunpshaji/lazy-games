import 'package:flutter/foundation.dart';
import 'package:lazy_games/services/app_config_service.dart';
import 'package:lazy_games/services/supabase_service.dart';

/// Manages the ad-free status for the current user.
///
/// Under the selected configuration model:
/// - If the global `adfree` config is enabled, everyone is treated as ad-free.
/// - If the global `adfree` config is disabled, only users who have `adfree = true`
///   in the `user_profiles` table are ad-free.
class AdFreeService {
  AdFreeService._();
  static final AdFreeService instance = AdFreeService._();

  bool _isUserAdFree = false;
  DateTime? _lastChecked;
  static const _cacheDuration = Duration(minutes: 5);

  /// Returns true if the user is currently ad-free.
  /// First checks the global config. If enabled, bypasses ads for all.
  /// If disabled, queries the `user_profiles` table for the user's status.
  Future<bool> isAdFree({bool forceRefresh = false}) async {
    // Refresh global config
    await AppConfigService.instance.fetchAndCacheConfig(forceRefresh: forceRefresh);

    // If global flag is enabled, everyone is ad-free
    if (AppConfigService.instance.isAdFreeFeatureEnabled) {
      return true;
    }

    // Otherwise, check the user's database status
    final now = DateTime.now();
    final isFresh =
        _lastChecked != null &&
        now.difference(_lastChecked!) < _cacheDuration;
    if (isFresh && !forceRefresh) {
      return _isUserAdFree;
    }

    try {
      final uid = SupabaseService.instance.userId;
      if (uid == null) {
        _isUserAdFree = false;
        return false;
      }

      final row = await SupabaseService.instance.client
          .from('user_profiles')
          .select('adfree')
          .eq('id', uid)
          .maybeSingle();

      if (row != null) {
        _isUserAdFree = row['adfree'] as bool? ?? false;
      } else {
        _isUserAdFree = false;
      }
      _lastChecked = now;
    } catch (e) {
      debugPrint('[AdFreeService] Check error (using cached): $e');
    }

    return _isUserAdFree;
  }

  /// Get the cached value of the user's local ad-free setting.
  /// (Does not perform network request, respects global flag if loaded).
  bool get isAdFreeCached {
    if (AppConfigService.instance.isAdFreeFeatureEnabled) {
      return true;
    }
    return _isUserAdFree;
  }
}
