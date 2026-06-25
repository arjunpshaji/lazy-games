import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_manager.dart';
import '../theme/app_theme.dart';
import 'liquid_glass_background.dart';
import 'glass_button.dart';
import 'glass_container.dart';

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.neonCyan),
          onPressed: () async {
            if (netManager.isConnected) {
              final leave = await showDialog<bool>(
                    context: context,
                    barrierColor: const Color(0xFF1F1145).withOpacity(0.40),
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
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
                              style: AppTheme.headlineMd.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This will disconnect the local network game session.',
                              style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: Text('Cancel', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                GlassButton(
                                  isFullWidth: false,
                                  color: AppTheme.neonPink,
                                  label: const Text('Leave'),
                                  onPressed: () => Navigator.of(context).pop(true),
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
      body: Stack(
        children: [
          const LiquidGlassBackground(),
          SafeArea(
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
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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
                  const Icon(Icons.menu_book, color: AppTheme.neonGreen, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'How to Play: $title',
                      style: AppTheme.headlineMd.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    rules,
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary, height: 1.5),
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
