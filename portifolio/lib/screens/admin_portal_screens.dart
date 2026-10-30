import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'welcome_screen.dart';

class SuperAdminScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const SuperAdminScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) => _AdminPortalFrame(
    user: user,
    title: 'Super Admin',
    subtitle: 'All communities, neighbours and meetings',
  );
}

class _AdminPortalFrame extends StatelessWidget {
  final Map<String, dynamic> user;
  final String title;
  final String subtitle;

  const _AdminPortalFrame({
    required this.user,
    required this.title,
    required this.subtitle,
  });

  void _signOut(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = user['name']?.toString().trim() ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(
              name.isEmpty ? subtitle : '$name · $subtitle',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: AdminDashboardScreen(key: ValueKey(user['id']), user: user),
    );
  }
}
