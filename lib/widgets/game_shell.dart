import 'package:flutter/material.dart';
import 'package:lazy_games/services/audio_service.dart';
import 'package:lazy_games/services/network_manager.dart';
import 'package:lazy_games/services/supabase_room_manager.dart';
import 'package:lazy_games/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'liquid_glass_background.dart';
import 'glass_button.dart';
import 'glass_container.dart';
import 'win_overlay.dart';
import 'lottie_loader.dart';

class GameShell extends StatefulWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final String rules;
  final Widget? statusWidget;
  final VoidCallback? onReset;
  final bool isWinner;
  final String? winTitle;
  final String? winSubtitle;
  final bool isInProgress;
  /// Set to true when the game is an online (Supabase) session.
  final bool isOnlineGame;

  const GameShell({
    super.key,
    required this.title,
    required this.child,
    required this.rules,
    this.actions,
    this.statusWidget,
    this.onReset,
    this.isWinner = false,
    this.winTitle,
    this.winSubtitle,
    this.isInProgress = true,
    this.isOnlineGame = false,
  });

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> {
  bool _didFireWinSound = false;
  bool _isWaitingForApproval = false;
  BuildContext? _activeDialogContext;
  late SupabaseRoomManager _roomManager;
  late NetworkManager _netManager;

  @override
  void initState() {
    super.initState();
    _netManager = Provider.of<NetworkManager>(context, listen: false);
    _netManager.addMessageListener(_handleNetworkMessage);

    _roomManager = Provider.of<SupabaseRoomManager>(context, listen: false);
    if (widget.isOnlineGame) {
      _roomManager.addMessageListener(_handleOnlineMessage);
    }
  }

  @override
  void dispose() {
    _netManager.removeMessageListener(_handleNetworkMessage);
    if (widget.isOnlineGame) {
      _roomManager.removeMessageListener(_handleOnlineMessage);
      if (_roomManager.isConnected) {
        _roomManager.leaveRoom();
      }
    }
    _dismissActiveDialog();
    super.dispose();
  }

  void _handleNetworkMessage(Map<String, dynamic> packet) {
    if (!mounted) return;
    final type = packet['type'];
    if (type == 'reload_request') {
      if (_isWaitingForApproval) {
        // Simultaneous request: auto-approve
        _dismissActiveDialog();
        _isWaitingForApproval = false;
        _netManager.sendMessage('reload_approve', {});
        widget.onReset?.call();
      } else {
        _showApprovalPromptDialog(_netManager);
      }
    } else if (type == 'reload_approve') {
      if (_isWaitingForApproval) {
        _dismissActiveDialog();
        _isWaitingForApproval = false;
        widget.onReset?.call();
      }
    } else if (type == 'reload_decline') {
      if (_isWaitingForApproval) {
        _dismissActiveDialog();
        _isWaitingForApproval = false;
        _showDeclinedDialog();
      }
    } else if (type == 'reload_cancel') {
      _dismissActiveDialog();
    }
  }

  void _handleOnlineMessage(Map<String, dynamic> packet) {
    if (!mounted) return;
    if (packet['type'] == 'room_abandoned') {
      _showConnectionClosedDialog();
      return;
    }
    if (packet['type'] == 'game_state_update') {
      final data = packet['data'] as Map<String, dynamic>;
      final type = data['type'];
      final sender = data['sender'] as String?;
      final myRoleStr = _roomManager.role == OnlineRole.host ? 'host' : 'guest';

      // Ignore our own database update broadcasts
      if (sender == myRoleStr) return;

      if (type == 'reload_request') {
        if (_isWaitingForApproval) {
          // Simultaneous requests: auto-approve
          _dismissActiveDialog();
          _isWaitingForApproval = false;
          _roomManager.sendGameState({
            'type': 'reload_approve',
            'sender': myRoleStr,
          });
          if (_roomManager.role == OnlineRole.host) {
            widget.onReset?.call();
          }
        } else {
          _showOnlineApprovalPromptDialog();
        }
      } else if (type == 'reload_approve') {
        if (_isWaitingForApproval) {
          _dismissActiveDialog();
          _isWaitingForApproval = false;
          if (_roomManager.role == OnlineRole.host) {
            widget.onReset?.call();
          }
        }
      } else if (type == 'reload_decline') {
        if (_isWaitingForApproval) {
          _dismissActiveDialog();
          _isWaitingForApproval = false;
          _showDeclinedDialog();
        }
      } else if (type == 'reload_cancel') {
        _dismissActiveDialog();
      }
    }
  }

  void _handleResetClick() {
    if (widget.isOnlineGame) {
      if (!_roomManager.isConnected) {
        widget.onReset?.call();
        return;
      }
      _initiateOnlineReloadFlow();
      return;
    }
    final netManager = Provider.of<NetworkManager>(context, listen: false);
    if (!netManager.isConnected || !widget.isInProgress) {
      widget.onReset?.call();
      return;
    }
    _initiateReloadFlow(netManager);
  }

  void _initiateOnlineReloadFlow() {
    _isWaitingForApproval = true;
    _showOnlineWaitingDialog();
    final myRoleStr = _roomManager.role == OnlineRole.host ? 'host' : 'guest';
    _roomManager.sendGameState({
      'type': 'reload_request',
      'sender': myRoleStr,
    });
  }

  void _initiateReloadFlow(NetworkManager netManager) {
    _isWaitingForApproval = true;
    _showWaitingDialog(netManager);
    netManager.sendMessage('reload_request', {});
  }

  void _showWaitingDialog(NetworkManager netManager) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFF1F1145).withOpacity(0.40),
      builder: (dialogContext) {
        _activeDialogContext = dialogContext;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GlassContainer(
                  elevation: GlassElevation.high,
                  borderColor: AppTheme.neonCyan.withOpacity(0.35),
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Restart Request Sent',
                        style: AppTheme.headlineMd.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      const Center(child: LottieLoader(size: 220)),
                      const SizedBox(height: 20),
                      Text(
                        'Waiting for opponent to approve...',
                        style: AppTheme.bodyMd.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      GlassButton(
                        isFullWidth: true,
                        color: AppTheme.neonPink,
                        label: const Text('Cancel Request'),
                        onPressed: () {
                          _dismissActiveDialog();
                          netManager.sendMessage('reload_cancel', {});
                          _isWaitingForApproval = false;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showApprovalPromptDialog(NetworkManager netManager) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFF1F1145).withOpacity(0.40),
      builder: (dialogContext) {
        _activeDialogContext = dialogContext;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GlassContainer(
                  elevation: GlassElevation.high,
                  borderColor: AppTheme.neonPink.withOpacity(0.35),
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Restart Game?',
                        style: AppTheme.headlineMd.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your opponent wants to restart the game. Do you approve?',
                        style: AppTheme.bodyMd.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: GlassButton(
                              isFullWidth: true,
                              color: AppTheme.neonPink,
                              label: const Text('Decline'),
                              onPressed: () {
                                _dismissActiveDialog();
                                netManager.sendMessage('reload_decline', {});
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassButton(
                              isFullWidth: true,
                              color: AppTheme.neonGreen,
                              label: const Text('Approve'),
                              onPressed: () {
                                _dismissActiveDialog();
                                netManager.sendMessage('reload_approve', {});
                                if (netManager.role == NetworkRole.host) {
                                  widget.onReset?.call();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showOnlineWaitingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFF1F1145).withOpacity(0.40),
      builder: (dialogContext) {
        _activeDialogContext = dialogContext;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GlassContainer(
                  elevation: GlassElevation.high,
                  borderColor: AppTheme.neonCyan.withOpacity(0.35),
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Restart Request Sent',
                        style: AppTheme.headlineMd.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      const Center(child: LottieLoader(size: 220)),
                      const SizedBox(height: 20),
                      Text(
                        'Waiting for opponent to approve...',
                        style: AppTheme.bodyMd.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      GlassButton(
                        isFullWidth: true,
                        color: AppTheme.neonPink,
                        label: const Text('Cancel Request'),
                        onPressed: () {
                          _dismissActiveDialog();
                          final myRoleStr = _roomManager.role == OnlineRole.host ? 'host' : 'guest';
                          _roomManager.sendGameState({
                            'type': 'reload_cancel',
                            'sender': myRoleStr,
                          });
                          _isWaitingForApproval = false;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showOnlineApprovalPromptDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFF1F1145).withOpacity(0.40),
      builder: (dialogContext) {
        _activeDialogContext = dialogContext;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GlassContainer(
                  elevation: GlassElevation.high,
                  borderColor: AppTheme.neonPink.withOpacity(0.35),
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Restart Game?',
                        style: AppTheme.headlineMd.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your opponent wants to restart the game. Do you approve?',
                        style: AppTheme.bodyMd.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: GlassButton(
                              isFullWidth: true,
                              color: AppTheme.neonPink,
                              label: const Text('Decline'),
                              onPressed: () {
                                _dismissActiveDialog();
                                final myRoleStr = _roomManager.role == OnlineRole.host ? 'host' : 'guest';
                                _roomManager.sendGameState({
                                  'type': 'reload_decline',
                                  'sender': myRoleStr,
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassButton(
                              isFullWidth: true,
                              color: AppTheme.neonGreen,
                              label: const Text('Approve'),
                              onPressed: () {
                                _dismissActiveDialog();
                                final myRoleStr = _roomManager.role == OnlineRole.host ? 'host' : 'guest';
                                _roomManager.sendGameState({
                                  'type': 'reload_approve',
                                  'sender': myRoleStr,
                                });
                                if (_roomManager.role == OnlineRole.host) {
                                  widget.onReset?.call();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showConnectionClosedDialog() {
    _dismissActiveDialog();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFF1F1145).withOpacity(0.60),
      builder: (dialogContext) {
        _activeDialogContext = dialogContext;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GlassContainer(
                  elevation: GlassElevation.high,
                  borderColor: AppTheme.neonPink.withOpacity(0.35),
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Connection Closed',
                        style: AppTheme.headlineMd.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your opponent has left the room or disconnected.',
                        style: AppTheme.bodyMd.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      GlassButton(
                        isFullWidth: true,
                        color: AppTheme.neonPink,
                        label: const Text('Return to Lobby'),
                        onPressed: () {
                          _dismissActiveDialog();
                          Navigator.of(context).pop(); // Pops the game screen
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeclinedDialog() {
    showDialog(
      context: context,
      barrierColor: const Color(0xFF1F1145).withOpacity(0.40),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GlassContainer(
                  elevation: GlassElevation.high,
                  borderColor: AppTheme.neonPink.withOpacity(0.35),
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Request Declined',
                        style: AppTheme.headlineMd.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your opponent declined the restart request.',
                        style: AppTheme.bodyMd.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      GlassButton(
                        color: AppTheme.neonCyan,
                        label: const Text('OK'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _dismissActiveDialog() {
    if (_activeDialogContext != null && _activeDialogContext!.mounted) {
      Navigator.of(_activeDialogContext!).pop();
    }
    _activeDialogContext = null;
  }

  @override
  void didUpdateWidget(covariant GameShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fire win sound exactly once when isWinner transitions to true.
    if (widget.isWinner && !oldWidget.isWinner && !_didFireWinSound) {
      _didFireWinSound = true;
      AudioService.instance.win();
    }
    // Reset flag when game resets.
    if (!widget.isWinner && oldWidget.isWinner) {
      _didFireWinSound = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final netManager = Provider.of<NetworkManager>(context);
    final roomManager = Provider.of<SupabaseRoomManager>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.neonCyan),
          onPressed: () async {
            // ── Online (Supabase) leave ──────────────────────────────────
            if (widget.isOnlineGame) {
              final roomManager = Provider.of<SupabaseRoomManager>(
                context,
                listen: false,
              );
              final leave = await showDialog<bool>(
                    context: context,
                    barrierColor: const Color(0xFF1F1145).withOpacity(0.40),
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      child: Center(
                        child: SingleChildScrollView(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: GlassContainer(
                              elevation: GlassElevation.high,
                              borderColor: AppTheme.neonPink.withOpacity(0.35),
                              borderRadius: 24,
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Leave Online Match?',
                                    style: AppTheme.headlineMd.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'This will abandon the online game session.',
                                    style: AppTheme.bodyMd.copyWith(
                                      color: AppTheme.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text(
                                          'Cancel',
                                          style: AppTheme.bodyMd.copyWith(
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      GlassButton(
                                        isFullWidth: false,
                                        color: AppTheme.neonPink,
                                        label: const Text('Leave'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ) ??
                  false;
              if (leave) {
                await roomManager.leaveRoom();
                if (context.mounted) Navigator.of(context).pop();
              }
              return;
            }
            // ── LAN leave ───────────────────────────────────────────────
            if (netManager.isConnected) {
              final leave =
                  await showDialog<bool>(
                    context: context,
                    barrierColor: const Color(0xFF1F1145).withOpacity(0.40),
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      child: Center(
                        child: SingleChildScrollView(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: GlassContainer(
                              elevation: GlassElevation.high,
                              borderColor: AppTheme.neonPink.withOpacity(0.35),
                              borderRadius: 24, // rounded-xl (24px)
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Leave Match?',
                                    style: AppTheme.headlineMd.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'This will disconnect the local network game session.',
                                    style: AppTheme.bodyMd.copyWith(
                                      color: AppTheme.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text(
                                          'Cancel',
                                          style: AppTheme.bodyMd.copyWith(
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      GlassButton(
                                        isFullWidth: false,
                                        color: AppTheme.neonPink,
                                        label: const Text('Leave'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ) ??
                  false;
              if (leave) {
                await netManager.stop();
                if (context.mounted) Navigator.of(context).pop();
              }
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 22,
            letterSpacing: 2,
            shadows: [const Shadow(color: AppTheme.neonCyan, blurRadius: 10)],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.neonGreen),
            onPressed: () => _showRules(context),
          ),
          if (widget.onReset != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.neonCyan),
              onPressed: _handleResetClick,
            ),
          ...?widget.actions,
        ],
      ),
      body: Stack(
        children: [
          const LiquidGlassBackground(),
          SafeArea(
            child: Column(
              children: [
                // Network Indicator Bar
                if (widget.isOnlineGame)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 16,
                    ),
                    color: AppTheme.neonViolet.withOpacity(0.15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.public,
                          size: 16,
                          color: AppTheme.neonViolet,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Online — ${roomManager.role == OnlineRole.host ? "Host" : "Guest"}',
                          style: const TextStyle(
                            color: AppTheme.neonViolet,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (netManager.isConnected)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 16,
                    ),
                    color: AppTheme.neonGreen.withOpacity(0.15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi,
                          size: 16,
                          color: AppTheme.neonGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Connected as ${netManager.role == NetworkRole.host ? "Host" : "Client"}',
                          style: const TextStyle(
                            color: AppTheme.neonGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Status area
                if (widget.statusWidget != null)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: widget.statusWidget!,
                  ),

                // Main game area
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          WinOverlay(
            isVisible: widget.isWinner,
            title: widget.winTitle ?? 'CONGRATULATIONS!',
            subtitle: widget.winSubtitle ?? 'YOU WON!',
            isOnlineOrNetworkGuest:
                (widget.isOnlineGame &&
                    roomManager.role == OnlineRole.guest) ||
                (_netManager.isConnected &&
                    _netManager.role == NetworkRole.client),
            onPlayAgain: widget.onReset != null ? _handleResetClick : null,
          ),
        ],
      ),
    );
  }

  void _showRules(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: const Color(0xFF1F1145).withOpacity(0.40),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassContainer(
          elevation: GlassElevation.high,
          borderColor: AppTheme.neonGreen.withOpacity(0.35),
          borderRadius: 24, // rounded-xl (24px)
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.menu_book,
                    color: AppTheme.neonGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'How to Play: ${widget.title}',
                      style: AppTheme.headlineMd.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    widget.rules,
                    style: AppTheme.bodyMd.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GlassButton(
                color: AppTheme.neonCyan,
                label: const Text('Got it!'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
