import 'package:flutter/foundation.dart';
import 'package:lazy_games/services/supabase_service.dart';

/// Manages the 1-hour online multiplayer entitlement.
/// Stored in `multiplayer_entitlements` table in Supabase.
class EntitlementService {
  EntitlementService._();
  static final EntitlementService instance = EntitlementService._();

  /// Returns true if the current user has a valid (unexpired) entitlement.
  Future<bool> hasOnlineAccess() async {
    try {
      final uid = SupabaseService.instance.userId;
      if (uid == null) return false;

      final row = await SupabaseService.instance.client
          .from('multiplayer_entitlements')
          .select('valid_until')
          .eq('user_id', uid)
          .maybeSingle();

      if (row == null) return false;

      final validUntil = DateTime.parse(row['valid_until'] as String);
      return validUntil.isAfter(DateTime.now());
    } catch (e) {
      debugPrint('[EntitlementService] hasOnlineAccess error: $e');
      return false;
    }
  }

  /// Upserts (or extends) the user's entitlement to 1 hour from now.
  Future<void> unlockForOneHour() async {
    try {
      final uid = SupabaseService.instance.userId;
      if (uid == null) return;

      final validUntil = DateTime.now().add(const Duration(hours: 1));

      await SupabaseService.instance.client
          .from('multiplayer_entitlements')
          .upsert({
            'user_id': uid,
            'valid_until': validUntil.toIso8601String(),
          });
      debugPrint('[EntitlementService] Unlocked until $validUntil');
    } catch (e) {
      debugPrint('[EntitlementService] unlockForOneHour error: $e');
    }
  }
}
