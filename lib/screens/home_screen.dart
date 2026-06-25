import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_manager.dart';
import '../theme/app_theme.dart';

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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
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
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                letterSpacing: 3,
                                fontWeight: FontWeight.w900,
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
                        // Small neon top badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.neonCyan.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(20),
                            color: AppTheme.neonCyan.withOpacity(0.05),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.sports_esports, size: 16, color: AppTheme.neonCyan),
                              SizedBox(width: 4),
                              Text(
                                'V1.0',
                                style: TextStyle(
                                  color: AppTheme.neonCyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
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
                          child: Container(
                            height: 110,
                            decoration: AppTheme.neonBorderDecoration(color: game.color, borderWidth: 1.0),
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
                                    border: Border.all(color: game.color.withOpacity(0.3), width: 1.5),
                                  ),
                                  child: Icon(game.icon, color: game.color, size: 32),
                                ),
                                const SizedBox(width: 16),
                                // Text details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              game.title,
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
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(4),
                                              color: game.color.withOpacity(0.15),
                                            ),
                                            child: Text(
                                              game.category.toUpperCase(),
                                              style: TextStyle(
                                                color: game.color,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
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
                                Icon(Icons.arrow_forward_ios, color: game.color.withOpacity(0.5), size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _games.length,
                ),
              ),
            ),
            
            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  void _showModeSelection(BuildContext context, GameInfo game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
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
                      Icon(game.icon, color: game.color, size: 28),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          game.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose how you want to play this session.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Button 1: Pass & Play
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_pin, color: Colors.black),
                    label: const Text('Pass & Play (Same Device)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: game.color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      // Setup provider mode: pass & play
                      // Let's stop any active network connection just in case
                      Provider.of<NetworkManager>(context, listen: false).stop();
                      Navigator.pushNamed(context, game.route, arguments: {'network': false});
                    },
                  ),
                  const SizedBox(height: 16),

                  // Button 2: Local Network Play
                  OutlinedButton.icon(
                    icon: Icon(Icons.wifi, color: game.color),
                    label: Text('Local Network (2 Devices)', style: TextStyle(color: game.color, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: game.color.withOpacity(0.8), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showNetworkLobby(context, game);
                    },
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
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final ipController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final netManager = Provider.of<NetworkManager>(context);
            
            // Check if connection succeeded
            if (netManager.isConnected) {
              // Dismiss bottom sheet and push game
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context);
                Navigator.pushNamed(context, game.route, arguments: {'network': true});
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
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppTheme.neonCyan)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Connect with another device on the same Wi-Fi network.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 20),

                      if (netManager.role == NetworkRole.none) ...[
                        // Selection choices: Host or Join
                        Row(
                          children: [
                            // HOST Button (Mobile Only)
                            Expanded(
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
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: kIsWeb ? Colors.grey.withOpacity(0.3) : AppTheme.neonCyan.withOpacity(0.5),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: kIsWeb ? Colors.transparent : AppTheme.neonCyan.withOpacity(0.05),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.dns, color: kIsWeb ? Colors.grey : AppTheme.neonCyan),
                                      const SizedBox(height: 8),
                                      const Text('HOST GAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      if (kIsWeb)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                                          child: Text(
                                            'Mobile Only',
                                            style: TextStyle(color: Colors.grey, fontSize: 9),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // JOIN Button
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setSheetState(() {
                                    // Transition to IP address entry
                                    // Let's set a marker or state inside netManager or locally
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.neonGreen.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppTheme.neonGreen.withOpacity(0.05),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.wifi_find, color: AppTheme.neonGreen),
                                      const SizedBox(height: 8),
                                      const Text('JOIN GAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (netManager.role == NetworkRole.host) ...[
                        // Host Lobby State
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.dns, color: AppTheme.neonCyan, size: 36),
                              const SizedBox(height: 12),
                              const Text(
                                'Waiting for player to connect...',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Your Local IP:', style: TextStyle(color: AppTheme.textSecondary)),
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
                                  const Text('Port:', style: TextStyle(color: AppTheme.textSecondary)),
                                  Text('4040', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonPink,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            await netManager.stop();
                            setSheetState(() {});
                          },
                          child: const Text('Cancel Hosting', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ] else ...[
                        // Join Lobby / IP Entry
                        TextField(
                          controller: ipController,
                          decoration: InputDecoration(
                            labelText: 'Enter Host IP Address',
                            labelStyle: const TextStyle(color: AppTheme.neonGreen),
                            hintText: 'e.g. 192.168.1.100',
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.neonGreen.withOpacity(0.4)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppTheme.neonGreen),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.values.firstWhere((element) => true, orElse: () => TextInputType.number), // fallback
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            final ip = ipController.text.trim();
                            if (ip.isNotEmpty) {
                              setSheetState(() {});
                              await netManager.joinGame(ip, 4040);
                              setSheetState(() {});
                            }
                          },
                          child: const Text('Connect', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () async {
                            await netManager.stop();
                            setSheetState(() {});
                          },
                          child: const Text('Back', style: TextStyle(color: AppTheme.textSecondary)),
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
