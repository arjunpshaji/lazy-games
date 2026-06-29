import 'package:flutter/material.dart';
import 'package:lazy_games/providers/word_search_provider.dart';
import 'package:lazy_games/services/audio_service.dart';
import 'package:lazy_games/services/network_manager.dart';
import 'package:lazy_games/theme/app_theme.dart';
import 'package:lazy_games/widgets/game_shell.dart';
import 'package:lazy_games/widgets/lottie_loader.dart';
import 'package:provider/provider.dart';

class WordSearchScreen extends StatefulWidget {
  const WordSearchScreen({super.key});

  @override
  State<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends State<WordSearchScreen> {
  late NetworkManager _netManager;
  late WordSearchProvider _provider;

  int _startIndex = -1;
  int _currentIndex = -1;
  List<int> _selectedPath = [];
  final GlobalKey _gridKey = GlobalKey();
  bool _netInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _netManager = Provider.of<NetworkManager>(context, listen: false);
      _provider = Provider.of<WordSearchProvider>(context, listen: false);
      _netInitialized = true;

      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final isNetwork = args?['network'] ?? false;
      final role = _netManager.role == NetworkRole.host ? 'host' : 'client';

      if (isNetwork) {
        _netManager.onMessageReceived = (packet) {
          if (packet['type'] == 'ws_setup') {
            final grid = List<String>.from(packet['data']['grid']);
            final words = List<String>.from(packet['data']['words']);

            // Convert Map<String, dynamic> to Map<String, List<int>>
            final rawLocations =
                packet['data']['locations'] as Map<String, dynamic>;
            final Map<String, List<int>> locations = {};
            rawLocations.forEach((key, val) {
              locations[key] = List<int>.from(val);
            });

            _provider.setupNetworkBoard(grid, words, locations);
          } else if (packet['type'] == 'ws_found') {
            final word = packet['data']['word'] as String;
            final isPeerHost = packet['sender'] == 'host';
            final highlightColor = isPeerHost
                ? AppTheme.neonCyan
                : AppTheme.neonPink;
            _provider.markWordFound(word, highlightColor);
          } else if (packet['type'] == 'ws_reset') {
            _generateAndSyncNetworkGame();
          }
        };

        if (role == 'host') {
          _generateAndSyncNetworkGame();
        }
      } else {
        _provider.initBoard();
      }
    });
  }

  void _generateAndSyncNetworkGame() async {
    await _provider.initBoard();
    if (!mounted) return;
    _netManager.sendMessage('ws_setup', {
      'grid': _provider.grid,
      'words': _provider.words,
      'locations': _provider.wordLocations,
    });
  }

  @override
  void dispose() {
    if (_netInitialized) _netManager.onMessageReceived = null;
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_provider.isGameOver) return;

    final RenderBox renderBox =
        _gridKey.currentContext?.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;

    final index = _getIndexFromOffset(localPos, size);
    if (index != -1) {
      setState(() {
        _startIndex = index;
        _currentIndex = index;
        _selectedPath = [index];
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_startIndex == -1 || _provider.isGameOver) return;

    final RenderBox renderBox =
        _gridKey.currentContext?.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;

    final index = _getIndexFromOffset(localPos, size);
    if (index != -1 && index != _currentIndex) {
      setState(() {
        _currentIndex = index;
        _selectedPath = _getIndicesOnLine(_startIndex, _currentIndex);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_startIndex == -1 || _provider.isGameOver) return;

    // Check if the selected path matches any word
    final wordFound = _provider.checkSelection(_selectedPath);
    if (wordFound != null) {
      AudioService.instance.wordFound();
      final myColor = _netManager.role == NetworkRole.client
          ? AppTheme.neonPink
          : AppTheme.neonCyan;
      _provider.markWordFound(wordFound, myColor);

      if (_netManager.isConnected) {
        _netManager.sendMessage('ws_found', {'word': wordFound});
      }
    }

    setState(() {
      _startIndex = -1;
      _currentIndex = -1;
      _selectedPath = [];
    });
  }

  int _getIndexFromOffset(Offset localPos, Size size) {
    final cellW = size.width / 10;
    final cellH = size.height / 10;

    final col = (localPos.dx / cellW).floor();
    final row = (localPos.dy / cellH).floor();

    if (row >= 0 && row < 10 && col >= 0 && col < 10) {
      return row * 10 + col;
    }
    return -1;
  }

  List<int> _getIndicesOnLine(int start, int end) {
    final r1 = start ~/ 10;
    final c1 = start % 10;
    final r2 = end ~/ 10;
    final c2 = end % 10;

    int dr = r2 - r1;
    int dc = c2 - c1;

    final isRow = dr == 0;
    final isCol = dc == 0;
    final isDiag = dr.abs() == dc.abs();

    if (!isRow && !isCol && !isDiag) {
      return [start]; // Only highlight start if direction not locked
    }

    final stepR = dr == 0 ? 0 : dr.sign;
    final stepC = dc == 0 ? 0 : dc.sign;

    final List<int> path = [];
    int r = r1;
    int c = c1;
    while (true) {
      path.add(r * 10 + c);
      if (r == r2 && c == c2) break;
      r += stepR;
      c += stepC;
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WordSearchProvider>(context);
    final netManager = Provider.of<NetworkManager>(context);

    final isNetwork = netManager.isConnected;

    Widget statusWidget;
    if (provider.isGameOver) {
      statusWidget = Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: AppTheme.neonBorderDecoration(color: AppTheme.neonGreen),
        child: const Text(
          'ALL WORDS FOUND!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      );
    } else {
      statusWidget = Text(
        'Words: ${provider.foundWords.length} / ${provider.words.length} found',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      );
    }

    return GameShell(
      title: 'Word Search',
      rules:
          'Drag your finger horizontally, vertically, or diagonally to connect letters and highlight target words from the checklist below.',
      statusWidget: statusWidget,
      isWinner: provider.isGameOver,
      winSubtitle: 'ALL WORDS FOUND!',
      isInProgress: !provider.isGameOver && provider.foundWords.isNotEmpty,
      onReset:
          isNetwork &&
              netManager.role != NetworkRole.host &&
              provider.isGameOver
          ? null
          : () {
              if (isNetwork) {
                _generateAndSyncNetworkGame();
                netManager.sendMessage('ws_reset', {});
              } else {
                provider.initBoard();
              }
            },
      child: provider.isLoading
          ? const Center(child: LottieLoader(size: 220))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 10x10 Grid Board
                GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      key: _gridKey,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 10,
                            ),
                        itemCount: 100,
                        itemBuilder: (context, index) {
                          final letter = provider.grid[index];

                          // Check if cell is in current dragging path
                          final isCurrentSelection = _selectedPath.contains(
                            index,
                          );
                          // Check if cell is in a word already found
                          final isHighlighted = provider.highlightedCells
                              .containsKey(index);

                          Color cellColor = Colors.transparent;
                          if (isCurrentSelection) {
                            cellColor = AppTheme.neonOrange.withOpacity(0.3);
                          } else if (isHighlighted) {
                            cellColor = provider.highlightedCells[index]!
                                .withOpacity(0.25);
                          }

                          Color letterColor = Colors.white70;
                          if (isCurrentSelection) {
                            letterColor = AppTheme.neonOrange;
                          } else if (isHighlighted) {
                            letterColor = provider.highlightedCells[index]!;
                          }

                          return Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    (isCurrentSelection || isHighlighted)
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: letterColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Word Checklist Board
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WORD CHECKLIST:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: provider.words.map((word) {
                          final isFound = provider.foundWords.contains(word);
                          return Text(
                            word,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: isFound
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isFound
                                  ? AppTheme.textSecondary.withOpacity(0.5)
                                  : Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
