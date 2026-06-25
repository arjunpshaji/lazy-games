import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_neon_container.dart';

class GameInfo {
  final String id;
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final Color color;
  final String route;

  GameInfo({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  final List<GameInfo> _games = [
    GameInfo(
      id: 'tic_tac_toe',
      title: 'Tic Tac Toe',
      category: 'Board Game',
      description: 'Align three symbols in a grid to claim victory.',
      icon: Icons.grid_3x3,
      color: AppTheme.neonCyan,
      route: '/tic_tac_toe',
    ),
    GameInfo(
      id: 'sudoku',
      title: 'Sudoku',
      category: 'Math Puzzle',
      description: 'Fill the 9x9 grid so every row, col, & box contains 1-9.',
      icon: Icons.grid_on,
      color: AppTheme.neonGreen,
      route: '/sudoku',
    ),
    GameInfo(
      id: '2048',
      title: '2048',
      category: 'Merge Puzzle',
      description: 'Slide matching tiles to double values & hit the 2048 tile.',
      icon: Icons.grid_view,
      color: AppTheme.neonOrange,
      route: '/2048',
    ),
    GameInfo(
      id: 'memory_match',
      title: 'Memory Match',
      category: 'Card game',
      description: 'Flip cards and find all identical pairs in minimal moves.',
      icon: Icons.style,
      color: AppTheme.neonPink,
      route: '/memory_match',
    ),
    GameInfo(
      id: 'connect_four',
      title: 'Connect Four',
      category: 'Strategy Board',
      description: 'Drop discs down columns. Align four in a row to win.',
      icon: Icons.view_column,
      color: AppTheme.neonCyan,
      route: '/connect_four',
    ),
    GameInfo(
      id: 'minesweeper',
      title: 'Minesweeper',
      category: 'Logic puzzle',
      description: 'Reveal cells without detonating hidden mines.',
      icon: Icons.dangerous,
      color: AppTheme.neonPink,
      route: '/minesweeper',
    ),
    GameInfo(
      id: 'word_search',
      title: 'Word Search',
      category: 'Word puzzle',
      description: 'Locate all hidden words in a grid of random letters.',
      icon: Icons.translate,
      color: AppTheme.neonGreen,
      route: '/word_search',
    ),
    GameInfo(
      id: 'sliding_puzzle',
      title: 'Sliding Puzzle',
      category: 'Classic puzzle',
      description: 'Slide numbered tiles to organize them back in order.',
      icon: Icons.extension,
      color: AppTheme.neonOrange,
      route: '/sliding_puzzle',
    ),
    GameInfo(
      id: 'checkers',
      title: 'Checkers / Draughts',
      category: 'Strategy Board',
      description: 'Jump over opponent chips on an 8x8 checkerboard.',
      icon: Icons.casino,
      color: AppTheme.neonViolet,
      route: '/checkers',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Fancy Dashboard Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 28.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LAZY GAMES',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'BitcountGridDouble',
                                    fontSize: 32,
                                    shadows: [
                                      const Shadow(
                                        color: AppTheme.neonCyan,
                                        blurRadius: 10,
                                      ),
                                      const Shadow(
                                        color: AppTheme.neonViolet,
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select a game & play together',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Game Cards Staggered List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final game = _games[index];

                  // Stagger Animation
                  final anim = Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _staggerController,
                      curve: Interval(
                        (index / _games.length) * 0.5,
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
                          offset: Offset(0, (1 - anim.value) * 50),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: InkWell(
                        onTap: () => _showModeSelection(context, game),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedNeonContainer(
                          color: game.color,
                          borderWidth: 1.0,
                          height: 110,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Game icon container
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: game.color.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: game.color.withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          game.icon,
                                          color: game.color,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Text details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    game.title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    color: game.color
                                                        .withOpacity(0.15),
                                                  ),
                                                  child: Text(
                                                    game.category.toUpperCase(),
                                                    style: TextStyle(
                                                      color: game.color,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              game.description,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: game.color.withOpacity(0.5),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                                if (game.id == 'connect_four')
                                  Positioned(
                                    top: 12,
                                    right: -28,
                                    child: _buildFavoriteBanner(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }, childCount: _games.length),
              ),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteBanner() {
    return Transform.rotate(
      angle: 0.7853, // 45 degrees
      child: Container(
        width: 100,
        height: 20,
        decoration: BoxDecoration(
          color: AppTheme.neonPink,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: Colors.white, size: 10),
            SizedBox(width: 4),
            Text(
              'FAVORITE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModeSelection(BuildContext context, GameInfo game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.forestDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(game.icon, color: AppTheme.forestMint, size: 28),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          game.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.forestMint,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose how you want to play this session.',
                    style: TextStyle(
                      color: AppTheme.forestAccent,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Button 1: Pass & Play
                  AnimatedNeonContainer(
                    color: AppTheme.forestMint,
                    backgroundColor: AppTheme.forestDeep,
                    borderRadius: 12,
                    borderWidth: 1.5,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
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
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_pin, color: AppTheme.forestMint),
                            const SizedBox(width: 8),
                            Text(
                              'Pass & Play (Same Device)',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Button 2: Local Network Play
                  AnimatedNeonContainer(
                    color: AppTheme.forestAccent,
                    backgroundColor: AppTheme.forestDark,
                    borderRadius: 12,
                    borderWidth: 1.5,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _showNetworkLobby(context, game);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi, color: AppTheme.forestMint),
                            const SizedBox(width: 8),
                            Text(
                              'Local Network (2 Devices)',
                              style: TextStyle(
                                color: AppTheme.forestMint,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNetworkLobby(BuildContext context, GameInfo game) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.forestDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final ipController = TextEditingController();
        bool isJoining = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final netManager = Provider.of<NetworkManager>(context);

            // Check if connection succeeded
            if (netManager.isConnected) {
              // Dismiss bottom sheet and push game
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  game.route,
                  arguments: {'network': true},
                );
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
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
                              'Lobby: ${game.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.forestMint,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (netManager.isSearching)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppTheme.forestMint,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Connect with another device on the same Wi-Fi network.',
                        style: TextStyle(
                          color: AppTheme.forestAccent,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (netManager.role == NetworkRole.none &&
                          !isJoining) ...[
                        // Selection choices: Host or Join
                        Row(
                          children: [
                            // HOST Button (Mobile Only)
                            Expanded(
                              child: AnimatedNeonContainer(
                                color: kIsWeb
                                    ? Colors.grey.withOpacity(0.3)
                                    : AppTheme.forestAccent,
                                backgroundColor: kIsWeb
                                    ? Colors.transparent
                                    : AppTheme.forestDark,
                                borderRadius: 12,
                                borderWidth: 1.5,
                                child: InkWell(
                                  onTap: kIsWeb
                                      ? null
                                      : () async {
                                          setSheetState(() {});
                                          await netManager.hostGame(4040);
                                          setSheetState(() {});
                                        },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 100,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.dns,
                                          color: kIsWeb
                                              ? Colors.grey
                                              : AppTheme.forestMint,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'HOST GAME',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: kIsWeb
                                                ? Colors.grey
                                                : Colors.white,
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
                            ),
                            const SizedBox(width: 16),
                            // JOIN Button
                            Expanded(
                              child: AnimatedNeonContainer(
                                color: AppTheme.forestMint,
                                backgroundColor: AppTheme.forestDeep,
                                borderRadius: 12,
                                borderWidth: 1.5,
                                child: InkWell(
                                  onTap: () {
                                    setSheetState(() {
                                      isJoining = true;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 100,
                                    alignment: Alignment.center,
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.wifi_find,
                                          color: AppTheme.forestMint,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'JOIN GAME',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (netManager.role == NetworkRole.host) ...[
                        // Host Lobby State
                        AnimatedNeonContainer(
                          color: AppTheme.forestAccent,
                          backgroundColor: AppTheme.forestDeep,
                          borderRadius: 12,
                          borderWidth: 1.5,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.dns,
                                  color: AppTheme.forestMint,
                                  size: 36,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Waiting for player to connect...',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Your Local IP:',
                                      style: TextStyle(
                                        color: AppTheme.forestMint,
                                      ),
                                    ),
                                    Text(
                                      netManager.localIp ?? 'Fetching...',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Port:',
                                      style: TextStyle(
                                        color: AppTheme.forestMint,
                                      ),
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
                        ),
                        const SizedBox(height: 16),
                        AnimatedNeonContainer(
                          color: Colors.redAccent,
                          backgroundColor: AppTheme.forestDark,
                          borderRadius: 12,
                          borderWidth: 1.5,
                          child: InkWell(
                            onTap: () async {
                              await netManager.stop();
                              setSheetState(() {});
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              child: const Text(
                                'Cancel Hosting',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Join Lobby / IP Entry
                        TextField(
                          controller: ipController,
                          cursorColor: AppTheme.forestMint,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Enter Host IP Address',
                            labelStyle: const TextStyle(
                              color: AppTheme.forestMint,
                            ),
                            hintText: 'e.g. 192.168.1.100',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: AppTheme.forestAccent,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: AppTheme.forestMint,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.values.firstWhere(
                            (element) => true,
                            orElse: () => TextInputType.number,
                          ), // fallback
                        ),
                        const SizedBox(height: 16),
                        AnimatedNeonContainer(
                          color: AppTheme.forestMint,
                          backgroundColor: AppTheme.forestDeep,
                          borderRadius: 12,
                          borderWidth: 1.5,
                          child: InkWell(
                            onTap: () async {
                              final ip = ipController.text.trim();
                              if (ip.isNotEmpty) {
                                setSheetState(() {});
                                await netManager.joinGame(ip, 4040);
                                setSheetState(() {});
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              child: const Text(
                                'Connect',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () async {
                            await netManager.stop();
                            setSheetState(() {
                              isJoining = false;
                            });
                          },
                          child: const Text(
                            'Back',
                            style: TextStyle(
                              color: AppTheme.forestAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
