import 'package:flutter/material.dart';

import '../../../core/constants/app_theme.dart';

class FundraisersScreen extends StatelessWidget {
  const FundraisersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fundraisers')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volunteer_activism,
              size: 64,
              color: AppColors.success.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text('Fundraisers Screen'),
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
