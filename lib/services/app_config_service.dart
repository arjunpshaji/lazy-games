import 'package:flutter/foundation.dart';
import 'package:lazy_games/services/supabase_service.dart';

/// Fetches and caches the remote feature-flag / kill-switch config from
/// the `app_config` Supabase table.
///
/// Toggle online multiplayer off instantly without a new release:
///   Supabase Dashboard → Table Editor → app_config
///   Set value = {"enabled": false}
class AppConfigService {
  AppConfigService._();
  static final AppConfigService instance = AppConfigService._();

  bool _onlineMultiplayerEnabled = true; // optimistic default
  DateTime? _lastFetched;
  static const _cacheDuration = Duration(minutes: 30);

  bool get isOnlineMultiplayerEnabled => _onlineMultiplayerEnabled;

  /// Refresh on app startup, every 30 min, and when the Online lobby opens.
  Future<bool> fetchAndCacheConfig({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final isFresh =
        _lastFetched != null &&
        now.difference(_lastFetched!) < _cacheDuration;
    if (isFresh && !forceRefresh) return _onlineMultiplayerEnabled;

    try {
      final row = await SupabaseService.instance.client
          .from('app_config')
          .select('value')
          .eq('key', 'online_multiplayer')
          .maybeSingle();

      if (row != null) {
        _onlineMultiplayerEnabled =
            (row['value'] as Map<String, dynamic>)['enabled'] as bool? ?? true;
      }
      _lastFetched = now;
    } catch (e) {
      debugPrint('[AppConfigService] fetch error (using cached): $e');
    }

    return _onlineMultiplayerEnabled;
  }
}
