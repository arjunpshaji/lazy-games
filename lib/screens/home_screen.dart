import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lazy_games/services/network_manager.dart';
import 'package:lazy_games/theme/app_theme.dart';
import 'package:lazy_games/utils/responsive_layout.dart';
import 'package:lazy_games/widgets/app_snackbar.dart';
import 'package:lazy_games/widgets/game_visual.dart';
import 'package:lazy_games/widgets/glass_button.dart';
import 'package:lazy_games/widgets/glass_container.dart';
import 'package:lazy_games/widgets/liquid_glass_background.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class GameInfo {
  final String id;
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
  final bool supportsSinglePlayer;
  final bool supportsMultiplayer;

  GameInfo({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
    required this.supportsSinglePlayer,
    required this.supportsMultiplayer,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late AnimationController _bounceController;
  late ScrollController _scrollController;
  bool _showScrollIndicator = false;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Logic', 'Classic', 'Strategy'];

  // Cached card animations — built once in initState, not on every build tick.
  late List<Animation<double>> _cardAnims;

  // Cached text style — GoogleFonts.getFont() allocates on every call.
  late TextStyle _caveatStyle;

  final List<GameInfo> _games = [
    GameInfo(
      id: 'tic_tac_toe',
      title: 'Tic Tac Toe',
      category: 'Classic',
      description: 'Align three symbols in a grid to claim victory.',
      icon: Icons.grid_3x3,
      color: AppTheme.neonCyan,
      route: '/tic_tac_toe',
      supportsSinglePlayer: false,
      supportsMultiplayer: true,
    ),
    GameInfo(
      id: 'sudoku',
      title: 'Sudoku',
      category: 'Logic',
      description: 'Fill the 9x9 grid so every row, col, & box contains 1-9.',
      icon: Icons.grid_on,
      color: AppTheme.neonGreen,
      route: '/sudoku',
      supportsSinglePlayer: true,
      supportsMultiplayer: false,
    ),
    GameInfo(
      id: '2048',
      title: '2048',
      category: 'Classic',
      description: 'Slide matching tiles to double values & hit the 2048 tile.',
      icon: Icons.grid_view,
      color: AppTheme.neonOrange,
      route: '/2048',
      supportsSinglePlayer: true,
      supportsMultiplayer: false,
    ),
    GameInfo(
      id: 'memory_match',
      title: 'Memory Match',
      category: 'Classic',
      description: 'Flip cards and find all identical pairs in minimal moves.',
      icon: Icons.style,
      color: AppTheme.neonPink,
      route: '/memory_match',
      supportsSinglePlayer: true,
      supportsMultiplayer: true,
    ),
    GameInfo(
      id: 'connect_four',
      title: 'Connect Four',
      category: 'Strategy',
      description: 'Drop discs down columns. Align four in a row to win.',
      icon: Icons.view_column,
      color: AppTheme.neonCyan,
      route: '/connect_four',
      supportsSinglePlayer: false,
      supportsMultiplayer: true,
    ),
    GameInfo(
      id: 'minesweeper',
      title: 'Minesweeper',
      category: 'Logic',
      description: 'Reveal cells without detonating hidden mines.',
      icon: Icons.dangerous,
      color: AppTheme.neonPink,
      route: '/minesweeper',
      supportsSinglePlayer: true,
      supportsMultiplayer: false,
    ),
    GameInfo(
      id: 'word_search',
      title: 'Word Search',
      category: 'Logic',
      description: 'Locate all hidden words in a grid of random letters.',
      icon: Icons.translate,
      color: AppTheme.neonGreen,
      route: '/word_search',
      supportsSinglePlayer: true,
      supportsMultiplayer: false,
    ),
    GameInfo(
      id: 'sliding_puzzle',
      title: 'Sliding Puzzle',
      category: 'Classic',
      description: 'Slide numbered tiles to organize them back in order.',
      icon: Icons.extension,
      color: AppTheme.neonOrange,
      route: '/sliding_puzzle',
      supportsSinglePlayer: true,
      supportsMultiplayer: false,
    ),
    GameInfo(
      id: 'checkers',
      title: 'Checkers / Draughts',
      category: 'Strategy',
      description: 'Jump over opponent chips on an 8x8 checkerboard.',
      icon: Icons.casino,
      color: AppTheme.neonViolet,
      route: '/checkers',
      supportsSinglePlayer: false,
      supportsMultiplayer: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _staggerController.forward();

    // Bounce controller starts stopped; only runs when scroll indicator is visible.
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    // Cache GoogleFonts TextStyle once to avoid per-build allocation.
    _caveatStyle = GoogleFonts.getFont(
      'Caveat',
      textStyle: AppTheme.bodyMd.copyWith(
        fontSize: 22,
        color: AppTheme.textSecondary,
        letterSpacing: 0.5,
      ),
    );

    // Build card animations once; rebuild when category changes.
    _buildCardAnimations();

    _checkScrollable();
  }

  void _buildCardAnimations() {
    final count = _games.length;
    _cardAnims = List.generate(count, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval((i / count) * 0.4, 1.0, curve: Curves.easeOutCubic),
        ),
      );
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _bounceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final canScroll = _scrollController.position.maxScrollExtent > 10;
      final show = _scrollController.offset < 20 && canScroll;
      if (show != _showScrollIndicator) {
        setState(() {
          _showScrollIndicator = show;
        });
        // Start/stop bounce animation based on indicator visibility.
        if (show) {
          _bounceController.repeat(reverse: true);
        } else {
          _bounceController.stop();
        }
      }
    }
  }

  void _checkScrollable() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final canScroll = _scrollController.position.maxScrollExtent > 10;
        final show = _scrollController.offset < 20 && canScroll;
        if (show != _showScrollIndicator) {
          setState(() {
            _showScrollIndicator = show;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredGames = _selectedCategory == 'All'
        ? _games
        : _games.where((game) => game.category == _selectedCategory).toList();
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = isDesktop
        ? (screenWidth - 850).clamp(80.0, double.infinity) / 2
        : 20.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const RepaintBoundary(child: LiquidGlassBackground()),
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Dashboard Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 24.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select a game & play together',
                              style: _caveatStyle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Category Filter Tabs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, idx) {
                          final cat = _categories[idx];
                          final isSelected = _selectedCategory == cat;

                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = cat;
                                  // Restart staggered animations and rebuild cached anims.
                                  _staggerController.reset();
                                  _buildCardAnimations();
                                  _staggerController.forward();
                                });
                                _checkScrollable();
                              },
                              child: GlassContainer(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                borderRadius:
                                    24, // rounded-xl (24px) for controls
                                borderColor: isSelected
                                    ? AppTheme.neonCyan.withOpacity(0.6)
                                    : Colors.white.withOpacity(0.08),
                                fillColor: isSelected
                                    ? AppTheme.neonCyan.withOpacity(0.15)
                                    : Colors.white.withOpacity(0.02),
                                child: Text(
                                  cat,
                                  style: AppTheme.labelCaps.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Responsive Grid of Game Cards
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverGrid(
                    gridDelegate: isDesktop
                        ? const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 24,
                            crossAxisSpacing: 24,
                            childAspectRatio: 1.05,
                          )
                        : const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.9,
                          ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final game = filteredGames[index];
                      // Use pre-built cached animation — no Tween/CurvedAnimation allocation per frame.
                      final anim = _cardAnims[index];

                      return AnimatedBuilder(
                        animation: anim,
                        builder: (context, child) {
                          return Opacity(
                            opacity: anim.value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - anim.value) * 30),
                              child: child,
                            ),
                          );
                        },
                        child: InkWell(
                          onTap: () => _showModeSelection(context, game),
                          borderRadius: BorderRadius.circular(16),
                          child: GlassContainer(
                            borderColor: game.color.withOpacity(0.25),
                            borderRadius: 16,
                            elevation: GlassElevation.medium,
                            primaryColor: game.color,
                            boxShadow: [
                              BoxShadow(
                                color: game.color.withOpacity(0.06),
                                blurRadius: 16,
                                spreadRadius: 0,
                              ),
                            ],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Category badge on top-right
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: game.color.withOpacity(0.1),
                                      border: Border.all(
                                        color: game.color.withOpacity(0.2),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      game.category.toUpperCase(),
                                      style: TextStyle(
                                        color: game.color,
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Glowing centered game icon / visual representation
                                RepaintBoundary(
                                  child: GameVisual(
                                    gameId: game.id,
                                    color: game.color,
                                    size: 56,
                                  ),
                                ),
                                const Spacer(),
                                // Title
                                Text(
                                  game.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.bodyLg.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Description
                                Text(
                                  game.description,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.bodyMd.copyWith(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: filteredGames.length),
                  ),
                ),

                // Spacing
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              bottom: true,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showScrollIndicator ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_showScrollIndicator,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      child: AnimatedBuilder(
                        animation: _bounceController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              -5 + (_bounceController.value * 8),
                            ),
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.neonCyan.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonCyan.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.keyboard_double_arrow_down_rounded,
                            color: AppTheme.neonCyan,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showModeSelection(BuildContext context, GameInfo game) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: GlassContainer(
            borderColor: game.color.withOpacity(0.4),
            fillColor: Colors.black.withOpacity(0.45),
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: game.color.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: game.color.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(game.icon, color: game.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                game.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Choose play mode to begin',
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

                    // Options buttons depending on capabilities
                    if (game.supportsSinglePlayer &&
                        game.supportsMultiplayer) ...[
                      // Supports both!
                      GlassButton(
                        color: game.color,
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: const Text('Play Solo'),
                        isPrimary: true,
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Provider.of<NetworkManager>(
                            context,
                            listen: false,
                          ).stop();
                          Navigator.pushNamed(
                            context,
                            game.route,
                            arguments: {'network': false, 'isSolo': true},
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      GlassButton(
                        color: game.color,
                        icon: const Icon(Icons.person_pin, size: 20),
                        label: const Text('Pass & Play (Same Device)'),
                        isPrimary: false,
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Provider.of<NetworkManager>(
                            context,
                            listen: false,
                          ).stop();
                          Navigator.pushNamed(
                            context,
                            game.route,
                            arguments: {'network': false, 'isSolo': false},
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      GlassButton(
                        color: game.color,
                        icon: const Icon(Icons.wifi, size: 20),
                        label: const Text('Local Network (2 Devices)'),
                        hasShimmer: true,
                        isPrimary: false,
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showNetworkLobby(context, game);
                        },
                      ),
                    ] else if (game.supportsMultiplayer) ...[
                      // Multiplayer only
                      GlassButton(
                        color: game.color,
                        icon: const Icon(Icons.person_pin, size: 20),
                        label: const Text('Pass & Play (Same Device)'),
                        isPrimary: true,
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Provider.of<NetworkManager>(
                            context,
                            listen: false,
                          ).stop();
                          Navigator.pushNamed(
                            context,
                            game.route,
                            arguments: {'network': false, 'isSolo': false},
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      GlassButton(
                        color: game.color,
                        icon: const Icon(Icons.wifi, size: 20),
                        label: const Text('Local Network (2 Devices)'),
                        hasShimmer: true,
                        isPrimary: false,
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showNetworkLobby(context, game);
                        },
                      ),
                    ] else ...[
                      // Single Player only
                      GlassButton(
                        color: game.color,
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: const Text('Play Solo'),
                        isPrimary: true,
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Provider.of<NetworkManager>(
                            context,
                            listen: false,
                          ).stop();
                          Navigator.pushNamed(
                            context,
                            game.route,
                            arguments: {'network': false, 'isSolo': true},
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      GlassButton(
                        color: game.color,
                        icon: const Icon(Icons.wifi, size: 20),
                        label: const Text('Local Network (2 Devices)'),
                        hasShimmer: false,
                        isPrimary: false,
                        onPressed: null,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNetworkLobby(BuildContext context, GameInfo game) {
    Provider.of<NetworkManager>(context, listen: false).stop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => NetworkLobbySheet(game: game),
    );
  }
}

class NetworkLobbySheet extends StatefulWidget {
  final GameInfo game;

  const NetworkLobbySheet({super.key, required this.game});

  @override
  State<NetworkLobbySheet> createState() => _NetworkLobbySheetState();
}

class _NetworkLobbySheetState extends State<NetworkLobbySheet> {
  late final TextEditingController _ipController;
  bool _showJoinInput = false;
  // Guard to ensure Navigator.pop is only called once even if provider
  // notifies multiple times while isConnected == true.
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final netManager = Provider.of<NetworkManager>(context);

    if (netManager.isConnected && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
          Navigator.pushNamed(
            context,
            widget.game.route,
            arguments: {'network': true},
          );
        }
      });
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: GlassContainer(
        borderColor: widget.game.color.withOpacity(0.4),
        fillColor: Colors.black.withOpacity(0.45),
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Lobby: ${widget.game.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (netManager.isSearching)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CupertinoActivityIndicator(radius: 10),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Connect with another device on the same Wi-Fi network.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 20),

                if (netManager.role == NetworkRole.none && !_showJoinInput) ...[
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: kIsWeb
                              ? null
                              : () async {
                                  await netManager.hostGame(4040);
                                },
                          borderRadius: BorderRadius.circular(16),
                          child: GlassContainer(
                            height: 100,
                            borderColor: kIsWeb
                                ? Colors.white.withOpacity(0.05)
                                : AppTheme.neonCyan.withOpacity(0.4),
                            fillColor: kIsWeb
                                ? Colors.transparent
                                : AppTheme.neonCyan.withOpacity(0.08),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.dns,
                                  color: kIsWeb
                                      ? Colors.grey
                                      : AppTheme.neonCyan,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'HOST GAME',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (kIsWeb)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    child: Text(
                                      'Mobile Only',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 9,
                                      ),
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
                          onTap: () {
                            setState(() {
                              _showJoinInput = true;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: GlassContainer(
                            height: 100,
                            borderColor: AppTheme.neonGreen.withOpacity(0.4),
                            fillColor: AppTheme.neonGreen.withOpacity(0.08),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.wifi_find,
                                  color: AppTheme.neonGreen,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'JOIN GAME',
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
                ] else if (netManager.role == NetworkRole.host) ...[
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    borderColor: AppTheme.neonCyan.withOpacity(0.2),
                    fillColor: Colors.black12,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.dns,
                          color: AppTheme.neonCyan,
                          size: 36,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Waiting for player to connect...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Local IP:',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                            Text(
                              netManager.localIp ?? 'Fetching...',
                              style: const TextStyle(
                                color: AppTheme.neonCyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Port:',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                            Text(
                              '4040',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
                    label: const Text('Cancel Hosting'),
                    onPressed: () async {
                      await netManager.stop();
                    },
                  ),
                ] else ...[
                  if (netManager.isSearching) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: Column(
                        children: [
                          CupertinoActivityIndicator(
                            radius: 10,
                            color: AppTheme.neonGreen,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Connecting to Host...',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _ipController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Enter Host IP Address',
                        labelStyle: const TextStyle(color: AppTheme.neonGreen),
                        hintText: 'e.g. 192.168.1.100',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppTheme.neonGreen.withOpacity(0.4),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppTheme.neonGreen,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\:]')),
                      ],
                      onSubmitted: (val) async {
                        final ip = val.trim();
                        if (ip.isNotEmpty) {
                          try {
                            await netManager.joinGame(ip, 4040);
                          } catch (e) {
                            if (context.mounted) {
                              AppSnackBar.showError(
                                context,
                                'Failed to connect: $e',
                              );
                            }
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    GlassButton(
                      color: AppTheme.neonGreen,
                      label: const Text('Connect'),
                      onPressed: () async {
                        final ip = _ipController.text.trim();
                        if (ip.isNotEmpty) {
                          try {
                            await netManager.joinGame(ip, 4040);
                          } catch (e) {
                            if (context.mounted) {
                              AppSnackBar.showError(
                                context,
                                'Failed to connect: $e',
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      await netManager.stop();
                      setState(() {
                        _showJoinInput = false;
                      });
                    },
                    child: const Text(
                      'Back',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
