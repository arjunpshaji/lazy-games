import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_manager.dart';
import '../theme/app_theme.dart';

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
                    builder: (context) => AlertDialog(
                      title: const Text('Leave Match?'),
                      content: const Text('This will disconnect the local network game session.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Leave', style: TextStyle(color: AppTheme.neonPink)),
                        ),
                      ],
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
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.menu_book, color: AppTheme.neonGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text('How to Play: $title'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            rules,
            style: const TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!', style: TextStyle(color: AppTheme.neonCyan)),
          ),
        ],
      ),
    );
  }
}
