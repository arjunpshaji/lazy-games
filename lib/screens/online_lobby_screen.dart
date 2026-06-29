import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lazy_games/services/admob_service.dart';
import 'package:lazy_games/services/app_config_service.dart';
import 'package:lazy_games/services/entitlement_service.dart';
import 'package:lazy_games/services/supabase_room_manager.dart';
import 'package:lazy_games/theme/app_theme.dart';
import 'package:lazy_games/widgets/app_snackbar.dart';
import 'package:lazy_games/widgets/glass_button.dart';
import 'package:lazy_games/widgets/glass_container.dart';
import 'package:provider/provider.dart';

enum _LobbyPhase { loading, disabled, webUnsupported, adGate, lobby }

/// Bottom sheet for the online (internet) multiplayer lobby.
///
/// Flow:
/// 1. Kill-switch check → show maintenance if disabled
/// 2. Entitlement check → show ad gate if expired
/// 3. Create Room or Join Room UI
class OnlineLobbySheet extends StatefulWidget {
  final String gameId;
  final String gameTitle;
  final Color gameColor;
  final String gameRoute;

  const OnlineLobbySheet({
    super.key,
    required this.gameId,
    required this.gameTitle,
    required this.gameColor,
    required this.gameRoute,
  });

  @override
  State<OnlineLobbySheet> createState() => _OnlineLobbySheetState();
}

class _OnlineLobbySheetState extends State<OnlineLobbySheet> {
  late final TextEditingController _codeController;
  late final SupabaseRoomManager _roomManager;

  _LobbyPhase _phase = _LobbyPhase.loading;
  bool _showJoinInput = false;
  bool _navigated = false;
  bool _adLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _roomManager = context.read<SupabaseRoomManager>();
    _roomManager.addMessageListener(_onRoomMessage);
    _checkAccess();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _roomManager.removeMessageListener(_onRoomMessage);
    super.dispose();
  }

  void _onRoomMessage(Map<String, dynamic> packet) {
    if (!mounted) return;
    if (packet['type'] == 'room_connected' && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context); // close sheet
          Navigator.pushNamed(
            context,
            widget.gameRoute,
            arguments: {'online': true},
          );
        }
      });
    }
  }

  Future<void> _checkAccess() async {
    // Web: never allow (user chose option b)
    if (kIsWeb) {
      setState(() => _phase = _LobbyPhase.webUnsupported);
      return;
    }

    // Kill switch
    final enabled =
        await AppConfigService.instance.fetchAndCacheConfig(forceRefresh: true);
    if (!enabled) {
      setState(() => _phase = _LobbyPhase.disabled);
      return;
    }

    // Entitlement
    final hasAccess = await EntitlementService.instance.hasOnlineAccess();
    if (hasAccess) {
      _onEntitlementGranted();
    } else {
      setState(() => _phase = _LobbyPhase.adGate);
      // Pre-load ad in background
      if (AdMobService.instance.isSupported) {
        AdMobService.instance.loadRewardedAd();
      }
    }
  }

  void _onEntitlementGranted() {
    if (mounted) setState(() => _phase = _LobbyPhase.lobby);
  }

  Future<void> _watchAd() async {
    setState(() => _adLoading = true);
    await AdMobService.instance.showRewardedAd(
      onRewarded: () async {
        await EntitlementService.instance.unlockForOneHour();
        if (mounted) _onEntitlementGranted();
      },
      onFailed: () {
        if (mounted) {
          setState(() => _adLoading = false);
          AppSnackBar.showError(context, 'Ad not available. Please try again.');
        }
      },
    );
    if (mounted) setState(() => _adLoading = false);
  }

  Future<void> _createRoom() async {
    await _roomManager.createRoom(widget.gameId);
    if (_roomManager.lastError != null && mounted) {
      AppSnackBar.showError(context, _roomManager.lastError!);
    }
  }

  Future<void> _joinRoom(String code) async {
    if (code.trim().isEmpty) return;
    await _roomManager.joinRoom(code);
    if (_roomManager.lastError != null && mounted) {
      AppSnackBar.showError(context, _roomManager.lastError!);
    }
    // Navigation happens via _onRoomMessage when guest joins
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: GlassContainer(
        borderColor: widget.gameColor.withOpacity(0.45),
        fillColor: Colors.black.withOpacity(0.45),
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.gameColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.gameColor.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.public,
                        color: widget.gameColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Online: ${widget.gameTitle}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Text(
                            'Play with anyone, anywhere',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildBody(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _LobbyPhase.loading:
        return _buildLoading();
      case _LobbyPhase.disabled:
        return _buildDisabled();
      case _LobbyPhase.webUnsupported:
        return _buildWebUnsupported();
      case _LobbyPhase.adGate:
        return _buildAdGate();
      case _LobbyPhase.lobby:
        return _buildLobby();
    }
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: CircularProgressIndicator(color: AppTheme.neonCyan),
      ),
    );
  }

  Widget _buildDisabled() {
    return Column(
      children: [
        const Icon(Icons.wifi_off, color: AppTheme.neonPink, size: 48),
        const SizedBox(height: 16),
        Text(
          'Online Multiplayer Unavailable',
          style: AppTheme.headlineMd.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Online multiplayer is temporarily unavailable. Please try again later.',
          style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GlassButton(
          color: AppTheme.neonCyan,
          label: const Text('Close'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildWebUnsupported() {
    return Column(
      children: [
        const Icon(Icons.computer_outlined, color: AppTheme.neonPink, size: 48),
        const SizedBox(height: 16),
        Text(
          'Mobile Only',
          style: AppTheme.headlineMd.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Online multiplayer requires the mobile app on Android or iOS.',
          style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GlassButton(
          color: AppTheme.neonCyan,
          label: const Text('Close'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildAdGate() {
    return Column(
      children: [
        const Icon(Icons.lock_outline, color: AppTheme.neonViolet, size: 48),
        const SizedBox(height: 16),
        Text(
          'Unlock Online Play',
          style: AppTheme.headlineMd.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Watch a short ad to unlock online multiplayer for 1 hour.',
          style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GlassButton(
          color: AppTheme.neonViolet,
          isPrimary: true,
          icon: _adLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.play_circle_outline, size: 20),
          label: Text(_adLoading ? 'Loading Ad...' : 'Watch Ad & Unlock'),
          onPressed: _adLoading ? null : _watchAd,
        ),
        const SizedBox(height: 12),
        GlassButton(
          color: AppTheme.neonCyan,
          label: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildLobby() {
    return Consumer<SupabaseRoomManager>(
      builder: (context, rm, _) {
        // Waiting for guest to join
        if (rm.role == OnlineRole.host && rm.isSearching) {
          return _buildHostWaiting(rm);
        }

        // Guest searching / connecting
        if (rm.role == OnlineRole.guest && rm.isSearching) {
          return _buildGuestConnecting();
        }

        // Join input
        if (_showJoinInput) {
          return _buildJoinInput(rm);
        }

        // Default: Create or Join
        return _buildCreateJoin(rm);
      },
    );
  }

  Widget _buildCreateJoin(SupabaseRoomManager rm) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _createRoom,
                borderRadius: BorderRadius.circular(16),
                child: GlassContainer(
                  height: 100,
                  borderColor: AppTheme.neonCyan.withOpacity(0.4),
                  fillColor: AppTheme.neonCyan.withOpacity(0.08),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: AppTheme.neonCyan),
                      SizedBox(height: 8),
                      Text(
                        'CREATE ROOM',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _showJoinInput = true),
                borderRadius: BorderRadius.circular(16),
                child: GlassContainer(
                  height: 100,
                  borderColor: AppTheme.neonGreen.withOpacity(0.4),
                  fillColor: AppTheme.neonGreen.withOpacity(0.08),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.login_rounded,
                        color: AppTheme.neonGreen,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'JOIN ROOM',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHostWaiting(SupabaseRoomManager rm) {
    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(20),
          borderColor: AppTheme.neonCyan.withOpacity(0.25),
          fillColor: Colors.black12,
          child: Column(
            children: [
              const Icon(Icons.wifi_tethering, color: AppTheme.neonCyan, size: 36),
              const SizedBox(height: 12),
              const Text(
                'Room Created!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Share this code with your opponent:',
                style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Room code display
              GestureDetector(
                onTap: () => _copyCode(rm.roomCode ?? ''),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.neonCyan.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          rm.roomCode ?? '------',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: AppTheme.neonCyan,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.copy_rounded,
                          color: AppTheme.neonCyan,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.neonCyan,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Waiting for opponent to join...',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassButton(
          color: AppTheme.neonPink,
          label: const Text('Cancel'),
          onPressed: () async {
            await rm.leaveRoom();
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildGuestConnecting() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppTheme.neonGreen),
          SizedBox(height: 16),
          Text(
            'Connecting to room...',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinInput(SupabaseRoomManager rm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter Room Code',
          style: AppTheme.headlineMd.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codeController,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: 'ABCD12',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.25),
              letterSpacing: 4,
            ),
            counterText: '',
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppTheme.neonGreen.withOpacity(0.4),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppTheme.neonGreen),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            UpperCaseTextFormatter(),
          ],
          onSubmitted: (val) => _joinRoom(val),
        ),
        const SizedBox(height: 16),
        GlassButton(
          color: AppTheme.neonGreen,
          isPrimary: true,
          label: const Text('Join Game'),
          onPressed: () => _joinRoom(_codeController.text),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            setState(() => _showJoinInput = false);
            _codeController.clear();
          },
          child: const Text(
            'Back',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    AppSnackBar.showSuccess(context, 'Room code "$code" copied to clipboard!');
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
