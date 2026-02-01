import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';

class BlobBackground extends StatefulWidget {
  final Widget child;
  final bool navigateBack;

  const BlobBackground({
    super.key,
    required this.child,
    this.navigateBack = false,
  });

  @override
  State<BlobBackground> createState() => _BlobBackgroundState();
}

class _BlobBackgroundState extends State<BlobBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Very slow rotation for life-like feel but zero layout cost
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Performance: Use simple gradient blobs, no blurs
    final blob1Color = isDark
        ? AppColors.primary.withValues(alpha: 0.3)
        : AppColors.primary.withValues(alpha: 0.2);

    final blob2Color = isDark
        ? Colors.purple.withValues(alpha: 0.3)
        : Colors.purple.withValues(alpha: 0.2);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blob 1: Top Right
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(400, 400),
                  painter: _BlobPainter(color: blob1Color, shape: 1),
                ),
              ),
            ),
          ),

          // Blob 2: Bottom Left
          Positioned(
            bottom: -50,
            left: -100,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Transform.rotate(
                angle: -_controller.value * 2 * math.pi, // Reverse rotation
                child: CustomPaint(
                  size: const Size(350, 350),
                  painter: _BlobPainter(color: blob2Color, shape: 2),
                ),
              ),
            ),
          ),

          // Content
          widget.child,
        ],
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final Color color;
  final int shape;

  _BlobPainter({required this.color, required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    if (shape == 1) {
      // Organic blob shape 1
      path.moveTo(size.width * 0.8, size.height * 0.2);
      path.quadraticBezierTo(
        size.width,
        size.height * 0.4,
        size.width * 0.8,
        size.height * 0.7,
      );
      path.quadraticBezierTo(
        size.width * 0.6,
        size.height,
        size.width * 0.3,
        size.height * 0.8,
      );
      path.quadraticBezierTo(
        0,
        size.height * 0.6,
        size.width * 0.2,
        size.height * 0.3,
      );
      path.quadraticBezierTo(
        size.width * 0.4,
        0,
        size.width * 0.8,
        size.height * 0.2,
      );
    } else {
      // Organic blob shape 2
      path.moveTo(size.width * 0.5, size.height * 0.1);
      path.quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.2,
        size.width * 0.8,
        size.height * 0.6,
      );
      path.quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.9,
        size.width * 0.4,
        size.height * 0.8,
      );
      path.quadraticBezierTo(
        size.width * 0.1,
        size.height * 0.7,
        size.width * 0.2,
        size.height * 0.3,
      );
      path.quadraticBezierTo(
        size.width * 0.3,
        0,
        size.width * 0.5,
        size.height * 0.1,
      );
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BlobPainter oldDelegate) => false; // Static shape, no repaint needed
}
