import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase wrapper.
/// Call [initialize] once from main() before runApp.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static const _url = 'https://nhxbeqmamxjvtgcvjjgk.supabase.co';
  static const _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5oeGJlcW1hbXhqdnRnY3ZqamdrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3MDc2NDgsImV4cCI6MjA5ODI4MzY0OH0.TXvEnbNVuGzgLyt0q4j8LoUzyvmzT5bykMtEzuABohc';

  static Future<void> initialize() async {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
    await instance._signInAnonymouslyIfNeeded();
  }

  SupabaseClient get client => Supabase.instance.client;

  String? get userId => client.auth.currentUser?.id;

  /// Ensures the user has a valid authenticated session, retrying anonymous sign-in if needed.
  /// Throws an [Exception] if sign-in fails.
  Future<String> ensureAuthenticated() async {
    final session = client.auth.currentSession;
    if (session != null) {
      return session.user.id;
    }
    
    // Attempt anonymous sign-in
    final response = await client.auth.signInAnonymously();
    final uid = response.user?.id;
    if (uid == null) {
      throw Exception('Failed to obtain a user ID. Please check your internet connection or verify that Anonymous Sign-in is enabled in your Supabase dashboard.');
    }
    return uid;
  }

  Future<void> _signInAnonymouslyIfNeeded() async {
    try {
      final uid = await ensureAuthenticated();
      debugPrint('[SupabaseService] Authenticated user: $uid');
    } catch (e) {
      debugPrint('[SupabaseService] Auth error: $e');
    }
  }
}
