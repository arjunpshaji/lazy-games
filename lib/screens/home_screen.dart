import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/liquid_glass_background.dart';
import '../widgets/glass_button.dart';
import '../widgets/jumping_letters_text.dart';
import 'package:google_fonts/google_fonts.dart';

class GameInfo {
  final String id;
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
  final bool supportsMultiplayer;

  GameInfo({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
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

  final List<GameInfo> _games = [
    GameInfo(
      id: 'tic_tac_toe',
      title: 'Tic Tac Toe',
      category: 'Classic',
      description: 'Align three symbols in a grid to claim victory.',
      icon: Icons.grid_3x3,
      color: AppTheme.neonCyan,
      route: '/tic_tac_toe',
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
      supportsMultiplayer: false,
    ),
    GameInfo(
      id: 'connect_four',
      title: 'Connect Four',
      category: 'Strategy',
      description: 'Drop discs down columns. Align four in a row to win.',
      icon: Icons.view_column,
      color: AppTheme.neonCyan,
      route: '/connect_four',
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

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    _checkScrollable();
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const LiquidGlassBackground(),
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Dashboard Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 24.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            JumpingLettersText(
                              text: 'LAZY GAMES',
                              style: GoogleFonts.getFont(
                                'Caveat',
                                textStyle: AppTheme.displayLgMobile.copyWith(
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.bold,
                                  shadows: const [
                                    Shadow(
                                      color: AppTheme.neonCyan,
                                      blurRadius: 10,
                                    ),
                                    Shadow(
                                      color: AppTheme.neonViolet,
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              'Select a game & play together',
                              style: GoogleFonts.getFont(
                                "Montserrat",
                                textStyle: AppTheme.bodyMd.copyWith(
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                  // Restart staggered animations
                                  _staggerController.reset();
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
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.9,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final game = filteredGames[index];

                      // Stagger Animation
                      final anim = Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _staggerController,
                          curve: Interval(
                            (index / filteredGames.length) * 0.4,
                            1.0,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      );

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
                          borderRadius: BorderRadius.circular(
                            16,
                          ), // rounded-lg (16px) for cards
                          child: GlassContainer(
                            borderColor: game.color.withOpacity(0.3),
                            borderRadius: 16, // rounded-lg (16px) for cards
                            elevation: GlassElevation.low,
                            boxShadow: [
                              BoxShadow(
                                color: game.color.withOpacity(0.08),
                                blurRadius: 16,
                                spreadRadius: 0,
                              ),
                            ],
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: game.color.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: game.color.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        game.icon,
                                        color: game.color,
                                        size: 22,
                                      ),
                                    ),
                                    Container(
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
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  game.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.bodyLg.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  game.description,
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

                    // Button 1: Pass & Play / Play Solo
                    GlassButton(
                      color: game.color,
                      icon: Icon(
                        game.supportsMultiplayer
                            ? Icons.person_pin
                            : Icons.play_arrow,
                        size: 20,
                      ),
                      label: Text(
                        game.supportsMultiplayer
                            ? 'Pass & Play (Same Device)'
                            : 'Play Solo',
                      ),
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
                          arguments: {'network': false},
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Button 2: Local Network Play
                    GlassButton(
                      color: game.color,
                      icon: const Icon(Icons.wifi, size: 20),
                      label: const Text('Local Network (2 Devices)'),
                      hasShimmer: game.supportsMultiplayer,
                      isPrimary: false,
                      onPressed: game.supportsMultiplayer
                          ? () {
                              Navigator.pop(sheetContext);
                              _showNetworkLobby(context, game);
                            }
                          : null,
                    ),
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

    if (netManager.isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        Navigator.pushNamed(
          context,
          widget.game.route,
          arguments: {'network': true},
        );
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(AppTheme.neonCyan),
                        ),
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
                                const SizedBox(height: 8),
                                const Text(
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
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                              AppTheme.neonGreen,
                            ),
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
                      keyboardType: TextInputType.values.firstWhere(
                        (_) => true,
                        orElse: () => TextInputType.number,
                      ),
                      onSubmitted: (val) async {
                        final ip = val.trim();
                        if (ip.isNotEmpty) {
                          try {
                            await netManager.joinGame(ip, 4040);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to connect: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to connect: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
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
