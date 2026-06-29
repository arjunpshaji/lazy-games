import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Theme & Services
import 'theme/app_theme.dart';
import 'services/network_manager.dart';
import 'services/audio_service.dart';
import 'services/supabase_service.dart';
import 'services/supabase_room_manager.dart';
import 'services/app_config_service.dart';
import 'services/admob_service.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

// Games & Providers
import 'providers/tic_tac_toe_provider.dart';
import 'games/tic_tac_toe.dart';
import 'providers/sudoku_provider.dart';
import 'games/sudoku.dart';
import 'providers/game_2048_provider.dart';
import 'games/game_2048.dart';
import 'providers/memory_match_provider.dart';
import 'games/memory_match.dart';
import 'providers/connect_four_provider.dart';
import 'games/connect_four.dart';
import 'providers/minesweeper_provider.dart';
import 'games/minesweeper.dart';
import 'providers/word_search_provider.dart';
import 'games/word_search.dart';
import 'providers/sliding_puzzle_provider.dart';
import 'games/sliding_puzzle.dart';
import 'providers/checkers_provider.dart';
import 'games/checkers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Core services
  await AudioService.instance.init();

  // Supabase (anonymous auth + session restore)
  await SupabaseService.initialize();

  // AdMob (mobile only; no-op on web)
  if (!kIsWeb) {
    await AdMobService.instance.initialize();
  }

  // Prime the kill-switch cache on startup
  AppConfigService.instance.fetchAndCacheConfig();

  runApp(
    MultiProvider(
      providers: [
        // LAN multiplayer
        ChangeNotifierProvider(create: (_) => NetworkManager()),
        // Online multiplayer (Supabase)
        ChangeNotifierProvider(create: (_) => SupabaseRoomManager()),
        // Game providers
        ChangeNotifierProvider(create: (_) => TicTacToeProvider()),
        ChangeNotifierProvider(create: (_) => SudokuProvider()),
        ChangeNotifierProvider(create: (_) => Game2048Provider()),
        ChangeNotifierProvider(create: (_) => MemoryMatchProvider()),
        ChangeNotifierProvider(create: (_) => ConnectFourProvider()),
        ChangeNotifierProvider(create: (_) => MinesweeperProvider()),
        ChangeNotifierProvider(create: (_) => WordSearchProvider()),
        ChangeNotifierProvider(create: (_) => SlidingPuzzleProvider()),
        ChangeNotifierProvider(create: (_) => CheckersProvider()),
      ],
      child: const LazyGamesApp(),
    ),
  );
}

class LazyGamesApp extends StatelessWidget {
  const LazyGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lazy Games',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/tic_tac_toe': (context) => const TicTacToeScreen(),
        '/sudoku': (context) => const SudokuScreen(),
        '/2048': (context) => const Game2048Screen(),
        '/memory_match': (context) => const MemoryMatchScreen(),
        '/connect_four': (context) => const ConnectFourScreen(),
        '/minesweeper': (context) => const MinesweeperScreen(),
        '/word_search': (context) => const WordSearchScreen(),
        '/sliding_puzzle': (context) => const SlidingPuzzleScreen(),
        '/checkers': (context) => const CheckersScreen(),
      },
    );
  }
}
