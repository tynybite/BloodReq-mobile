import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';

class DonorAvatarRing extends StatelessWidget {
  final Widget child;
  final bool isDonor;
  final double borderWidth;
  final double padding;

  const DonorAvatarRing({
    super.key,
    required this.child,
    required this.isDonor,
    this.borderWidth = 3.0,
    this.padding = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDonor) return child;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: borderWidth),
      ),
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}
