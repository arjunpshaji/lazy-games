import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

enum OnlineRole { none, host, guest }

/// Online multiplayer transport layer backed by Supabase Realtime.
/// Drop-in counterpart to [NetworkManager] for the Supabase online path.
///
/// Lifecycle:
///   1. Host calls [createRoom] → room inserted, waits for guest.
///   2. Guest calls [joinRoom] → room updated, both clients navigate to game.
///   3. Either side calls [sendGameState] to broadcast moves.
///   4. Either side calls [leaveRoom] to set status = 'abandoned'.
class SupabaseRoomManager extends ChangeNotifier {
  OnlineRole _role = OnlineRole.none;
  String? _roomId;
  String? _roomCode;
  bool _isConnected = false; // true once host+guest are in the room
  bool _isSearching = false;
  String? _gameType;
  Map<String, dynamic>? _gameState;
  String? _lastError;

  RealtimeChannel? _channel;
  int _resubscribeAttempts = 0;
  static const int _maxResubscribeAttempts = 3;
  final List<void Function(Map<String, dynamic>)> _listeners = [];

  // ── Getters ──────────────────────────────────────────────────────────────
  OnlineRole get role => _role;
  String? get roomId => _roomId;
  String? get roomCode => _roomCode;
  bool get isConnected => _isConnected;
  bool get isSearching => _isSearching;
  String? get gameType => _gameType;
  Map<String, dynamic>? get gameState => _gameState;
  String? get lastError => _lastError;

  SupabaseClient get _db => SupabaseService.instance.client;

  // ── Listener management (mirrors NetworkManager) ─────────────────────────
  void addMessageListener(void Function(Map<String, dynamic>) listener) {
    _listeners.add(listener);
  }

  void removeMessageListener(void Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(Map<String, dynamic> packet) {
    for (final l in List.of(_listeners)) {
      try {
        l(packet);
      } catch (e) {
        debugPrint('[SupabaseRoomManager] listener error: $e');
      }
    }
  }

  // ── Room creation (HOST) ─────────────────────────────────────────────────
  Future<void> createRoom(String gameType) async {
    await _reset();
    _role = OnlineRole.host;
    _gameType = gameType;
    _isSearching = true;
    _lastError = null;
    notifyListeners();

    try {
      final uid = await SupabaseService.instance.ensureAuthenticated();
      final code = _generateCode();

      final row = await _db.from('game_rooms').insert({
        'room_code': code,
        'game_type': gameType,
        'host_id': uid,
        'status': 'waiting',
      }).select().single();

      _roomId = row['id'] as String;
      _roomCode = code;
      notifyListeners();

      _subscribeToRoom(_roomId!);
    } catch (e) {
      _lastError = e.toString().replaceAll('Exception: ', '');
      debugPrint('[SupabaseRoomManager] createRoom error: $e');
      await _reset();
    }
  }

  // ── Room joining (GUEST) ─────────────────────────────────────────────────
  Future<void> joinRoom(String code) async {
    await _reset();
    _role = OnlineRole.guest;
    _isSearching = true;
    _lastError = null;
    notifyListeners();

    try {
      final uid = await SupabaseService.instance.ensureAuthenticated();
      final trimmed = code.trim().toUpperCase();

      // Find the room
      final row = await _db
          .from('game_rooms')
          .select()
          .eq('room_code', trimmed)
          .eq('status', 'waiting')
          .maybeSingle();

      if (row == null) {
        _lastError = 'Room not found or already full.';
        await _reset();
        return;
      }

      final roomId = row['id'] as String;
      _gameType = row['game_type'] as String;

      // Join: set guest_id and flip to playing
      final updatedRow = await _db.from('game_rooms').update({
        'guest_id': uid,
        'status': 'playing',
      }).eq('id', roomId).select().single();

      _roomId = roomId;
      _roomCode = trimmed;
      _isConnected = true;
      _isSearching = false;
      _gameState = updatedRow['game_state'] as Map<String, dynamic>?;
      notifyListeners();

      _subscribeToRoom(roomId);
      
      // Dispatch connection event immediately on guest side
      _notifyListeners({'type': 'room_connected', 'data': updatedRow});
    } catch (e) {
      _lastError = e.toString().replaceAll('Exception: ', '');
      debugPrint('[SupabaseRoomManager] joinRoom error: $e');
      await _reset();
    }
  }

  // ── Refetch current game state from DB (used by guest after channel SUBSCRIBED) ──
  Future<void> refetchGameState() async {
    if (_roomId == null) return;
    try {
      final row = await _db
          .from('game_rooms')
          .select('game_state')
          .eq('id', _roomId!)
          .maybeSingle();
      if (row == null) return;
      final state = row['game_state'] as Map<String, dynamic>?;
      if (state != null) {
        _gameState = state;
        _notifyListeners({'type': 'game_state_update', 'data': state});
      }
    } catch (e) {
      debugPrint('[SupabaseRoomManager] refetchGameState error: $e');
    }
  }

  // ── Send game state (move broadcast) ─────────────────────────────────────
  Future<void> sendGameState(Map<String, dynamic> state) async {
    if (_roomId == null || !_isConnected) return;
    _gameState = state;
    try {
      await _db.from('game_rooms').update({
        'game_state': state,
      }).eq('id', _roomId!);
    } catch (e) {
      debugPrint('[SupabaseRoomManager] sendGameState error: $e');
    }
  }

  // ── Leave / abandon ───────────────────────────────────────────────────────
  Future<void> leaveRoom() async {
    if (_roomId != null) {
      try {
        await _db.from('game_rooms').update({
          'status': 'abandoned',
        }).eq('id', _roomId!);
      } catch (_) {}
    }
    await _reset();
  }

  // ── Realtime subscription ─────────────────────────────────────────────────
  void _subscribeToRoom(String roomId) {
    _channel = _db
        .channel('room-$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'game_rooms',
          callback: (payload) {
            final row = payload.newRecord;
            if (row['id'] == roomId) {
              debugPrint('[SupabaseRoomManager] Postgres update payload received: ${payload.newRecord}');
              _onRoomUpdate(payload);
            }
          },
        );
        
    _channel!.subscribe((status, [error]) {
      debugPrint('[SupabaseRoomManager] Realtime subscription status: $status');
      if (error != null) {
        debugPrint('[SupabaseRoomManager] Realtime subscription error: $error');
      }
      if (status == RealtimeSubscribeStatus.subscribed) {
        _resubscribeAttempts = 0;
        // Guest may have missed the host's initial game_state write while the
        // channel was still connecting. Refetch to guarantee the grid loads.
        if (_role == OnlineRole.guest) {
          refetchGameState();
        }
      } else if (status == RealtimeSubscribeStatus.timedOut) {
        // Timeout is transient — attempt to re-subscribe rather than abandoning.
        if (_resubscribeAttempts < _maxResubscribeAttempts && _roomId != null) {
          _resubscribeAttempts++;
          debugPrint('[SupabaseRoomManager] Channel timed out, retrying ($_resubscribeAttempts/$_maxResubscribeAttempts)...');
          try { _channel?.unsubscribe(); } catch (_) {}
          _channel = null;
          Future.delayed(const Duration(seconds: 2), () {
            if (_roomId != null) _subscribeToRoom(_roomId!);
          });
        } else {
          debugPrint('[SupabaseRoomManager] Max resubscribe attempts reached, abandoning.');
          _notifyListeners({'type': 'room_abandoned', 'data': {}});
        }
      } else if (status == RealtimeSubscribeStatus.channelError) {
        debugPrint('[SupabaseRoomManager] Channel error, notifying listeners of room abandonment.');
        _notifyListeners({'type': 'room_abandoned', 'data': {}});
      }
    });
  }

  void _onRoomUpdate(PostgresChangePayload payload) {
    final row = payload.newRecord;
    final status = row['status'] as String?;

    // Guest joined → both sides become connected
    if (status == 'playing' && !_isConnected) {
      _isConnected = true;
      _isSearching = false;
      notifyListeners();

      // Notify game screens via generic packet
      _notifyListeners({'type': 'room_connected', 'data': row});
    }

    if (status == 'abandoned') {
      _notifyListeners({'type': 'room_abandoned', 'data': {}});
      _reset();
      return;
    }

    // Forward game state changes to game screens
    final newState = row['game_state'] as Map<String, dynamic>?;
    if (newState != null && newState != _gameState) {
      _gameState = newState;
      // Only dispatch to the side that didn't send it (i.e., if it's a remote move).
      // Game screens decide whether to apply based on packet type they set.
      _notifyListeners({'type': 'game_state_update', 'data': newState});
    }
  }

  // ── Internal helpers ──────────────────────────────────────────────────────
  Future<void> _reset() async {
    _isConnected = false;
    _isSearching = false;
    _role = OnlineRole.none;
    _roomId = null;
    _roomCode = null;
    _gameState = null;
    _gameType = null;
    _resubscribeAttempts = 0;

    try {
      await _channel?.unsubscribe();
    } catch (_) {}
    _channel = null;

    notifyListeners();
  }

  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  @override
  void dispose() {
    _reset();
    super.dispose();
  }
}
