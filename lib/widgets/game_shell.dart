import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_manager.dart';
import '../theme/app_theme.dart';
import 'animated_neon_container.dart';

class GameShell extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final String rules;
  final Widget? statusWidget;
  final VoidCallback? onReset;

  const GameShell({
    super.key,
    required this.title,
    required this.child,
    required this.rules,
    this.actions,
    this.statusWidget,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final netManager = Provider.of<NetworkManager>(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.neonCyan),
          onPressed: () async {
            if (netManager.isConnected) {
              final leave = await showDialog<bool>(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: AnimatedNeonContainer(
                        color: AppTheme.forestMint,
                        backgroundColor: AppTheme.forestDark,
                        borderRadius: 16,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Leave Match?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.forestMint,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'This will disconnect the local network game session.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: AppTheme.forestAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AnimatedNeonContainer(
                                    color: Colors.redAccent,
                                    backgroundColor: AppTheme.forestDark,
                                    borderRadius: 8,
                                    borderWidth: 1.2,
                                    child: InkWell(
                                      onTap: () => Navigator.of(context).pop(true),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'Leave',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 22,
            letterSpacing: 2,
            shadows: [
              const Shadow(
                color: AppTheme.neonCyan,
                blurRadius: 10,
              )
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.neonGreen),
            onPressed: () => _showRules(context),
          ),
          if (onReset != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.neonCyan),
              onPressed: onReset,
            ),
          ...?actions,
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Network Indicator Bar
            if (netManager.isConnected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                color: AppTheme.neonGreen.withOpacity(0.15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi, size: 16, color: AppTheme.neonGreen),
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
            if (statusWidget != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: statusWidget!,
              ),
            
            // Main game area
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: AnimatedNeonContainer(
          color: AppTheme.forestMint,
          backgroundColor: AppTheme.forestDark,
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book, color: AppTheme.forestMint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'How to Play: $title',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.forestMint,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    rules,
                    style: const TextStyle(
                      height: 1.5,
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedNeonContainer(
                color: AppTheme.forestMint,
                backgroundColor: AppTheme.forestDeep,
                borderRadius: 10,
                borderWidth: 1.2,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: const Text(
                      'Got it!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
