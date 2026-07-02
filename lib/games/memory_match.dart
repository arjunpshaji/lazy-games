import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lazy_games/providers/memory_match_provider.dart';
import 'package:lazy_games/services/audio_service.dart';
import 'package:lazy_games/services/network_manager.dart';
import 'package:lazy_games/services/supabase_room_manager.dart';
import 'package:lazy_games/theme/app_theme.dart';
import 'package:lazy_games/widgets/game_shell.dart';
import 'package:lazy_games/widgets/glass_container.dart';
import 'package:provider/provider.dart';

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  late NetworkManager _netManager;
  late MemoryMatchProvider _provider;
  SupabaseRoomManager? _roomManager;
  bool _isOnline = false;

  // 18 emojis — enough for Easy (8), Medium (18) and Hard (16) groups.
  final List<String> _cardEmojis = [
    '🐶', // 0
    '✈️', // 1
    '🍕', // 2
    '🚀', // 3
    '🎨', // 4
    '🎵', // 5
    '🏆', // 6
    '🎮', // 7
    '🦁', // 8
    '🌈', // 9
    '⚡', // 10
    '🌸', // 11
    '🍄', // 12
    '🐉', // 13
    '💎', // 14
    '🔥', // 15
    '🧩', // 16
    '🪐', // 17
  ];

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _netManager = Provider.of<NetworkManager>(context, listen: false);
      _provider = Provider.of<MemoryMatchProvider>(context, listen: false);

      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final isNetwork = args?['network'] ?? false;
      _isOnline = args?['online'] ?? false;
      final isSolo = args?['isSolo'] ?? false;
      final difficulty = _difficultyFromArgs(args);
      final role = _netManager.role == NetworkRole.host ? 'host' : 'client';

      if (_isOnline) {
        _roomManager = Provider.of<SupabaseRoomManager>(context, listen: false);
        final onlineRole = _roomManager!.role == OnlineRole.host
            ? 'host'
            : 'client';
        _roomManager!.addMessageListener(_handleOnlineMessage);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (onlineRole == 'host') {
            _generateAndSyncOnlineGame(difficulty);
          } else {
            // Client checks if host has already generated the cards.
            final initialCards = _roomManager?.gameState?['cards'] as List?;
            if (initialCards != null && initialCards.isNotEmpty) {
              final cards = initialCards.cast<int>();
              _provider.setupGame(
                isNetwork: true,
                role: onlineRole,
                isSolo: false,
                preShuffledCards: cards,
              );
            } else {
              // Client waits for host to send the real card layout.
              _provider.setupGame(
                isNetwork: true,
                role: onlineRole,
                isSolo: false,
                preShuffledCards: [],
              );
            }
          }
        });
      } else if (isNetwork) {
        _netManager.onMessageReceived = (packet) {
          if (packet['type'] == 'memory_setup') {
            final cards = List<int>.from(packet['data']['cards']);
            _provider.setupGame(
              isNetwork: true,
              role: role,
              isSolo: false,
              preShuffledCards: cards,
            );
          } else if (packet['type'] == 'memory_tap') {
            final idx = packet['data']['index'] as int;
            _provider.handleNetworkTap(idx);
          } else if (packet['type'] == 'memory_reset') {
            _generateAndSyncNetworkGame(_provider.difficulty);
          }
        };

        if (role == 'host') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _generateAndSyncNetworkGame(difficulty);
          });
        }
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _provider.setupGame(
            isNetwork: false,
            role: role,
            isSolo: isSolo,
            difficulty: difficulty,
          );
        });
      }
    }
  }

  MemoryDifficulty _difficultyFromArgs(Map<String, dynamic>? args) {
    final raw = args?['difficulty'] as String?;
    switch (raw) {
      case 'medium':
        return MemoryDifficulty.medium;
      case 'hard':
      case 'high':
        return MemoryDifficulty.high;
      default:
        return MemoryDifficulty.easy;
    }
  }

  void _handleOnlineMessage(Map<String, dynamic> packet) {
    final onlineRole = _roomManager?.role == OnlineRole.host
        ? 'host'
        : 'client';
    if (packet['type'] == 'game_state_update') {
      final data = packet['data'] as Map<String, dynamic>;
      if (data['type'] == 'memory_online_reset') {
        if (onlineRole == 'host') {
          _generateAndSyncOnlineGame(_provider.difficulty);
        }
      } else if (data.containsKey('cards')) {
        // Only the guest should apply the host's card layout sync.
        if (onlineRole != 'host') {
          final cards = (data['cards'] as List).cast<int>();
          _provider.setupGame(
            isNetwork: true,
            role: onlineRole,
            isSolo: false,
            preShuffledCards: cards,
          );
        }
      } else if (data.containsKey('tapIndex')) {
        // Filter by the explicit sender role embedded at send-time.
        final senderRole = data['senderRole'] as String?;
        if (senderRole != null && senderRole != onlineRole) {
          final idx = data['tapIndex'] as int;
          _provider.handleNetworkTap(idx);
        }
      }
    }
  }

  void _generateAndSyncOnlineGame(MemoryDifficulty difficulty) {
    // Temporarily set difficulty so generateCards() uses the correct pool.
    _provider.setupGame(
      isNetwork: true,
      role: _roomManager?.role == OnlineRole.host ? 'host' : 'client',
      isSolo: false,
      difficulty: difficulty,
    );
    final cards = _provider.cards;
    _roomManager?.sendGameState({
      'cards': cards,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  void dispose() {
    _roomManager?.removeMessageListener(_handleOnlineMessage);
    _netManager.onMessageReceived = null;
    super.dispose();
  }

  void _generateAndSyncNetworkGame(MemoryDifficulty difficulty) {
    _provider.setupGame(
      isNetwork: true,
      role: 'host',
      isSolo: false,
      difficulty: difficulty,
    );
    final cards = _provider.cards;
    _netManager.sendMessage('memory_setup', {'cards': cards});
  }

  void _changeDifficulty(MemoryDifficulty diff) {
    if (_isOnline) {
      _generateAndSyncOnlineGame(diff);
    } else if (_provider.isNetworkGame) {
      _generateAndSyncNetworkGame(diff);
      _netManager.sendMessage('memory_reset', {});
    } else {
      _provider.setupGame(
        isNetwork: false,
        role: 'host',
        isSolo: _provider.isSolo,
        difficulty: diff,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MemoryMatchProvider>(context);
    final netManager = Provider.of<NetworkManager>(context);

    Widget statusWidget;
    if (provider.isGameOver) {
      String winnerText;
      if (provider.isSolo) {
        winnerText = "GAME COMPLETED!";
      } else if (provider.player1Score == provider.player2Score) {
        winnerText = "MATCH DRAW!";
      } else {
        final win1 = provider.player1Score > provider.player2Score;
        if (provider.isNetworkGame) {
          final iWon =
              (provider.myRole == 'host' && win1) ||
              (provider.myRole == 'client' && !win1);
          winnerText = iWon ? "YOU WIN!" : "OPPONENT WINS!";
        } else {
          winnerText = win1 ? "PLAYER 1 WINS!" : "PLAYER 2 WINS!";
        }
      }
      statusWidget = AnimatedNeonContainer(
        color: AppTheme.neonGreen,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: AppTheme.neonBorderDecoration(color: AppTheme.neonGreen),
        child: Text(
          winnerText,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      );
    } else {
      String turnText;
      final isMyTurn = provider.isMyTurn;
      if (provider.isSolo) {
        turnText = "SOLO PLAY";
      } else if (provider.isNetworkGame) {
        turnText = isMyTurn ? "YOUR TURN" : "OPPONENT'S TURN";
      } else {
        turnText = provider.isPlayer1Turn
            ? "PLAYER 1'S TURN"
            : "PLAYER 2'S TURN";
      }

      statusWidget = AnimatedNeonContainer(
        color: provider.isPlayer1Turn ? AppTheme.neonCyan : AppTheme.neonViolet,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: AppTheme.neonBorderDecoration(
          color: provider.isSolo
              ? AppTheme.neonPink
              : (provider.isPlayer1Turn
                    ? AppTheme.neonCyan
                    : AppTheme.neonViolet),
        ),
        child: Text(
          turnText,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      );
    }

    final hasWinner =
        provider.isGameOver && provider.player1Score != provider.player2Score;
    final win1 = provider.player1Score > provider.player2Score;
    final iWon =
        provider.isNetworkGame &&
        ((provider.myRole == 'host' && win1) ||
            (provider.myRole == 'client' && !win1));

    final isWinner = provider.isSolo
        ? provider.isGameOver
        : (provider.isNetworkGame ? (provider.isGameOver && iWon) : hasWinner);
    final winSubtitle = provider.isSolo
        ? 'Completed in ${provider.moves} moves!'
        : (provider.isNetworkGame
              ? 'YOU WON!'
              : (win1 ? 'PLAYER 1 WINS!' : 'PLAYER 2 WINS!'));

    // Difficulty badge label
    final diffLabel = provider.difficulty == MemoryDifficulty.high
        ? 'HIGH  7×7 · TRIPLETS'
        : provider.difficulty == MemoryDifficulty.medium
        ? 'MEDIUM  6×6'
        : 'EASY  4×4';
    final diffColor = provider.difficulty == MemoryDifficulty.high
        ? AppTheme.neonPink
        : provider.difficulty == MemoryDifficulty.medium
        ? AppTheme.neonOrange
        : AppTheme.neonGreen;

    final cols = provider.gridColumns;
    final total = provider.totalCards;

    return GameShell(
      title: 'Memory Match',
      rules:
          'Flip cards and find matching ${provider.difficulty == MemoryDifficulty.high ? 'triplets' : 'pairs'}. '
          'Find a match to earn another turn. Complete all groups to finish the game.',
      statusWidget: statusWidget,
      isWinner: isWinner,
      winSubtitle: winSubtitle,
      isOnlineGame: _isOnline,
      isInProgress:
          !provider.isGameOver &&
          (provider.flipped.contains(true) || provider.matched.contains(true)),
      onReset:
          provider.isNetworkGame &&
              provider.myRole != 'host' &&
              provider.isGameOver
          ? null
          : () {
              if (_isOnline) {
                _roomManager?.sendGameState({
                  'type': 'memory_online_reset',
                  'ts': DateTime.now().millisecondsSinceEpoch,
                });
                final onlineRole = _roomManager?.role == OnlineRole.host
                    ? 'host'
                    : 'client';
                if (onlineRole == 'host') {
                  _generateAndSyncOnlineGame(provider.difficulty);
                }
              } else if (provider.isNetworkGame) {
                _generateAndSyncNetworkGame(provider.difficulty);
                netManager.sendMessage('memory_reset', {});
              } else {
                provider.setupGame(
                  isNetwork: false,
                  role: 'host',
                  isSolo: provider.isSolo,
                  difficulty: provider.difficulty,
                );
              }
            },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Difficulty Selector / Badge
          if (provider.cards.isNotEmpty)
            if (!provider.isNetworkGame || provider.myRole == 'host')
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: MemoryDifficulty.values.map((diff) {
                    final active = provider.difficulty == diff;
                    final String label = diff == MemoryDifficulty.high
                        ? 'HIGH'
                        : diff == MemoryDifficulty.medium
                        ? 'MEDIUM'
                        : 'EASY';
                    final Color color = diff == MemoryDifficulty.high
                        ? AppTheme.neonPink
                        : diff == MemoryDifficulty.medium
                        ? AppTheme.neonOrange
                        : AppTheme.neonGreen;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: GestureDetector(
                        onTap: () => _changeDifficulty(diff),
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          borderRadius: 24,
                          borderColor: active
                              ? color.withOpacity(0.6)
                              : Colors.white.withOpacity(0.08),
                          fillColor: active
                              ? color.withOpacity(0.15)
                              : Colors.white.withOpacity(0.02),
                          child: Text(
                            label,
                            style: AppTheme.labelCaps.copyWith(
                              color: active
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontWeight: active
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 12,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: diffColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: diffColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  diffLabel,
                  style: TextStyle(
                    color: diffColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

          // Scores info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (provider.isSolo) ...[
                _buildPlayerScore(
                  "GROUPS FOUND",
                  provider.player1Score,
                  AppTheme.neonCyan,
                  true,
                ),
                _buildPlayerScore(
                  "TOTAL MOVES",
                  provider.moves,
                  AppTheme.neonPink,
                  false,
                ),
              ] else ...[
                _buildPlayerScore(
                  provider.isNetworkGame
                      ? (provider.myRole == 'host'
                            ? "YOU (P1)"
                            : "OPPONENT (P1)")
                      : "PLAYER 1",
                  provider.player1Score,
                  AppTheme.neonCyan,
                  provider.isPlayer1Turn,
                ),
                _buildPlayerScore(
                  provider.isNetworkGame
                      ? (provider.myRole == 'client'
                            ? "YOU (P2)"
                            : "OPPONENT (P2)")
                      : "PLAYER 2",
                  provider.player2Score,
                  AppTheme.neonViolet,
                  !provider.isPlayer1Turn,
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Card grid — dynamic columns and card count
          if (provider.cards.isNotEmpty)
            AspectRatio(
              aspectRatio: cols / ((total / cols).ceil()),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: cols > 5 ? 6 : 10,
                  mainAxisSpacing: cols > 5 ? 6 : 10,
                ),
                itemCount: total,
                itemBuilder: (context, index) {
                  final cardValue = provider.cards[index];

                  // Blank placeholder cell (hard mode, 49th card)
                  if (cardValue == -1) {
                    return const SizedBox.shrink();
                  }

                  final isFlipped = provider.flipped[index];
                  final isMatched = provider.matched[index];

                  return GestureDetector(
                    onTap: () async {
                      if (provider.isMyTurn &&
                          !isFlipped &&
                          !isMatched &&
                          !provider.isWaiting) {
                        AudioService.instance.cardFlip();
                        final success = await provider.handleCardTap(index);
                        if (success) {
                          if (_isOnline) {
                            final senderRole =
                                _roomManager?.role == OnlineRole.host
                                ? 'host'
                                : 'client';
                            _roomManager?.sendGameState({
                              'tapIndex': index,
                              'senderRole': senderRole,
                              'ts': DateTime.now().millisecondsSinceEpoch,
                            });
                          } else if (provider.isNetworkGame) {
                            netManager.sendMessage('memory_tap', {
                              'index': index,
                            });
                          }
                        }
                      }
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: _transitionBuilder,
                      layoutBuilder: (widget, list) =>
                          Stack(children: [widget!, ...list]),
                      child: isFlipped || isMatched
                          ? Container(
                              key: ValueKey('card-$index-front'),
                              decoration: BoxDecoration(
                                color: isMatched
                                    ? AppTheme.neonGreen.withOpacity(0.1)
                                    : AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(
                                  cols > 5 ? 8 : 12,
                                ),
                                border: Border.all(
                                  color: isMatched
                                      ? AppTheme.neonGreen
                                      : AppTheme.neonCyan,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                () {
                                  if (cardValue < 0 ||
                                      cardValue >= _cardEmojis.length) {
                                    return '❓';
                                  }
                                  return _cardEmojis[cardValue];
                                }(),
                                style: TextStyle(fontSize: cols > 5 ? 22 : 32),
                              ),
                            )
                          : Container(
                              key: ValueKey('card-$index-back'),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(
                                  cols > 5 ? 8 : 12,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.neonViolet.withOpacity(0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.help_outline,
                                color: Colors.white,
                                size: cols > 5 ? 18 : 28,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(
    String label,
    int score,
    Color color,
    bool isActive,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transitionBuilder(Widget child, Animation<double> animation) {
    final rotateAnim = Tween<double>(begin: pi, end: 0.0).animate(animation);
    return AnimatedBuilder(
      animation: rotateAnim,
      child: child,
      builder: (context, child) {
        final isUnder = (const ValueKey(true) != child?.key);
        var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
        tilt = isUnder ? -tilt : tilt;
        final value = isUnder
            ? min(rotateAnim.value, pi / 2)
            : rotateAnim.value;
        return Transform(
          transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
          alignment: Alignment.center,
          child: child,
        );
      },
    );
  }
}
