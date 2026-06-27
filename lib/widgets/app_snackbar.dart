import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class AppSnackBar {
  static void showError(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      borderColor: AppTheme.neonPink,
      icon: Icons.error_outline,
      iconColor: AppTheme.neonPink,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      borderColor: AppTheme.neonGreen,
      icon: Icons.check_circle_outline,
      iconColor: AppTheme.neonGreen,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      borderColor: AppTheme.neonCyan,
      icon: Icons.info_outline,
      iconColor: AppTheme.neonCyan,
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              80,
          left: 16,
          right: 16,
        ),
        dismissDirection: DismissDirection.up,
        duration: const Duration(seconds: 4),
        content: GlassContainer(
          borderRadius: 16,
          borderWidth: 1.5,
          borderColor: borderColor.withOpacity(0.5),
          fillColor: AppTheme.neonPink.withOpacity(0.4),
          elevation: GlassElevation.medium,
          primaryColor: borderColor,
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.08),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
