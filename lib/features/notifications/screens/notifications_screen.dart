import 'package:flutter/material.dart';

import '../../../core/constants/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 64,
              color: AppColors.info.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text('Notifications Screen'),
            const SizedBox(height: 8),
            Text(
              'Coming soon...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
