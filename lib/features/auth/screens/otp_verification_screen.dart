import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/config/language_config.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  int _resendCooldown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() => _resendCooldown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleVerify() async {
    final lang = context.read<LanguageProvider>();
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(lang.getText('enter_full_code'))));
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.verifyEmailOtp(widget.email, otp);

    setState(() => _isLoading = false);

    if (success && mounted) {
      context.go('/home'); // Or where ever successful login goes
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.error ?? lang.getText('verification_failed'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0) return;
    final lang = context.read<LanguageProvider>();

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resendEmailOtp(widget.email);
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(lang.getText('code_resent'))));
      _startTimer();
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(lang.getText('resend_failed'))));
    }
  }

  void _onDigitChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    // Handle paste?
    if (value.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = value[i];
      }
      _focusNodes[5].requestFocus();
      _handleVerify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: PopupMenuButton<Locale>(
                offset: const Offset(0, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tooltip: 'Select Language',
                initialValue: lang.currentLocale,
                onSelected: (locale) => lang.changeLanguage(locale),
                itemBuilder: (context) => LanguageConfig.options.map((option) {
                  return PopupMenuItem(
                    value: Locale(option.code),
                    child: Row(
                      children: [
                        Text(option.flag, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Text(option.name),
                      ],
                    ),
                  );
                }).toList(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${LanguageConfig.getOption(lang.currentLocale.languageCode).flag} ${lang.currentLocale.languageCode.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background matching other screens
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: CustomPaint(painter: _BlobPainter(color: AppColors.primary)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.1),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      lang.getText('verification'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn().slideX(),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${lang.getText('enter_code_sent')}\n${widget.email}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ),

                  SizedBox(height: size.height * 0.15),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: context.isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // OTP Input Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: 40,
                              child: TextFormField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLength: 1,
                                decoration: InputDecoration(
                                  counterText: '',
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: context.borderColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onChanged: (val) => _onDigitChanged(val, index),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 32),

                        // Verify Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleVerify,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    lang.getText('verify'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Resend
                        TextButton(
                          onPressed: _resendCooldown > 0 ? null : _handleResend,
                          child: Text(
                            _resendCooldown > 0
                                ? '${lang.getText('resend_code_in')} ${_resendCooldown}s'
                                : lang.getText('resend_code'),
                            style: TextStyle(
                              color: _resendCooldown > 0
                                  ? Colors.grey
                                  : AppColors.primary,
                              fontWeight: _resendCooldown > 0
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOut,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final Color color;

  _BlobPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    // Start top-left
    path.lineTo(0, size.height * 0.75);

    // Smooth bezier curve for organic blob feel
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.6,
      size.height * 0.85,
    );

    path.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.75,
      size.width,
      size.height * 0.9,
    );

    // End top-right
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
