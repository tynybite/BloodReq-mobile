import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class OfflineDropScreen extends StatefulWidget {
  final VoidCallback? onRetry;

  const OfflineDropScreen({super.key, this.onRetry});

  @override
  State<OfflineDropScreen> createState() => _OfflineDropScreenState();
}

class _OfflineDropScreenState extends State<OfflineDropScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isShocking = false;

  @override
  void initState() {
    super.initState();
    // 2-second loop for the heartbeat cycle
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerShock() {
    if (_isShocking) return;
    setState(() => _isShocking = true);

    // Quick shock animation
    _controller.duration = const Duration(milliseconds: 500);
    _controller.reset();
    _controller.forward().whenComplete(() {
      if (mounted) {
        setState(() => _isShocking = false);
        _controller.duration = const Duration(seconds: 2);
        _controller.repeat();
        widget.onRetry?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerShock,
      child: Scaffold(
        backgroundColor: const Color(0xFF051008), // Dark Green/Black (Monitor)
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Monitor Grid
            CustomPaint(painter: GridPainter(), child: Container()),

            // 2. ECG Line
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: ECGPainter(
                    progress: _controller.value,
                    color: _isShocking
                        ? Colors.yellowAccent
                        : const Color(0xFF00FF41), // Matrix/Monitor Green
                    isShocking: _isShocking,
                  ),
                  child: Container(),
                );
              },
            ),

            // 3. Vignette & Glow Overlay
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  radius: 0.8,
                ),
              ),
            ),

            // 4. Content
            Positioned(
              top: MediaQuery.of(context).padding.top + 40,
              left: 20,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.monitor_heart_outlined,
                        color: Color(0xFF00FF41),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                            "NO INTERNET",
                            style: TextStyle(
                              fontFamily:
                                  "Courier", // Monospace for terminal look
                              color: const Color(
                                0xFF00FF41,
                              ).withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fade(duration: 1000.ms),
                    ],
                  ),
                ],
              ),
            ),

            // 5. Center Status
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 120), // Push down below heartbeat
                  Text(
                    _isShocking ? "TRYING TO RECONNECT..." : "YOU ARE OFFLINE",
                    style: TextStyle(
                      fontFamily: "Courier",
                      color: _isShocking ? Colors.yellowAccent : Colors.white54,
                      fontSize: 16,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 16),
                  Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(
                              0xFF00FF41,
                            ).withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: const Color(
                            0xFF00FF41,
                          ).withValues(alpha: 0.05),
                        ),
                        child: Text(
                          "TAP TO RETRY",
                          style: const TextStyle(
                            fontFamily: "Courier",
                            color: Color(0xFF00FF41),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(duration: 800.ms, begin: 0.4, end: 1.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF41).withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const gridSize = 40.0;

    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ECGPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isShocking;

  ECGPainter({
    required this.progress,
    required this.color,
    required this.isShocking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      // Glow effect
      ..shader =
          LinearGradient(
            colors: [Colors.transparent, color, color],
            stops: const [0.0, 0.9, 1.0],
          ).createShader(
            Rect.fromLTWH(size.width * progress - 200, 0, 200, size.height),
          );

    final path = Path();
    final centerY = size.height / 2;
    final width = size.width;

    // Simulate PQRST wave
    path.moveTo(0, centerY);

    // Calculate the X position of the "head" of the line
    final headX = width * progress;

    for (double x = 0; x <= headX; x += 2) {
      // Is this X inside a "beat"?
      // Let's say beat happens at 0.5 (center screen)
      double y = centerY;

      // Normalized X (0..1)
      double nx = x / width;

      // Beat logic
      if (nx > 0.4 && nx < 0.6) {
        // Inside beat window
        double beatProgress = (nx - 0.4) / 0.2; // 0..1

        if (isShocking) {
          // Chaotic fib
          y += math.sin(beatProgress * 20) * 50;
        } else {
          // Normal PQRST
          if (beatProgress < 0.2) {
            y -= 10 * math.sin(beatProgress * math.pi * 5); // P
          } else if (beatProgress < 0.3) {
            y += 0;
          } else if (beatProgress < 0.4) {
            y += 10; // Q dip
          } else if (beatProgress < 0.5) {
            y -= 80; // R spike
          } else if (beatProgress < 0.6) {
            y += 20; // S dip
          } else if (beatProgress < 0.8) {
            y -= 15 * math.sin((beatProgress - 0.6) * math.pi * 5); // T
          }
        }
      } else {
        // Flatline noise
        y += math.sin(x * 0.1) * 2;
      }

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw!
    canvas.drawPath(path, paint);

    // Draw the "Head" dot
    canvas.drawCircle(
      Offset(headX, getYAt(headX, width, centerY)),
      4,
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5),
    );
  }

  double getYAt(double x, double width, double centerY) {
    double nx = x / width;
    double y = centerY;
    if (nx > 0.4 && nx < 0.6) {
      double beatProgress = (nx - 0.4) / 0.2;
      if (isShocking) {
        y += math.sin(beatProgress * 20) * 50;
      } else {
        if (beatProgress < 0.2) {
          y -= 10 * math.sin(beatProgress * math.pi * 5); // P
        } else if (beatProgress < 0.3) {
          y += 0;
        } else if (beatProgress < 0.4) {
          y += 10; // Q dip
        } else if (beatProgress < 0.5) {
          y -= 80; // R spike
        } else if (beatProgress < 0.6) {
          y += 20; // S dip
        } else if (beatProgress < 0.8) {
          y -= 15 * math.sin((beatProgress - 0.6) * math.pi * 5); // T
        }
      }
    } else {
      y += math.sin(x * 0.1) * 2;
    }
    return y;
  }

  @override
  bool shouldRepaint(covariant ECGPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isShocking != isShocking;
}
